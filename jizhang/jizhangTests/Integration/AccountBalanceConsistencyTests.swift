//
//  AccountBalanceConsistencyTests.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest
import SwiftData
@testable import jizhang

/// 账户余额一致性测试 - 验证交易对账户余额的影响
@MainActor
final class AccountBalanceConsistencyTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testLedger: Ledger!
    
    override func setUp() async throws {
        modelContainer = try TestHelpers.createInMemoryContainer()
        modelContext = ModelContext(modelContainer)
        testLedger = TestHelpers.createFullTestLedger(context: modelContext)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        try TestHelpers.cleanup(context: modelContext)
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 多笔交易余额测试
    
    func testMultipleTransactionsBalanceCorrectness() {
        let account = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "测试账户",
            balance: 1000,
            context: modelContext
        )
        
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        let initialBalance = account.balance
        
        // 创建多笔支出交易
        let amounts: [Decimal] = [100, 50, 30, 20, 10]
        var transactions: [Transaction] = []
        
        for amount in amounts {
            let transaction = Transaction(
                ledger: testLedger,
                amount: amount,
                date: Date(),
                type: .expense,
                fromAccount: account,
                category: category
            )
            modelContext.insert(transaction)
            transaction.updateAccountBalance()
            transactions.append(transaction)
        }
        
        try? modelContext.save()
        
        // 验证总支出: 100 + 50 + 30 + 20 + 10 = 210
        let expectedBalance = initialBalance - 210
        XCTAssertEqual(account.balance, expectedBalance)
    }
    
    // MARK: - 删除交易后余额回滚测试
    
    func testBalanceRevertsAfterDeletingTransaction() {
        let account = TestHelpers.createTestAccount(
            ledger: testLedger,
            balance: 1000,
            context: modelContext
        )
        
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        let initialBalance = account.balance
        
        // 创建交易
        let transaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(transaction)
        transaction.updateAccountBalance()
        
        XCTAssertEqual(account.balance, initialBalance - 200)
        
        // 删除交易前先回滚余额
        transaction.revertAccountBalance()
        modelContext.delete(transaction)
        
        try? modelContext.save()
        
        // 验证余额恢复
        XCTAssertEqual(account.balance, initialBalance)
    }
    
    // MARK: - 转账双向余额变化测试
    
    func testTransferUpdatesBothAccounts() {
        let fromAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "转出账户",
            balance: 5000,
            context: modelContext
        )
        
        let toAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "转入账户",
            balance: 1000,
            context: modelContext
        )
        
        let fromInitialBalance = fromAccount.balance
        let toInitialBalance = toAccount.balance
        
        // 创建转账交易
        let transaction = Transaction(
            ledger: testLedger,
            amount: 1000,
            date: Date(),
            type: .transfer,
            fromAccount: fromAccount,
            toAccount: toAccount
        )
        modelContext.insert(transaction)
        transaction.updateAccountBalance()
        
        try? modelContext.save()
        
        // 验证转出账户减少
        XCTAssertEqual(fromAccount.balance, fromInitialBalance - 1000)
        
        // 验证转入账户增加
        XCTAssertEqual(toAccount.balance, toInitialBalance + 1000)
    }
    
    func testMultipleTransfersMaintainConsistency() {
        let account1 = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "账户1",
            balance: 10000,
            context: modelContext
        )
        
        let account2 = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "账户2",
            balance: 5000,
            context: modelContext
        )
        
        let account3 = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "账户3",
            balance: 2000,
            context: modelContext
        )
        
        let totalInitialBalance = account1.balance + account2.balance + account3.balance
        
        // 多次转账
        let transfer1 = Transaction(
            ledger: testLedger,
            amount: 1000,
            date: Date(),
            type: .transfer,
            fromAccount: account1,
            toAccount: account2
        )
        modelContext.insert(transfer1)
        transfer1.updateAccountBalance()
        
        let transfer2 = Transaction(
            ledger: testLedger,
            amount: 500,
            date: Date(),
            type: .transfer,
            fromAccount: account2,
            toAccount: account3
        )
        modelContext.insert(transfer2)
        transfer2.updateAccountBalance()
        
        let transfer3 = Transaction(
            ledger: testLedger,
            amount: 300,
            date: Date(),
            type: .transfer,
            fromAccount: account3,
            toAccount: account1
        )
        modelContext.insert(transfer3)
        transfer3.updateAccountBalance()
        
        try? modelContext.save()
        
        // 验证总资产不变
        let totalFinalBalance = account1.balance + account2.balance + account3.balance
        XCTAssertEqual(totalFinalBalance, totalInitialBalance)
    }
    
    // MARK: - 信用卡可用额度测试
    
    func testCreditCardAvailableBalance() {
        let creditCard = TestHelpers.createCreditCardAccount(
            ledger: testLedger,
            balance: 0,
            creditLimit: 10000,
            context: modelContext
        )
        
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        // 验证初始可用额度
        XCTAssertEqual(creditCard.availableBalance, 10000)
        
        // 消费1000
        let transaction1 = Transaction(
            ledger: testLedger,
            amount: 1000,
            date: Date(),
            type: .expense,
            fromAccount: creditCard,
            category: category
        )
        modelContext.insert(transaction1)
        transaction1.updateAccountBalance()
        
        // 余额变为-1000，可用额度为9000
        XCTAssertEqual(creditCard.balance, -1000)
        XCTAssertEqual(creditCard.availableBalance, 9000)
        
        // 再消费3000
        let transaction2 = Transaction(
            ledger: testLedger,
            amount: 3000,
            date: Date(),
            type: .expense,
            fromAccount: creditCard,
            category: category
        )
        modelContext.insert(transaction2)
        transaction2.updateAccountBalance()
        
        // 余额变为-4000，可用额度为6000
        XCTAssertEqual(creditCard.balance, -4000)
        XCTAssertEqual(creditCard.availableBalance, 6000)
    }
    
    // MARK: - 余额调整功能测试
    
    func testAdjustBalanceCreatesCorrectTransaction() {
        let account = TestHelpers.createTestAccount(
            ledger: testLedger,
            balance: 1000,
            context: modelContext
        )
        
        // 调整余额到1500
        let transaction = account.adjustBalance(to: 1500, note: "对账调整")
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 验证余额更新
        XCTAssertEqual(account.balance, 1500)
        
        // 验证交易类型
        XCTAssertEqual(transaction.type, .adjustment)
        XCTAssertEqual(transaction.amount, 500)
        XCTAssertEqual(transaction.note, "对账调整")
    }
    
    func testAdjustBalanceDown() {
        let account = TestHelpers.createTestAccount(
            ledger: testLedger,
            balance: 1000,
            context: modelContext
        )
        
        // 调整余额到800（减少）
        let transaction = account.adjustBalance(to: 800)
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        XCTAssertEqual(account.balance, 800)
        XCTAssertEqual(transaction.amount, 200)
    }
    
    // MARK: - 收入和支出混合测试
    
    func testMixedIncomeAndExpenseTransactions() {
        let account = TestHelpers.createTestAccount(
            ledger: testLedger,
            balance: 1000,
            context: modelContext
        )
        
        let expenseCategory = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        let incomeCategory = (testLedger.categories ?? []).filter { $0.type == .income }.first!
        
        let initialBalance = account.balance
        
        // 收入
        let income = Transaction(
            ledger: testLedger,
            amount: 5000,
            date: Date(),
            type: .income,
            toAccount: account,
            category: incomeCategory
        )
        modelContext.insert(income)
        income.updateAccountBalance()
        
        // 支出
        let expense1 = Transaction(
            ledger: testLedger,
            amount: 200,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: expenseCategory
        )
        modelContext.insert(expense1)
        expense1.updateAccountBalance()
        
        let expense2 = Transaction(
            ledger: testLedger,
            amount: 300,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: expenseCategory
        )
        modelContext.insert(expense2)
        expense2.updateAccountBalance()
        
        try? modelContext.save()
        
        // 验证最终余额: 1000 + 5000 - 200 - 300 = 5500
        XCTAssertEqual(account.balance, initialBalance + 5000 - 200 - 300)
    }
}
