//
//  AccountModelTests.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class AccountModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testLedger: Ledger!
    
    override func setUp() async throws {
        modelContainer = try TestHelpers.createInMemoryContainer()
        modelContext = ModelContext(modelContainer)
        testLedger = TestHelpers.createTestLedger(context: modelContext)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        try TestHelpers.cleanup(context: modelContext)
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 账户类型测试
    
    func testAccountTypes() {
        XCTAssertEqual(AccountType.cash.displayName, "现金")
        XCTAssertEqual(AccountType.checking.displayName, "储蓄卡")
        XCTAssertEqual(AccountType.creditCard.displayName, "信用卡")
        XCTAssertEqual(AccountType.eWallet.displayName, "电子钱包")
    }
    
    func testAccountTypeDefaultIcons() {
        XCTAssertEqual(AccountType.cash.defaultIcon, "banknote.fill")
        XCTAssertEqual(AccountType.checking.defaultIcon, "creditcard.fill")
        XCTAssertEqual(AccountType.creditCard.defaultIcon, "creditcard.circle.fill")
        XCTAssertEqual(AccountType.eWallet.defaultIcon, "iphone")
    }
    
    func testAccountTypeIsAsset() {
        XCTAssertTrue(AccountType.cash.isAsset)
        XCTAssertTrue(AccountType.checking.isAsset)
        XCTAssertTrue(AccountType.eWallet.isAsset)
        XCTAssertFalse(AccountType.creditCard.isAsset)
    }
    
    func testAccountTypeSupportsCreditLimit() {
        XCTAssertTrue(AccountType.creditCard.supportsCreditLimit)
        XCTAssertFalse(AccountType.cash.supportsCreditLimit)
        XCTAssertFalse(AccountType.checking.supportsCreditLimit)
        XCTAssertFalse(AccountType.eWallet.supportsCreditLimit)
    }
    
    // MARK: - 账户创建测试
    
    func testCreateCashAccount() {
        let account = Account(
            ledger: testLedger,
            name: "现金",
            type: .cash,
            balance: 500
        )
        
        XCTAssertEqual(account.name, "现金")
        XCTAssertEqual(account.type, .cash)
        XCTAssertEqual(account.balance, 500)
        XCTAssertFalse(account.isArchived)
        XCTAssertFalse(account.excludeFromTotal)
    }
    
    func testCreateCheckingAccount() {
        let account = Account(
            ledger: testLedger,
            name: "银行卡",
            type: .checking,
            balance: 5000
        )
        
        XCTAssertEqual(account.type, .checking)
        XCTAssertEqual(account.balance, 5000)
    }
    
    func testCreateCreditCardAccount() {
        let account = Account(
            ledger: testLedger,
            name: "信用卡",
            type: .creditCard,
            balance: -1000
        )
        account.creditLimit = 10000
        account.statementDay = 5
        account.dueDay = 25
        
        XCTAssertEqual(account.type, .creditCard)
        XCTAssertEqual(account.balance, -1000)
        XCTAssertEqual(account.creditLimit, 10000)
        XCTAssertEqual(account.statementDay, 5)
        XCTAssertEqual(account.dueDay, 25)
    }
    
    // MARK: - 可用余额测试
    
    func testAvailableBalanceForCash() {
        let account = Account(
            ledger: testLedger,
            name: "现金",
            type: .cash,
            balance: 1000
        )
        
        XCTAssertEqual(account.availableBalance, 1000)
    }
    
    func testAvailableBalanceForChecking() {
        let account = Account(
            ledger: testLedger,
            name: "银行卡",
            type: .checking,
            balance: 5000
        )
        
        XCTAssertEqual(account.availableBalance, 5000)
    }
    
    func testAvailableBalanceForCreditCard() {
        let account = Account(
            ledger: testLedger,
            name: "信用卡",
            type: .creditCard,
            balance: -3000 // 欠款3000
        )
        account.creditLimit = 10000
        
        // 可用额度 = 信用额度 - 已用额度 = 10000 - 3000 = 7000
        XCTAssertEqual(account.availableBalance, 7000)
    }
    
    func testAvailableBalanceForCreditCardWithoutDebt() {
        let account = Account(
            ledger: testLedger,
            name: "信用卡",
            type: .creditCard,
            balance: 0
        )
        account.creditLimit = 10000
        
        XCTAssertEqual(account.availableBalance, 10000)
    }
    
    // MARK: - 余额调整测试
    
    func testAdjustBalanceIncrease() {
        let account = Account(
            ledger: testLedger,
            name: "现金",
            type: .cash,
            balance: 1000
        )
        modelContext.insert(account)
        
        let transaction = account.adjustBalance(to: 1500, note: "增加余额")
        
        XCTAssertEqual(account.balance, 1500)
        XCTAssertEqual(transaction.type, .adjustment)
        XCTAssertEqual(transaction.amount, 500)
        XCTAssertEqual(transaction.note, "增加余额")
    }
    
    func testAdjustBalanceDecrease() {
        let account = Account(
            ledger: testLedger,
            name: "现金",
            type: .cash,
            balance: 1000
        )
        modelContext.insert(account)
        
        let transaction = account.adjustBalance(to: 800, note: "减少余额")
        
        XCTAssertEqual(account.balance, 800)
        XCTAssertEqual(transaction.amount, 200)
    }
    
    func testAdjustBalanceToZero() {
        let account = Account(
            ledger: testLedger,
            name: "现金",
            type: .cash,
            balance: 500
        )
        modelContext.insert(account)
        
        let transaction = account.adjustBalance(to: 0)
        
        XCTAssertEqual(account.balance, 0)
        XCTAssertEqual(transaction.amount, 500)
    }
    
    // MARK: - 账户归档测试
    
    func testArchiveAccount() {
        let account = Account(
            ledger: testLedger,
            name: "旧账户",
            type: .cash
        )
        
        XCTAssertFalse(account.isArchived)
        
        account.isArchived = true
        
        XCTAssertTrue(account.isArchived)
    }
    
    // MARK: - 排除总资产统计测试
    
    func testExcludeFromTotal() {
        let account = Account(
            ledger: testLedger,
            name: "投资账户",
            type: .checking,
            balance: 50000
        )
        
        XCTAssertFalse(account.excludeFromTotal)
        
        account.excludeFromTotal = true
        
        XCTAssertTrue(account.excludeFromTotal)
    }
    
    // MARK: - 账户排序测试
    
    func testAccountSortOrder() {
        let account1 = Account(
            ledger: testLedger,
            name: "账户1",
            type: .cash,
            sortOrder: 0
        )
        
        let account2 = Account(
            ledger: testLedger,
            name: "账户2",
            type: .cash,
            sortOrder: 1
        )
        
        let account3 = Account(
            ledger: testLedger,
            name: "账户3",
            type: .cash,
            sortOrder: 2
        )
        
        modelContext.insert(account1)
        modelContext.insert(account2)
        modelContext.insert(account3)
        
        XCTAssertLessThan(account1.sortOrder, account2.sortOrder)
        XCTAssertLessThan(account2.sortOrder, account3.sortOrder)
    }
    
    // MARK: - 卡号后四位测试
    
    func testCardNumberLast4() {
        let account = Account(
            ledger: testLedger,
            name: "银行卡",
            type: .checking
        )
        account.cardNumberLast4 = "1234"
        
        XCTAssertEqual(account.cardNumberLast4, "1234")
    }
    
    // MARK: - 账户备注测试
    
    func testAccountNote() {
        let account = Account(
            ledger: testLedger,
            name: "现金",
            type: .cash
        )
        account.note = "日常零花钱"
        
        XCTAssertEqual(account.note, "日常零花钱")
    }
    
    // MARK: - 创建时间测试
    
    func testAccountCreatedAt() {
        let beforeCreation = Date()
        
        let account = Account(
            ledger: testLedger,
            name: "新账户",
            type: .cash
        )
        
        let afterCreation = Date()
        
        XCTAssertTrue(account.createdAt >= beforeCreation)
        XCTAssertTrue(account.createdAt <= afterCreation)
    }
}
