//
//  LedgerModelTests.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class LedgerModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        modelContainer = try TestHelpers.createInMemoryContainer()
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        try TestHelpers.cleanup(context: modelContext)
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 账本创建测试
    
    func testCreateLedger() {
        let ledger = Ledger(
            name: "个人账本",
            currencyCode: "CNY",
            colorHex: "#007AFF",
            iconName: "book.fill"
        )
        
        XCTAssertEqual(ledger.name, "个人账本")
        XCTAssertEqual(ledger.currencyCode, "CNY")
        XCTAssertEqual(ledger.colorHex, "#007AFF")
        XCTAssertEqual(ledger.iconName, "book.fill")
        XCTAssertFalse(ledger.isArchived)
        XCTAssertFalse(ledger.isDefault)
    }
    
    func testCreateDefaultLedger() {
        let ledger = Ledger(
            name: "默认账本",
            isDefault: true
        )
        
        XCTAssertTrue(ledger.isDefault)
    }
    
    // MARK: - 总资产计算测试
    
    func testTotalAssetsCalculation() {
        let ledger = TestHelpers.createTestLedger(context: modelContext)
        
        let account1 = Account(
            ledger: ledger,
            name: "现金",
            type: .cash,
            balance: 1000
        )
        modelContext.insert(account1)
        
        let account2 = Account(
            ledger: ledger,
            name: "银行卡",
            type: .checking,
            balance: 5000
        )
        modelContext.insert(account2)
        
        try? modelContext.save()
        
        // 总资产 = 1000 + 5000 = 6000
        XCTAssertEqual(ledger.totalAssets, 6000)
    }
    
    func testTotalAssetsExcludesArchivedAccounts() {
        let ledger = TestHelpers.createTestLedger(context: modelContext)
        
        let activeAccount = Account(
            ledger: ledger,
            name: "现金",
            type: .cash,
            balance: 1000
        )
        modelContext.insert(activeAccount)
        
        let archivedAccount = Account(
            ledger: ledger,
            name: "旧账户",
            type: .cash,
            balance: 2000
        )
        archivedAccount.isArchived = true
        modelContext.insert(archivedAccount)
        
        try? modelContext.save()
        
        // 只计入活跃账户
        XCTAssertEqual(ledger.totalAssets, 1000)
    }
    
    func testTotalAssetsExcludesExcludedAccounts() {
        let ledger = TestHelpers.createTestLedger(context: modelContext)
        
        let normalAccount = Account(
            ledger: ledger,
            name: "现金",
            type: .cash,
            balance: 1000
        )
        modelContext.insert(normalAccount)
        
        let excludedAccount = Account(
            ledger: ledger,
            name: "投资账户",
            type: .checking,
            balance: 50000
        )
        excludedAccount.excludeFromTotal = true
        modelContext.insert(excludedAccount)
        
        try? modelContext.save()
        
        // 不计入排除的账户
        XCTAssertEqual(ledger.totalAssets, 1000)
    }
    
    func testTotalAssetsIncludesCreditCardDebt() {
        let ledger = TestHelpers.createTestLedger(context: modelContext)
        
        let cashAccount = Account(
            ledger: ledger,
            name: "现金",
            type: .cash,
            balance: 1000
        )
        modelContext.insert(cashAccount)
        
        let creditCard = Account(
            ledger: ledger,
            name: "信用卡",
            type: .creditCard,
            balance: -500 // 欠款
        )
        modelContext.insert(creditCard)
        
        try? modelContext.save()
        
        // 总资产 = 1000 - 500 = 500
        XCTAssertEqual(ledger.totalAssets, 500)
    }
    
    // MARK: - 活跃账户数量测试
    
    func testActiveAccountsCount() {
        let ledger = TestHelpers.createTestLedger(context: modelContext)
        
        let account1 = Account(ledger: ledger, name: "账户1", type: .cash)
        let account2 = Account(ledger: ledger, name: "账户2", type: .cash)
        let archivedAccount = Account(ledger: ledger, name: "归档账户", type: .cash)
        archivedAccount.isArchived = true
        
        modelContext.insert(account1)
        modelContext.insert(account2)
        modelContext.insert(archivedAccount)
        
        try? modelContext.save()
        
        // 只计入活跃账户
        XCTAssertEqual(ledger.activeAccountsCount, 2)
    }
    
    // MARK: - 本月交易数量测试
    
    func testThisMonthTransactionCount() {
        let ledger = TestHelpers.createTestLedger(context: modelContext)
        let account = TestHelpers.createTestAccount(
            ledger: ledger,
            balance: 10000,
            context: modelContext
        )
        let category = Category(ledger: ledger, name: "餐饮", type: .expense)
        modelContext.insert(category)
        
        let today = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
        
        // 本月交易
        let thisMonthTransaction1 = Transaction(
            ledger: ledger,
            amount: 100,
            date: today,
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(thisMonthTransaction1)
        
        let thisMonthTransaction2 = Transaction(
            ledger: ledger,
            amount: 200,
            date: today,
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(thisMonthTransaction2)
        
        // 上月交易
        let lastMonthTransaction = Transaction(
            ledger: ledger,
            amount: 300,
            date: lastMonth,
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(lastMonthTransaction)
        
        try? modelContext.save()
        
        XCTAssertEqual(ledger.thisMonthTransactionCount, 2)
    }
    
    // MARK: - 默认账本唯一性测试
    
    func testOnlyOneDefaultLedger() {
        let ledger1 = Ledger(name: "账本1", isDefault: true)
        let ledger2 = Ledger(name: "账本2", isDefault: false)
        let ledger3 = Ledger(name: "账本3", isDefault: false)
        
        modelContext.insert(ledger1)
        modelContext.insert(ledger2)
        modelContext.insert(ledger3)
        
        try? modelContext.save()
        
        // 获取默认账本
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.isDefault == true }
        )
        let defaultLedgers = try? modelContext.fetch(descriptor)
        
        XCTAssertEqual(defaultLedgers?.count, 1)
        XCTAssertEqual(defaultLedgers?.first?.name, "账本1")
    }
    
    // MARK: - 账本归档测试
    
    func testArchiveLedger() {
        let ledger = Ledger(name: "旧账本")
        
        XCTAssertFalse(ledger.isArchived)
        
        ledger.isArchived = true
        
        XCTAssertTrue(ledger.isArchived)
    }
    
    // MARK: - 默认分类创建测试
    
    func testCreateDefaultCategories() {
        let ledger = Ledger(name: "测试账本")
        modelContext.insert(ledger)
        
        ledger.createDefaultCategories()
        
        try? modelContext.save()
        
        let categories = ledger.categories ?? []
        
        // 验证分类已创建
        XCTAssertGreaterThan(categories.count, 0)
        
        // 验证包含支出分类
        let expenseCategories = categories.filter { $0.type == .expense }
        XCTAssertGreaterThan(expenseCategories.count, 0)
        
        // 验证包含收入分类
        let incomeCategories = categories.filter { $0.type == .income }
        XCTAssertGreaterThan(incomeCategories.count, 0)
        
        // 验证有父子关系
        let parentCategories = categories.filter { $0.parent == nil }
        let childCategories = categories.filter { $0.parent != nil }
        XCTAssertGreaterThan(parentCategories.count, 0)
        XCTAssertGreaterThan(childCategories.count, 0)
    }
    
    func testDefaultCategoriesHierarchy() {
        let ledger = Ledger(name: "测试账本")
        modelContext.insert(ledger)
        
        ledger.createDefaultCategories()
        
        try? modelContext.save()
        
        let categories = ledger.categories ?? []
        
        // 查找"餐饮"分类
        let foodCategory = categories.first { $0.name == "餐饮" && $0.parent == nil }
        XCTAssertNotNil(foodCategory)
        
        // 验证有子分类
        if let foodCategory = foodCategory {
            let children = categories.filter { $0.parent?.id == foodCategory.id }
            XCTAssertGreaterThan(children.count, 0)
        }
    }
    
    // MARK: - 默认账户创建测试
    
    func testCreateDefaultAccounts() {
        let ledger = Ledger(name: "测试账本")
        modelContext.insert(ledger)
        
        ledger.createDefaultAccounts()
        
        try? modelContext.save()
        
        let accounts = ledger.accounts ?? []
        
        // 验证至少创建了一个现金账户
        XCTAssertGreaterThan(accounts.count, 0)
        
        let cashAccount = accounts.first { $0.type == .cash }
        XCTAssertNotNil(cashAccount)
        XCTAssertEqual(cashAccount?.name, "现金")
    }
    
    // MARK: - 账本排序测试
    
    func testLedgerSortOrder() {
        let ledger1 = Ledger(name: "账本1", sortOrder: 0)
        let ledger2 = Ledger(name: "账本2", sortOrder: 1)
        let ledger3 = Ledger(name: "账本3", sortOrder: 2)
        
        modelContext.insert(ledger1)
        modelContext.insert(ledger2)
        modelContext.insert(ledger3)
        
        try? modelContext.save()
        
        XCTAssertLessThan(ledger1.sortOrder, ledger2.sortOrder)
        XCTAssertLessThan(ledger2.sortOrder, ledger3.sortOrder)
    }
    
    // MARK: - 账本描述测试
    
    func testLedgerDescription() {
        let ledger = Ledger(name: "测试账本")
        ledger.ledgerDescription = "这是用于测试的账本"
        
        XCTAssertEqual(ledger.ledgerDescription, "这是用于测试的账本")
    }
    
    // MARK: - 创建时间测试
    
    func testLedgerCreatedAt() {
        let beforeCreation = Date()
        
        let ledger = Ledger(name: "新账本")
        
        let afterCreation = Date()
        
        XCTAssertTrue(ledger.createdAt >= beforeCreation)
        XCTAssertTrue(ledger.createdAt <= afterCreation)
    }
    
    // MARK: - 货币代码测试
    
    func testDefaultCurrencyCode() {
        let ledger = Ledger(name: "测试账本")
        
        XCTAssertEqual(ledger.currencyCode, "CNY")
    }
    
    func testCustomCurrencyCode() {
        let ledger = Ledger(name: "美元账本", currencyCode: "USD")
        
        XCTAssertEqual(ledger.currencyCode, "USD")
    }
}
