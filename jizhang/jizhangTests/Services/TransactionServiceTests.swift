import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class TransactionServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var ledger: Ledger!
    private var account: Account!
    private var secondAccount: Account!
    private var expenseCategory: jizhang.Category!
    private var incomeCategory: jizhang.Category!
    private var now: Date!
    private var service: TransactionService!

    override func setUpWithError() throws {
        container = try TestHelpers.createInMemoryContainer()
        context = ModelContext(container)
        ledger = TestHelpers.createTestLedger(context: context)
        account = TestHelpers.createTestAccount(
            ledger: ledger,
            name: "现金",
            balance: 1_000,
            context: context
        )
        secondAccount = TestHelpers.createTestAccount(
            ledger: ledger,
            name: "银行卡",
            balance: 500,
            context: context
        )
        expenseCategory = jizhang.Category(
            ledger: ledger,
            name: "餐饮",
            type: .expense
        )
        incomeCategory = jizhang.Category(
            ledger: ledger,
            name: "工资",
            type: .income
        )
        context.insert(expenseCategory)
        context.insert(incomeCategory)
        try context.save()

        now = Date(timeIntervalSince1970: 1_800_000_000)
        service = TransactionService(modelContext: context, now: { [unowned self] in self.now })
    }

    override func tearDown() {
        service = nil
        ledger = nil
        account = nil
        secondAccount = nil
        context = nil
        container = nil
    }

    func testCreateExpenseUpdatesBalanceAndPersistsTransaction() throws {
        let receipt = try service.create(draft(
            type: .expense,
            amount: 120,
            account: account,
            category: expenseCategory
        ))

        XCTAssertEqual(account.balance, 880)
        XCTAssertEqual(receipt.affectedBalances[account.id], 880)
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.id, receipt.transactionID)
    }

    func testCreateIncomeWritesCompatibilityRelationshipsButCreditsOnce() throws {
        _ = try service.create(draft(
            type: .income,
            amount: 300,
            account: account,
            category: incomeCategory
        ))

        XCTAssertEqual(account.balance, 1_300)
        let transaction = try XCTUnwrap(context.fetch(FetchDescriptor<Transaction>()).first)
        XCTAssertEqual(transaction.fromAccount?.id, account.id)
        XCTAssertEqual(transaction.toAccount?.id, account.id)
    }

    func testLegacyIncomeUsesFromAccountWhenUpdating() throws {
        let legacy = Transaction(
            ledger: ledger,
            amount: 100,
            date: now,
            type: .income,
            fromAccount: account,
            toAccount: nil,
            category: incomeCategory
        )
        context.insert(legacy)
        account.balance += 100
        try context.save()

        _ = try service.update(
            id: legacy.id,
            with: draft(type: .income, amount: 250, account: account, category: incomeCategory)
        )

        XCTAssertEqual(account.balance, 1_250)
        XCTAssertEqual(legacy.toAccount?.id, account.id)
    }

    func testUpdateAppliesNewEffectMinusOldEffectAcrossAccounts() throws {
        let receipt = try service.create(draft(
            type: .expense,
            amount: 100,
            account: account,
            category: expenseCategory
        ))

        _ = try service.update(
            id: receipt.transactionID,
            with: draft(type: .expense, amount: 40, account: secondAccount, category: expenseCategory)
        )

        XCTAssertEqual(account.balance, 1_000)
        XCTAssertEqual(secondAccount.balance, 460)
    }

    func testTransferPreservesCombinedBalance() throws {
        _ = try service.create(TransactionDraft(
            ledgerID: ledger.id,
            type: .transfer,
            amount: 200,
            date: now,
            primaryAccountID: account.id,
            destinationAccountID: secondAccount.id,
            categoryID: nil,
            tagIDs: [],
            note: nil,
            payee: nil
        ))

        XCTAssertEqual(account.balance, 800)
        XCTAssertEqual(secondAccount.balance, 700)
        XCTAssertEqual(account.balance + secondAccount.balance, 1_500)
    }

    func testDeleteAndUndoRestoreIdentityAndBalance() throws {
        let receipt = try service.create(draft(
            type: .expense,
            amount: 75,
            account: account,
            category: expenseCategory
        ))
        let token = try service.delete(id: receipt.transactionID)
        XCTAssertEqual(account.balance, 1_000)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Transaction>()).isEmpty)

        _ = try service.undo(token)

        XCTAssertEqual(account.balance, 925)
        let restored = try XCTUnwrap(context.fetch(FetchDescriptor<Transaction>()).first)
        XCTAssertEqual(restored.id, receipt.transactionID)
    }

    func testExpiredUndoDoesNotChangeStore() throws {
        let receipt = try service.create(draft(
            type: .expense,
            amount: 75,
            account: account,
            category: expenseCategory
        ))
        let token = try service.delete(id: receipt.transactionID)
        now = now.addingTimeInterval(6)

        XCTAssertThrowsError(try service.undo(token)) { error in
            guard case TransactionServiceError.undoExpired = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(account.balance, 1_000)
    }

    func testRejectsCrossLedgerAccountWithoutPartialWrite() throws {
        let otherLedger = TestHelpers.createTestLedger(name: "其他账本", context: context)
        let otherAccount = TestHelpers.createTestAccount(ledger: otherLedger, context: context)
        try context.save()

        XCTAssertThrowsError(try service.create(draft(
            type: .expense,
            amount: 100,
            account: otherAccount,
            category: expenseCategory
        ))) { error in
            guard case TransactionServiceError.crossLedgerRelationship = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(account.balance, 1_000)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Transaction>()).isEmpty)
    }

    func testBalanceAdjustmentCreatesSignedAuditTransaction() throws {
        _ = try service.adjustBalance(accountID: account.id, to: 850, note: "对账")

        XCTAssertEqual(account.balance, 850)
        let transaction = try XCTUnwrap(context.fetch(FetchDescriptor<Transaction>()).first)
        XCTAssertEqual(transaction.type, .adjustment)
        XCTAssertEqual(transaction.amount, -150)
        XCTAssertEqual(transaction.note, "对账")
    }

    private func draft(
        type: TransactionType,
        amount: Decimal,
        account: Account,
        category: jizhang.Category
    ) -> TransactionDraft {
        TransactionDraft(
            ledgerID: ledger.id,
            type: type,
            amount: amount,
            date: now,
            primaryAccountID: account.id,
            destinationAccountID: nil,
            categoryID: category.id,
            tagIDs: [],
            note: nil,
            payee: nil
        )
    }
}
