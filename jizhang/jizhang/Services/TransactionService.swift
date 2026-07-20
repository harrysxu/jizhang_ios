import Foundation
import SwiftData

struct TransactionDraft {
    let ledgerID: UUID
    let type: TransactionType
    let amount: Decimal
    let date: Date
    let primaryAccountID: UUID
    let destinationAccountID: UUID?
    let categoryID: UUID?
    let tagIDs: [UUID]
    let note: String?
    let payee: String?
}

struct TransactionReceipt {
    let transactionID: UUID
    let affectedBalances: [UUID: Decimal]
    let savedAt: Date
}

struct UndoToken {
    fileprivate let snapshot: TransactionSnapshot
    let expiresAt: Date
}

private struct TransactionSnapshot {
    let id: UUID
    let ledgerID: UUID
    let type: TransactionType
    let amount: Decimal
    let date: Date
    let primaryAccountID: UUID
    let destinationAccountID: UUID?
    let categoryID: UUID?
    let tagIDs: [UUID]
    let note: String?
    let payee: String?
    let imageURL: String?
    let createdAt: Date
    let modifiedAt: Date
}

protocol TransactionServicing {
    func create(_ draft: TransactionDraft) throws -> TransactionReceipt
    func update(id: UUID, with draft: TransactionDraft) throws -> TransactionReceipt
    func delete(id: UUID) throws -> UndoToken
    func undo(_ token: UndoToken) throws -> TransactionReceipt
    func adjustBalance(accountID: UUID, to newBalance: Decimal, note: String?) throws -> TransactionReceipt
}

enum TransactionServiceError: LocalizedError {
    case invalidAmount
    case ledgerNotFound
    case accountNotFound
    case destinationAccountRequired
    case sameTransferAccount
    case categoryRequired
    case crossLedgerRelationship
    case transactionNotFound
    case undoExpired

    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "金额必须大于 0"
        case .ledgerNotFound: return "未找到账本"
        case .accountNotFound: return "未找到账户"
        case .destinationAccountRequired: return "请选择转入账户"
        case .sameTransferAccount: return "转出和转入账户不能相同"
        case .categoryRequired: return "请选择分类"
        case .crossLedgerRelationship: return "账户、分类和标签必须属于当前账本"
        case .transactionNotFound: return "未找到这笔交易"
        case .undoExpired: return "撤销时间已结束"
        }
    }
}

enum TransactionAccountResolver {
    static func primaryAccount(for transaction: Transaction) -> Account? {
        switch transaction.type {
        case .expense, .transfer:
            return transaction.fromAccount
        case .income, .adjustment:
            return transaction.toAccount ?? transaction.fromAccount
        }
    }
}

@MainActor
final class TransactionService: TransactionServicing {
    private let modelContext: ModelContext
    private let now: () -> Date
    private let reloadWidgets: () -> Void

    init(
        modelContext: ModelContext,
        now: @escaping () -> Date = Date.init,
        reloadWidgets: @escaping () -> Void = {}
    ) {
        self.modelContext = modelContext
        self.now = now
        self.reloadWidgets = reloadWidgets
    }

    func create(_ draft: TransactionDraft) throws -> TransactionReceipt {
        do {
            let resolved = try resolve(draft)
            let transaction = Transaction(
                ledger: resolved.ledger,
                amount: draft.amount,
                date: draft.date,
                type: draft.type,
                fromAccount: resolved.fromAccount,
                toAccount: resolved.toAccount,
                category: resolved.category,
                note: draft.note,
                payee: draft.payee
            )
            transaction.tags = resolved.tags
            modelContext.insert(transaction)

            let effects = balanceEffects(
                type: draft.type,
                amount: draft.amount,
                primaryAccount: resolved.primaryAccount,
                destinationAccount: resolved.destinationAccount
            )
            try apply(effects)
            try modelContext.save()
            reloadWidgets()
            return receipt(for: transaction, effects: effects)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func update(id: UUID, with draft: TransactionDraft) throws -> TransactionReceipt {
        do {
            let transaction = try fetchTransaction(id: id)
            guard transaction.ledger?.id == draft.ledgerID else {
                throw TransactionServiceError.crossLedgerRelationship
            }
            let resolved = try resolve(draft)
            let oldEffects = balanceEffects(for: transaction)
            let newEffects = balanceEffects(
                type: draft.type,
                amount: draft.amount,
                primaryAccount: resolved.primaryAccount,
                destinationAccount: resolved.destinationAccount
            )
            let delta = effectDifference(new: newEffects, old: oldEffects)
            try apply(delta)

            transaction.amount = draft.amount
            transaction.date = draft.date
            transaction.type = draft.type
            transaction.fromAccount = resolved.fromAccount
            transaction.toAccount = resolved.toAccount
            transaction.category = resolved.category
            transaction.tags = resolved.tags
            transaction.note = draft.note
            transaction.payee = draft.payee
            transaction.modifiedAt = now()

            try modelContext.save()
            reloadWidgets()
            return receipt(for: transaction, effects: delta)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func delete(id: UUID) throws -> UndoToken {
        do {
            let transaction = try fetchTransaction(id: id)
            guard let snapshot = makeSnapshot(transaction) else {
                throw TransactionServiceError.crossLedgerRelationship
            }
            let inverseEffects = balanceEffects(for: transaction)
                .mapValues { -$0 }
            try apply(inverseEffects)
            modelContext.delete(transaction)
            try modelContext.save()
            reloadWidgets()
            return UndoToken(
                snapshot: snapshot,
                expiresAt: now().addingTimeInterval(5)
            )
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func undo(_ token: UndoToken) throws -> TransactionReceipt {
        guard now() <= token.expiresAt else {
            throw TransactionServiceError.undoExpired
        }

        let snapshot = token.snapshot
        let draft = TransactionDraft(
            ledgerID: snapshot.ledgerID,
            type: snapshot.type,
            amount: snapshot.amount,
            date: snapshot.date,
            primaryAccountID: snapshot.primaryAccountID,
            destinationAccountID: snapshot.destinationAccountID,
            categoryID: snapshot.categoryID,
            tagIDs: snapshot.tagIDs,
            note: snapshot.note,
            payee: snapshot.payee
        )

        do {
            let resolved = try resolve(draft)
            let transaction = Transaction(
                ledger: resolved.ledger,
                amount: snapshot.amount,
                date: snapshot.date,
                type: snapshot.type,
                fromAccount: resolved.fromAccount,
                toAccount: resolved.toAccount,
                category: resolved.category,
                note: snapshot.note,
                payee: snapshot.payee
            )
            transaction.id = snapshot.id
            transaction.imageURL = snapshot.imageURL
            transaction.createdAt = snapshot.createdAt
            transaction.modifiedAt = snapshot.modifiedAt
            transaction.tags = resolved.tags
            modelContext.insert(transaction)
            let effects = balanceEffects(
                type: snapshot.type,
                amount: snapshot.amount,
                primaryAccount: resolved.primaryAccount,
                destinationAccount: resolved.destinationAccount
            )
            try apply(effects)
            try modelContext.save()
            reloadWidgets()
            return receipt(for: transaction, effects: effects)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func adjustBalance(
        accountID: UUID,
        to newBalance: Decimal,
        note: String? = "余额调整"
    ) throws -> TransactionReceipt {
        let account = try fetchAccount(id: accountID)
        guard let ledgerID = account.ledger?.id else {
            throw TransactionServiceError.crossLedgerRelationship
        }
        let difference = newBalance - account.balance
        guard difference != 0 else {
            return TransactionReceipt(
                transactionID: UUID(),
                affectedBalances: [accountID: account.balance],
                savedAt: now()
            )
        }
        return try create(TransactionDraft(
            ledgerID: ledgerID,
            type: .adjustment,
            amount: difference,
            date: now(),
            primaryAccountID: accountID,
            destinationAccountID: nil,
            categoryID: nil,
            tagIDs: [],
            note: note,
            payee: nil
        ))
    }

    private struct ResolvedDraft {
        let ledger: Ledger
        let primaryAccount: Account
        let destinationAccount: Account?
        let fromAccount: Account?
        let toAccount: Account?
        let category: Category?
        let tags: [Tag]
    }

    private func resolve(_ draft: TransactionDraft) throws -> ResolvedDraft {
        if draft.type == .adjustment {
            guard draft.amount != 0 else { throw TransactionServiceError.invalidAmount }
        } else {
            guard draft.amount > 0 else { throw TransactionServiceError.invalidAmount }
        }
        let ledger = try fetchLedger(id: draft.ledgerID)
        let primaryAccount = try fetchAccount(id: draft.primaryAccountID)
        guard primaryAccount.ledger?.id == ledger.id else {
            throw TransactionServiceError.crossLedgerRelationship
        }

        let destinationAccount = try draft.destinationAccountID.map(fetchAccount)
        if let destinationAccount, destinationAccount.ledger?.id != ledger.id {
            throw TransactionServiceError.crossLedgerRelationship
        }
        if draft.type == .transfer {
            guard let destinationAccount else {
                throw TransactionServiceError.destinationAccountRequired
            }
            guard destinationAccount.id != primaryAccount.id else {
                throw TransactionServiceError.sameTransferAccount
            }
        }

        let category = try draft.categoryID.map(fetchCategory)
        if draft.type == .expense || draft.type == .income {
            guard let category else { throw TransactionServiceError.categoryRequired }
            guard category.ledger?.id == ledger.id else {
                throw TransactionServiceError.crossLedgerRelationship
            }
        }

        let tags = try draft.tagIDs.map(fetchTag)
        guard tags.allSatisfy({ $0.ledger?.id == ledger.id }) else {
            throw TransactionServiceError.crossLedgerRelationship
        }

        let fromAccount: Account?
        let toAccount: Account?
        switch draft.type {
        case .expense:
            fromAccount = primaryAccount
            toAccount = nil
        case .income:
            fromAccount = primaryAccount
            toAccount = primaryAccount
        case .transfer:
            fromAccount = primaryAccount
            toAccount = destinationAccount
        case .adjustment:
            fromAccount = primaryAccount
            toAccount = primaryAccount
        }

        return ResolvedDraft(
            ledger: ledger,
            primaryAccount: primaryAccount,
            destinationAccount: destinationAccount,
            fromAccount: fromAccount,
            toAccount: toAccount,
            category: category,
            tags: tags
        )
    }

    private func balanceEffects(for transaction: Transaction) -> [UUID: Decimal] {
        guard let primaryAccount = TransactionAccountResolver.primaryAccount(for: transaction) else {
            return [:]
        }
        return balanceEffects(
            type: transaction.type,
            amount: transaction.amount,
            primaryAccount: primaryAccount,
            destinationAccount: transaction.type == .transfer ? transaction.toAccount : nil
        )
    }

    private func balanceEffects(
        type: TransactionType,
        amount: Decimal,
        primaryAccount: Account,
        destinationAccount: Account?
    ) -> [UUID: Decimal] {
        switch type {
        case .expense:
            return [primaryAccount.id: -amount]
        case .income, .adjustment:
            return [primaryAccount.id: amount]
        case .transfer:
            guard let destinationAccount else { return [:] }
            return [primaryAccount.id: -amount, destinationAccount.id: amount]
        }
    }

    private func effectDifference(
        new: [UUID: Decimal],
        old: [UUID: Decimal]
    ) -> [UUID: Decimal] {
        var result = new
        for (accountID, amount) in old {
            result[accountID, default: 0] -= amount
        }
        return result.filter { $0.value != 0 }
    }

    private func apply(_ effects: [UUID: Decimal]) throws {
        for (accountID, delta) in effects {
            let account = try fetchAccount(id: accountID)
            account.balance += delta
        }
    }

    private func receipt(
        for transaction: Transaction,
        effects: [UUID: Decimal]
    ) -> TransactionReceipt {
        var balances: [UUID: Decimal] = [:]
        for accountID in effects.keys {
            balances[accountID] = try? fetchAccount(id: accountID).balance
        }
        return TransactionReceipt(
            transactionID: transaction.id,
            affectedBalances: balances,
            savedAt: now()
        )
    }

    private func makeSnapshot(_ transaction: Transaction) -> TransactionSnapshot? {
        guard let ledgerID = transaction.ledger?.id,
              let primaryAccountID = TransactionAccountResolver.primaryAccount(for: transaction)?.id else {
            return nil
        }
        return TransactionSnapshot(
            id: transaction.id,
            ledgerID: ledgerID,
            type: transaction.type,
            amount: transaction.amount,
            date: transaction.date,
            primaryAccountID: primaryAccountID,
            destinationAccountID: transaction.type == .transfer ? transaction.toAccount?.id : nil,
            categoryID: transaction.category?.id,
            tagIDs: (transaction.tags ?? []).map(\.id),
            note: transaction.note,
            payee: transaction.payee,
            imageURL: transaction.imageURL,
            createdAt: transaction.createdAt,
            modifiedAt: transaction.modifiedAt
        )
    }

    private func fetchLedger(id: UUID) throws -> Ledger {
        let descriptor = FetchDescriptor<Ledger>(predicate: #Predicate { $0.id == id })
        guard let ledger = try modelContext.fetch(descriptor).first else {
            throw TransactionServiceError.ledgerNotFound
        }
        return ledger
    }

    private func fetchAccount(id: UUID) throws -> Account {
        let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.id == id })
        guard let account = try modelContext.fetch(descriptor).first else {
            throw TransactionServiceError.accountNotFound
        }
        return account
    }

    private func fetchCategory(id: UUID) throws -> Category {
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })
        guard let category = try modelContext.fetch(descriptor).first else {
            throw TransactionServiceError.categoryRequired
        }
        return category
    }

    private func fetchTag(id: UUID) throws -> Tag {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.id == id })
        guard let tag = try modelContext.fetch(descriptor).first else {
            throw TransactionServiceError.crossLedgerRelationship
        }
        return tag
    }

    private func fetchTransaction(id: UUID) throws -> Transaction {
        let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })
        guard let transaction = try modelContext.fetch(descriptor).first else {
            throw TransactionServiceError.transactionNotFound
        }
        return transaction
    }
}
