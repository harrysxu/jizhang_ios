//
//  TransactionModelTests.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class TransactionModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testLedger: Ledger!
    var testAccount: Account!
    var testCategory: jizhang.Category!
    
    override func setUp() async throws {
        modelContainer = try TestHelpers.createInMemoryContainer()
        modelContext = ModelContext(modelContainer)
        
        testLedger = TestHelpers.createTestLedger(context: modelContext)
        testAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            balance: 1000,
            context: modelContext
        )
        testCategory = Category(
            ledger: testLedger,
            name: "测试分类",
            type: .expense
        )
        modelContext.insert(testCategory)
        
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        try TestHelpers.cleanup(context: modelContext)
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 交易类型测试
    
    func testTransactionTypes() {
        XCTAssertEqual(TransactionType.expense.displayName, "支出")
        XCTAssertEqual(TransactionType.income.displayName, "收入")
        XCTAssertEqual(TransactionType.transfer.displayName, "转账")
        XCTAssertEqual(TransactionType.adjustment.displayName, "调整")
    }
    
    func testTransactionTypeIcons() {
        XCTAssertEqual(TransactionType.expense.icon, "arrow.down.circle.fill")
        XCTAssertEqual(TransactionType.income.icon, "arrow.up.circle.fill")
        XCTAssertEqual(TransactionType.transfer.icon, "arrow.left.arrow.right.circle.fill")
        XCTAssertEqual(TransactionType.adjustment.icon, "slider.horizontal.3")
    }
    
    // MARK: - 交易创建测试
    
    func testCreateExpenseTransaction() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory,
            note: "测试支出"
        )
        
        XCTAssertEqual(transaction.amount, 100)
        XCTAssertEqual(transaction.type, .expense)
        XCTAssertEqual(transaction.fromAccount?.id, testAccount.id)
        XCTAssertEqual(transaction.category?.id, testCategory.id)
        XCTAssertEqual(transaction.note, "测试支出")
    }
    
    func testCreateIncomeTransaction() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 500,
            date: Date(),
            type: .income,
            toAccount: testAccount,
            category: testCategory
        )
        
        XCTAssertEqual(transaction.type, .income)
        XCTAssertEqual(transaction.toAccount?.id, testAccount.id)
    }
    
    // MARK: - displayAmount 测试
    
    func testDisplayAmountForExpense() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100.50,
            date: Date(),
            type: .expense,
            fromAccount: testAccount
        )
        
        XCTAssertTrue(transaction.displayAmount.hasPrefix("-"))
        XCTAssertTrue(transaction.displayAmount.contains("100.50"))
    }
    
    func testDisplayAmountForIncome() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 200.75,
            date: Date(),
            type: .income,
            toAccount: testAccount
        )
        
        XCTAssertTrue(transaction.displayAmount.hasPrefix("+"))
        XCTAssertTrue(transaction.displayAmount.contains("200.75"))
    }
    
    func testDisplayAmountForTransfer() {
        let toAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "目标账户",
            context: modelContext
        )
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 300,
            date: Date(),
            type: .transfer,
            fromAccount: testAccount,
            toAccount: toAccount
        )
        
        // 转账不带符号
        XCTAssertFalse(transaction.displayAmount.hasPrefix("+"))
        XCTAssertFalse(transaction.displayAmount.hasPrefix("-"))
        XCTAssertTrue(transaction.displayAmount.contains("300.00"))
    }
    
    // MARK: - primaryAccount 测试
    
    func testPrimaryAccountForExpense() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: testAccount
        )
        
        XCTAssertEqual(transaction.primaryAccount?.id, testAccount.id)
    }
    
    func testPrimaryAccountForIncome() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .income,
            toAccount: testAccount
        )
        
        XCTAssertEqual(transaction.primaryAccount?.id, testAccount.id)
    }
    
    func testPrimaryAccountForTransfer() {
        let toAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "目标账户",
            context: modelContext
        )
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .transfer,
            fromAccount: testAccount,
            toAccount: toAccount
        )
        
        // 转账的主要账户是fromAccount
        XCTAssertEqual(transaction.primaryAccount?.id, testAccount.id)
    }
    
    // MARK: - updateAccountBalance 测试
    
    func testUpdateBalanceForExpense() {
        let initialBalance = testAccount.balance
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: testAccount
        )
        
        transaction.updateAccountBalance()
        
        XCTAssertEqual(testAccount.balance, initialBalance - 100)
    }
    
    func testUpdateBalanceForIncome() {
        let initialBalance = testAccount.balance
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: Date(),
            type: .income,
            toAccount: testAccount
        )
        
        transaction.updateAccountBalance()
        
        XCTAssertEqual(testAccount.balance, initialBalance + 200)
    }
    
    func testUpdateBalanceForTransfer() {
        let toAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "目标账户",
            balance: 500,
            context: modelContext
        )
        
        let fromInitialBalance = testAccount.balance
        let toInitialBalance = toAccount.balance
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 300,
            date: Date(),
            type: .transfer,
            fromAccount: testAccount,
            toAccount: toAccount
        )
        
        transaction.updateAccountBalance()
        
        XCTAssertEqual(testAccount.balance, fromInitialBalance - 300)
        XCTAssertEqual(toAccount.balance, toInitialBalance + 300)
    }
    
    // MARK: - revertAccountBalance 测试
    
    func testRevertBalanceForExpense() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: testAccount
        )
        
        transaction.updateAccountBalance()
        let balanceAfterUpdate = testAccount.balance
        
        transaction.revertAccountBalance()
        
        XCTAssertEqual(testAccount.balance, balanceAfterUpdate + 100)
    }
    
    func testRevertBalanceForIncome() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: Date(),
            type: .income,
            toAccount: testAccount
        )
        
        transaction.updateAccountBalance()
        let balanceAfterUpdate = testAccount.balance
        
        transaction.revertAccountBalance()
        
        XCTAssertEqual(testAccount.balance, balanceAfterUpdate - 200)
    }
    
    func testRevertBalanceForTransfer() {
        let toAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "目标账户",
            balance: 500,
            context: modelContext
        )
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 300,
            date: Date(),
            type: .transfer,
            fromAccount: testAccount,
            toAccount: toAccount
        )
        
        transaction.updateAccountBalance()
        
        let fromBalanceAfterUpdate = testAccount.balance
        let toBalanceAfterUpdate = toAccount.balance
        
        transaction.revertAccountBalance()
        
        XCTAssertEqual(testAccount.balance, fromBalanceAfterUpdate + 300)
        XCTAssertEqual(toAccount.balance, toBalanceAfterUpdate - 300)
    }
    
    // MARK: - 转账验证测试
    
    func testTransferRequiresBothAccounts() {
        let toAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            name: "目标账户",
            context: modelContext
        )
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .transfer,
            fromAccount: testAccount,
            toAccount: toAccount
        )
        
        XCTAssertNotNil(transaction.fromAccount)
        XCTAssertNotNil(transaction.toAccount)
        XCTAssertNotEqual(transaction.fromAccount?.id, transaction.toAccount?.id)
    }
    
    // MARK: - 时间戳测试
    
    func testTransactionTimestamps() {
        let beforeCreation = Date()
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: testAccount
        )
        
        let afterCreation = Date()
        
        XCTAssertTrue(transaction.createdAt >= beforeCreation)
        XCTAssertTrue(transaction.createdAt <= afterCreation)
        XCTAssertEqual(transaction.createdAt, transaction.modifiedAt)
    }
    
    func testTransactionModifiedAtUpdates() {
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: testAccount
        )
        
        let originalModifiedAt = transaction.modifiedAt
        
        // 模拟时间流逝
        Thread.sleep(forTimeInterval: 0.1)
        
        transaction.updateAccountBalance()
        
        XCTAssertTrue(transaction.modifiedAt > originalModifiedAt)
    }
}
