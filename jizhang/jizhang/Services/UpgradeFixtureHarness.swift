#if DEBUG
import CryptoKit
import Foundation
import SwiftData

@MainActor
enum UpgradeFixtureHarness {
    private static let auditPrefix = "--upgrade-audit="
    private static let profilePrefix = "--upgrade-profile="
    private static let operationsPrefix = "--upgrade-operations="

    static func runIfRequested(appState: AppState) async {
        let arguments = ProcessInfo.processInfo.arguments
        let auditArgument = arguments.first(where: { $0.hasPrefix(auditPrefix) })
        let operationsArgument = arguments.first(where: { $0.hasPrefix(operationsPrefix) })
        guard auditArgument != nil || operationsArgument != nil else {
            return
        }
        let profile = arguments.first(where: { $0.hasPrefix(profilePrefix) })
            .map { String($0.dropFirst(profilePrefix.count)) } ?? "unknown"

        do {
            for _ in 0..<100 where appState.modelContainer == nil {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            guard let context = appState.modelContainer?.mainContext else {
                throw HarnessError.storeUnavailable
            }
            try await Task.sleep(nanoseconds: 500_000_000)
            if let operationsArgument {
                let operation = String(operationsArgument.dropFirst(operationsPrefix.count))
                let url = try runPostUpgradeOperations(
                    operation: operation,
                    profile: profile,
                    context: context
                )
                print("UPGRADE_OPERATIONS_READY \(url.path)")
            }
            if let auditArgument {
                let stage = String(auditArgument.dropFirst(auditPrefix.count))
                let url = try writeManifest(stage: stage, profile: profile, context: context)
                print("UPGRADE_FIXTURE_READY \(url.path)")
            }
        } catch {
            print("UPGRADE_FIXTURE_FAILED \(error)")
        }
    }

    private static func runPostUpgradeOperations(
        operation: String,
        profile: String,
        context: ModelContext
    ) throws -> URL {
        guard operation == "postoperations" else {
            throw HarnessError.unsupportedOperation(operation)
        }

        let ledgers = try context.fetch(FetchDescriptor<Ledger>())
        guard let ledger = ledgers
            .filter({ !$0.isArchived && $0.name.hasPrefix("升级测试-") })
            .sorted(by: { $0.name < $1.name })
            .first else {
            throw HarnessError.fixtureLedgerNotFound
        }
        let accounts = try context.fetch(FetchDescriptor<Account>())
        guard let account = accounts
            .filter({ !$0.isArchived && $0.ledger?.id == ledger.id })
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .first else {
            throw HarnessError.fixtureAccountNotFound
        }
        let categories = try context.fetch(FetchDescriptor<Category>())
        guard let category = categories
            .filter({ $0.ledger?.id == ledger.id && $0.type == .expense && !$0.isHidden })
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .first else {
            throw HarnessError.fixtureCategoryNotFound
        }

        let service = TransactionService(modelContext: context)
        let previousOperationTransactions = try context.fetch(FetchDescriptor<Transaction>())
            .filter { $0.note?.hasPrefix("UPGRADE_POSTOPERATIONS_") == true }
        for transaction in previousOperationTransactions {
            _ = try service.delete(id: transaction.id)
        }

        let baselineTransactions = try context.fetch(FetchDescriptor<Transaction>())
        let baselineTransactionLines = Dictionary(uniqueKeysWithValues: baselineTransactions.map {
            ($0.id, transactionLine($0))
        })
        let baselineBalances = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0.balance) })
        let baselineSentinels = sentinelCounts(
            ledgers: ledgers,
            transactions: baselineTransactions
        )
        let legacyIncome = baselineTransactions.first {
            $0.note == "UPGRADE_SENTINEL_LEGACY_INCOME"
        }
        let legacyIncomeResolved = legacyIncome.map {
            $0.toAccount == nil &&
            $0.fromAccount != nil &&
            TransactionAccountResolver.primaryAccount(for: $0)?.id == $0.fromAccount?.id
        } ?? false

        let baseDraft = TransactionDraft(
            ledgerID: ledger.id,
            type: .expense,
            amount: Decimal(string: "19.99")!,
            date: Date(),
            primaryAccountID: account.id,
            destinationAccountID: nil,
            categoryID: category.id,
            tagIDs: [],
            note: "UPGRADE_POSTOPERATIONS_TEMP_\(profile)",
            payee: "升级验证"
        )

        let firstReceipt = try service.create(baseDraft)
        let countAfterFirstCreate = try context.fetchCount(FetchDescriptor<Transaction>())
        let balanceAfterFirstCreate = account.balance
        _ = try service.delete(id: firstReceipt.transactionID)
        let countAfterFirstUndo = try context.fetchCount(FetchDescriptor<Transaction>())
        let balanceAfterFirstUndo = account.balance

        let finalDraft = TransactionDraft(
            ledgerID: ledger.id,
            type: .expense,
            amount: Decimal(string: "31.25")!,
            date: Date(),
            primaryAccountID: account.id,
            destinationAccountID: nil,
            categoryID: category.id,
            tagIDs: [],
            note: "UPGRADE_POSTOPERATIONS_FINAL_\(profile)",
            payee: "升级验证"
        )
        let finalReceipt = try service.create(finalDraft)
        let balanceAfterFinalCreate = account.balance
        let updatedDraft = TransactionDraft(
            ledgerID: ledger.id,
            type: .expense,
            amount: Decimal(string: "62.50")!,
            date: finalDraft.date,
            primaryAccountID: account.id,
            destinationAccountID: nil,
            categoryID: category.id,
            tagIDs: [],
            note: finalDraft.note,
            payee: finalDraft.payee
        )
        _ = try service.update(id: finalReceipt.transactionID, with: updatedDraft)
        let countAfterUpdate = try context.fetchCount(FetchDescriptor<Transaction>())
        let balanceAfterUpdate = account.balance
        let finalUndoToken = try service.delete(id: finalReceipt.transactionID)
        let countAfterDelete = try context.fetchCount(FetchDescriptor<Transaction>())
        let balanceAfterDelete = account.balance
        _ = try service.undo(finalUndoToken)

        let finalTransactions = try context.fetch(FetchDescriptor<Transaction>())
        let finalAccounts = try context.fetch(FetchDescriptor<Account>())
        let finalLedgers = try context.fetch(FetchDescriptor<Ledger>())
        let finalSentinels = sentinelCounts(
            ledgers: finalLedgers,
            transactions: finalTransactions
        )
        let finalTransactionByID = Dictionary(uniqueKeysWithValues: finalTransactions.map {
            ($0.id, transactionLine($0))
        })
        let unchangedOriginalTransactions = baselineTransactionLines.allSatisfy {
            finalTransactionByID[$0.key] == $0.value
        }
        let unchangedOtherAccountBalances = finalAccounts.allSatisfy { finalAccount in
            guard finalAccount.id != account.id else { return true }
            return baselineBalances[finalAccount.id] == finalAccount.balance
        }
        let budgetSummary = try BudgetCalculator(modelContext: context)
            .summary(ledgerID: ledger.id, at: Date())

        let expectedFinalBalance = (baselineBalances[account.id] ?? 0) - Decimal(string: "62.50")!
        let checks = [
            "legacyIncomeResolved": legacyIncomeResolved,
            "firstCreateCount": countAfterFirstCreate == baselineTransactions.count + 1,
            "firstCreateBalance": balanceAfterFirstCreate == (baselineBalances[account.id] ?? 0) - Decimal(string: "19.99")!,
            "firstUndoCount": countAfterFirstUndo == baselineTransactions.count,
            "firstUndoBalance": balanceAfterFirstUndo == baselineBalances[account.id],
            "finalCreateBalance": balanceAfterFinalCreate == (baselineBalances[account.id] ?? 0) - Decimal(string: "31.25")!,
            "updateCount": countAfterUpdate == baselineTransactions.count + 1,
            "updateBalance": balanceAfterUpdate == expectedFinalBalance,
            "deleteCount": countAfterDelete == baselineTransactions.count,
            "deleteBalance": balanceAfterDelete == baselineBalances[account.id],
            "finalCount": finalTransactions.count == baselineTransactions.count + 1,
            "finalBalance": account.balance == expectedFinalBalance,
            "originalTransactionsUnchanged": unchangedOriginalTransactions,
            "otherAccountBalancesUnchanged": unchangedOtherAccountBalances,
            "sentinelsUnchanged": finalSentinels == baselineSentinels,
            "finalTransactionPresent": finalTransactions.contains {
                $0.id == finalReceipt.transactionID &&
                $0.amount == Decimal(string: "62.50")! &&
                $0.note == finalDraft.note
            }
        ]
        let report = UpgradeOperationsReport(
            profile: profile,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            passed: checks.values.allSatisfy { $0 },
            checks: checks,
            ledgerID: ledger.id.uuidString,
            accountID: account.id.uuidString,
            baselineTransactionCount: baselineTransactions.count,
            finalTransactionCount: finalTransactions.count,
            baselineAccountBalance: decimalString(baselineBalances[account.id] ?? 0),
            finalAccountBalance: decimalString(account.balance),
            expectedFinalAccountBalance: decimalString(expectedFinalBalance),
            finalTransactionID: finalReceipt.transactionID.uuidString,
            legacyIncomeID: legacyIncome?.id.uuidString,
            budgetSummary: UpgradeBudgetSummary(
                totalBudget: decimalString(budgetSummary.totalBudget),
                coveredExpense: decimalString(budgetSummary.coveredExpense),
                uncoveredExpense: decimalString(budgetSummary.uncoveredExpense),
                remaining: decimalString(budgetSummary.remaining),
                safeDaily: decimalString(budgetSummary.safeDaily),
                activeBudgetCount: budgetSummary.activeBudgetCount
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent("upgrade-postoperations.json")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func writeManifest(
        stage: String,
        profile: String,
        context: ModelContext
    ) throws -> URL {
        let ledgers = try context.fetch(FetchDescriptor<Ledger>())
        let accounts = try context.fetch(FetchDescriptor<Account>())
        let categories = try context.fetch(FetchDescriptor<Category>())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        let budgets = try context.fetch(FetchDescriptor<Budget>())
        let tags = try context.fetch(FetchDescriptor<Tag>())

        let manifest = UpgradeFixtureManifest(
            stage: stage,
            profile: profile,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            ledgerCount: ledgers.count,
            accountCount: accounts.count,
            categoryCount: categories.count,
            transactionCount: transactions.count,
            budgetCount: budgets.count,
            tagCount: tags.count,
            transactionTypeCounts: Dictionary(grouping: transactions, by: { $0.type.rawValue })
                .mapValues { $0.count },
            sentinelNoteCounts: sentinelCounts(ledgers: ledgers, transactions: transactions),
            relationshipIssueCounts: relationshipIssueCounts(
                accounts: accounts,
                categories: categories,
                transactions: transactions,
                budgets: budgets,
                tags: tags
            ),
            accountBalances: Dictionary(uniqueKeysWithValues: accounts.map {
                ($0.id.uuidString, decimalString($0.balance))
            }),
            totalAccountBalance: decimalString(accounts.reduce(Decimal.zero) { $0 + $1.balance }),
            contentChecksum: checksum(
                ledgers: ledgers,
                accounts: accounts,
                categories: categories,
                transactions: transactions,
                budgets: budgets,
                tags: tags
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent("upgrade-\(stage).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func relationshipIssueCounts(
        accounts: [Account],
        categories: [Category],
        transactions: [Transaction],
        budgets: [Budget],
        tags: [Tag]
    ) -> [String: Int] {
        [
            "accountWithoutLedger": accounts.filter { $0.ledger == nil }.count,
            "categoryWithoutLedger": categories.filter { $0.ledger == nil }.count,
            "transactionWithoutLedger": transactions.filter { $0.ledger == nil }.count,
            "expenseWithoutAccount": transactions.filter { $0.type == .expense && $0.fromAccount == nil }.count,
            "incomeWithoutAccount": transactions.filter {
                $0.type == .income && $0.toAccount == nil && $0.fromAccount == nil
            }.count,
            "transferWithoutAccount": transactions.filter {
                $0.type == .transfer && ($0.fromAccount == nil || $0.toAccount == nil)
            }.count,
            "budgetWithoutLedger": budgets.filter { $0.ledger == nil }.count,
            "budgetWithoutCategory": budgets.filter { $0.category == nil }.count,
            "tagWithoutLedger": tags.filter { $0.ledger == nil }.count
        ]
    }

    private static func checksum(
        ledgers: [Ledger],
        accounts: [Account],
        categories: [Category],
        transactions: [Transaction],
        budgets: [Budget],
        tags: [Tag]
    ) -> String {
        var lines: [String] = []
        lines += ledgers.map {
            "L|\($0.id)|\($0.name)|\($0.currencyCode)|\($0.colorHex)|\($0.iconName)|\($0.isArchived)|\($0.isDefault)|\($0.sortOrder)|\($0.ledgerDescription ?? "")"
        }
        lines += accounts.map {
            "A|\($0.id)|\($0.ledger?.id.uuidString ?? "")|\($0.name)|\($0.type.rawValue)|\(decimalString($0.balance))|\($0.creditLimit.map(decimalString) ?? "")|\($0.statementDay.map(String.init) ?? "")|\($0.dueDay.map(String.init) ?? "")|\($0.cardNumberLast4 ?? "")|\($0.colorHex)|\($0.iconName)|\($0.excludeFromTotal)|\($0.isArchived)|\($0.sortOrder)|\($0.note ?? "")"
        }
        lines += categories.map {
            "C|\($0.id)|\($0.ledger?.id.uuidString ?? "")|\($0.parent?.id.uuidString ?? "")|\($0.name)|\($0.type.rawValue)|\($0.iconName)|\($0.colorHex)|\($0.sortOrder)|\($0.isHidden)|\($0.isQuickSelect)"
        }
        lines += transactions.map {
            let tagIDs = ($0.tags ?? []).map { $0.id.uuidString }.sorted().joined(separator: ",")
            return "T|\($0.id)|\($0.ledger?.id.uuidString ?? "")|\(decimalString($0.amount))|\($0.date.timeIntervalSince1970)|\($0.type.rawValue)|\($0.fromAccount?.id.uuidString ?? "")|\($0.toAccount?.id.uuidString ?? "")|\($0.category?.id.uuidString ?? "")|\($0.note ?? "")|\($0.payee ?? "")|\(tagIDs)"
        }
        lines += budgets.map {
            "B|\($0.id)|\($0.ledger?.id.uuidString ?? "")|\($0.category?.id.uuidString ?? "")|\(decimalString($0.amount))|\($0.period.rawValue)|\($0.startDate.timeIntervalSince1970)|\($0.endDate.timeIntervalSince1970)|\($0.enableRollover)|\(decimalString($0.rolloverAmount))"
        }
        lines += tags.map {
            let transactionIDs = ($0.transactions ?? []).map { $0.id.uuidString }.sorted().joined(separator: ",")
            return "G|\($0.id)|\($0.ledger?.id.uuidString ?? "")|\($0.name)|\($0.colorHex)|\($0.sortOrder)|\(transactionIDs)"
        }
        let stable = lines.sorted().joined(separator: "\n")
        return SHA256.hash(data: Data(stable.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func sentinelCounts(
        ledgers: [Ledger],
        transactions: [Transaction]
    ) -> [String: Int] {
        [
            "legacyIncome": transactions.filter { $0.note == "UPGRADE_SENTINEL_LEGACY_INCOME" }.count,
            "orphanExpense": transactions.filter { $0.note == "UPGRADE_SENTINEL_ORPHAN_EXPENSE" }.count,
            "adjustment": transactions.filter { $0.note == "UPGRADE_SENTINEL_ADJUSTMENT" }.count,
            "archivedLedger": ledgers.filter { $0.ledgerDescription == "UPGRADE_SENTINEL_ARCHIVED_LEDGER" }.count
        ]
    }

    private static func transactionLine(_ transaction: Transaction) -> String {
        let tagIDs = (transaction.tags ?? []).map { $0.id.uuidString }.sorted().joined(separator: ",")
        return "T|\(transaction.id)|\(transaction.ledger?.id.uuidString ?? "")|\(decimalString(transaction.amount))|\(transaction.date.timeIntervalSince1970)|\(transaction.type.rawValue)|\(transaction.fromAccount?.id.uuidString ?? "")|\(transaction.toAccount?.id.uuidString ?? "")|\(transaction.category?.id.uuidString ?? "")|\(transaction.note ?? "")|\(transaction.payee ?? "")|\(tagIDs)"
    }

    private static func decimalString(_ value: Decimal) -> String {
        var copy = value
        return NSDecimalString(&copy, Locale(identifier: "en_US_POSIX"))
    }
}

private struct UpgradeFixtureManifest: Codable {
    let stage: String
    let profile: String
    let appVersion: String
    let ledgerCount: Int
    let accountCount: Int
    let categoryCount: Int
    let transactionCount: Int
    let budgetCount: Int
    let tagCount: Int
    let transactionTypeCounts: [String: Int]
    let sentinelNoteCounts: [String: Int]
    let relationshipIssueCounts: [String: Int]
    let accountBalances: [String: String]
    let totalAccountBalance: String
    let contentChecksum: String
}

private struct UpgradeOperationsReport: Codable {
    let profile: String
    let appVersion: String
    let passed: Bool
    let checks: [String: Bool]
    let ledgerID: String
    let accountID: String
    let baselineTransactionCount: Int
    let finalTransactionCount: Int
    let baselineAccountBalance: String
    let finalAccountBalance: String
    let expectedFinalAccountBalance: String
    let finalTransactionID: String
    let legacyIncomeID: String?
    let budgetSummary: UpgradeBudgetSummary
}

private struct UpgradeBudgetSummary: Codable {
    let totalBudget: String
    let coveredExpense: String
    let uncoveredExpense: String
    let remaining: String
    let safeDaily: String
    let activeBudgetCount: Int
}

private enum HarnessError: LocalizedError {
    case storeUnavailable
    case unsupportedOperation(String)
    case fixtureLedgerNotFound
    case fixtureAccountNotFound
    case fixtureCategoryNotFound

    var errorDescription: String? {
        switch self {
        case .storeUnavailable:
            return "升级测试无法打开生产 store"
        case .unsupportedOperation(let operation):
            return "不支持的升级测试操作：\(operation)"
        case .fixtureLedgerNotFound:
            return "未找到升级测试账本"
        case .fixtureAccountNotFound:
            return "未找到升级测试账户"
        case .fixtureCategoryNotFound:
            return "未找到升级测试支出分类"
        }
    }
}
#endif
