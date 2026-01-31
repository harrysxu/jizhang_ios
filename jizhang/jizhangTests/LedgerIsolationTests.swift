//
//  LedgerIsolationTests.swift
//  jizhang Tests
//
//  Created by Cursor on 2026/1/25.
//

import XCTest
import SwiftData
@testable import jizhang

/// 账本隔离功能测试
@MainActor
final class LedgerIsolationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        // 创建内存数据库用于测试
        let schema = Schema([
            Ledger.self,
            Account.self,
            Category.self,
            Transaction.self,
            Budget.self,
            Tag.self
        ])
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 基础隔离测试
    
    /// 测试1: 账本数据完全隔离
    func testLedgerDataIsolation() throws {
        // 创建两个账本
        let ledger1 = Ledger(name: "个人账本", currencyCode: "CNY")
        let ledger2 = Ledger(name: "公司账本", currencyCode: "USD")
        
        modelContext.insert(ledger1)
        modelContext.insert(ledger2)
        
        // 为账本1创建账户和分类
        let account1 = Account(ledger: ledger1, name: "个人银行卡", type: .checking)
        let category1 = Category(ledger: ledger1, name: "餐饮", type: .expense)
        
        modelContext.insert(account1)
        modelContext.insert(category1)
        
        // 为账本2创建账户和分类
        let account2 = Account(ledger: ledger2, name: "公司账户", type: .checking)
        let category2 = Category(ledger: ledger2, name: "差旅", type: .expense)
        
        modelContext.insert(account2)
        modelContext.insert(category2)
        
        try modelContext.save()
        
        // 验证: 账本1只能看到自己的账户
        XCTAssertEqual(ledger1.accounts?.count, 1)
        XCTAssertEqual(ledger1.accounts?.first?.name, "个人银行卡")
        
        // 验证: 账本2只能看到自己的账户
        XCTAssertEqual(ledger2.accounts?.count, 1)
        XCTAssertEqual(ledger2.accounts?.first?.name, "公司账户")
        
        // 验证: 账本1只能看到自己的分类
        XCTAssertEqual(ledger1.categories?.count, 1)
        XCTAssertEqual(ledger1.categories?.first?.name, "餐饮")
        
        // 验证: 账本2只能看到自己的分类
        XCTAssertEqual(ledger2.categories?.count, 1)
        XCTAssertEqual(ledger2.categories?.first?.name, "差旅")
    }
    
    /// 测试2: 交易数据隔离
    func testTransactionIsolation() throws {
        // 创建两个账本
        let ledger1 = Ledger(name: "账本1")
        let ledger2 = Ledger(name: "账本2")
        
        modelContext.insert(ledger1)
        modelContext.insert(ledger2)
        
        // 创建账户
        let account1 = Account(ledger: ledger1, name: "账户1", type: .cash)
        let account2 = Account(ledger: ledger2, name: "账户2", type: .cash)
        
        modelContext.insert(account1)
        modelContext.insert(account2)
        
        // 创建分类
        let category1 = Category(ledger: ledger1, name: "分类1", type: .expense)
        let category2 = Category(ledger: ledger2, name: "分类2", type: .expense)
        
        modelContext.insert(category1)
        modelContext.insert(category2)
        
        // 在账本1创建交易
        let transaction1 = Transaction(
            ledger: ledger1,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: account1,
            category: category1
        )
        modelContext.insert(transaction1)
        
        // 在账本2创建交易
        let transaction2 = Transaction(
            ledger: ledger2,
            amount: 200,
            date: Date(),
            type: .expense,
            fromAccount: account2,
            category: category2
        )
        modelContext.insert(transaction2)
        
        try modelContext.save()
        
        // 验证: 账本1只能看到自己的交易
        XCTAssertEqual(ledger1.transactions?.count, 1)
        XCTAssertEqual(ledger1.transactions?.first?.amount, 100)
        
        // 验证: 账本2只能看到自己的交易
        XCTAssertEqual(ledger2.transactions?.count, 1)
        XCTAssertEqual(ledger2.transactions?.first?.amount, 200)
    }
    
    /// 测试3: 预算数据隔离
    func testBudgetIsolation() throws {
        // 创建两个账本
        let ledger1 = Ledger(name: "账本1")
        let ledger2 = Ledger(name: "账本2")
        
        modelContext.insert(ledger1)
        modelContext.insert(ledger2)
        
        // 创建分类
        let category1 = Category(ledger: ledger1, name: "餐饮", type: .expense)
        let category2 = Category(ledger: ledger2, name: "餐饮", type: .expense)
        
        modelContext.insert(category1)
        modelContext.insert(category2)
        
        // 为账本1创建预算
        let budget1 = Budget(ledger: ledger1, category: category1, amount: 500)
        modelContext.insert(budget1)
        
        // 为账本2创建预算
        let budget2 = Budget(ledger: ledger2, category: category2, amount: 800)
        modelContext.insert(budget2)
        
        try modelContext.save()
        
        // 验证: 账本1只能看到自己的预算
        XCTAssertEqual(ledger1.budgets?.count, 1)
        XCTAssertEqual(ledger1.budgets?.first?.amount, 500)
        
        // 验证: 账本2只能看到自己的预算
        XCTAssertEqual(ledger2.budgets?.count, 1)
        XCTAssertEqual(ledger2.budgets?.first?.amount, 800)
    }
    
    // MARK: - 级联删除测试
    
    /// 测试4: 删除账本级联删除所有关联数据
    func testLedgerCascadeDelete() throws {
        // 创建账本
        let ledger = Ledger(name: "测试账本")
        modelContext.insert(ledger)
        
        // 创建关联数据
        let account = Account(ledger: ledger, name: "账户", type: .cash)
        let category = Category(ledger: ledger, name: "分类", type: .expense)
        let transaction = Transaction(
            ledger: ledger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: category
        )
        let budget = Budget(ledger: ledger, category: category, amount: 500)
        let tag = Tag(ledger: ledger, name: "标签")
        
        modelContext.insert(account)
        modelContext.insert(category)
        modelContext.insert(transaction)
        modelContext.insert(budget)
        modelContext.insert(tag)
        
        try modelContext.save()
        
        // 获取数据数量
        let accountCountBefore = try modelContext.fetchCount(FetchDescriptor<Account>())
        let categoryCountBefore = try modelContext.fetchCount(FetchDescriptor<jizhang.Category>())
        let transactionCountBefore = try modelContext.fetchCount(FetchDescriptor<Transaction>())
        let budgetCountBefore = try modelContext.fetchCount(FetchDescriptor<Budget>())
        let tagCountBefore = try modelContext.fetchCount(FetchDescriptor<Tag>())
        
        XCTAssertEqual(accountCountBefore, 1)
        XCTAssertEqual(categoryCountBefore, 1)
        XCTAssertEqual(transactionCountBefore, 1)
        XCTAssertEqual(budgetCountBefore, 1)
        XCTAssertEqual(tagCountBefore, 1)
        
        // 删除账本
        modelContext.delete(ledger)
        try modelContext.save()
        
        // 验证: 所有关联数据都被删除
        let accountCountAfter = try modelContext.fetchCount(FetchDescriptor<Account>())
        let categoryCountAfter = try modelContext.fetchCount(FetchDescriptor<jizhang.Category>())
        let transactionCountAfter = try modelContext.fetchCount(FetchDescriptor<Transaction>())
        let budgetCountAfter = try modelContext.fetchCount(FetchDescriptor<Budget>())
        let tagCountAfter = try modelContext.fetchCount(FetchDescriptor<Tag>())
        
        XCTAssertEqual(accountCountAfter, 0)
        XCTAssertEqual(categoryCountAfter, 0)
        XCTAssertEqual(transactionCountAfter, 0)
        XCTAssertEqual(budgetCountAfter, 0)
        XCTAssertEqual(tagCountAfter, 0)
    }
    
    // MARK: - 账本切换测试
    
    /// 测试5: 账本切换不影响数据
    func testLedgerSwitch() throws {
        // 创建两个账本,各有数据
        let ledger1 = Ledger(name: "账本1")
        let ledger2 = Ledger(name: "账本2")
        
        modelContext.insert(ledger1)
        modelContext.insert(ledger2)
        
        // 账本1的数据
        let account1 = Account(ledger: ledger1, name: "账户1", type: .cash, balance: 1000)
        modelContext.insert(account1)
        
        // 账本2的数据
        let account2 = Account(ledger: ledger2, name: "账户2", type: .cash, balance: 2000)
        modelContext.insert(account2)
        
        try modelContext.save()
        
        // 模拟切换到账本1
        let ledger1Accounts = ledger1.accounts
        XCTAssertEqual(ledger1Accounts?.count, 1)
        XCTAssertEqual(ledger1Accounts?.first?.balance, 1000)
        
        // 模拟切换到账本2
        let ledger2Accounts = ledger2.accounts
        XCTAssertEqual(ledger2Accounts?.count, 1)
        XCTAssertEqual(ledger2Accounts?.first?.balance, 2000)
        
        // 再次切换回账本1,数据应该保持不变
        let ledger1AccountsAgain = ledger1.accounts
        XCTAssertEqual(ledger1AccountsAgain?.count, 1)
        XCTAssertEqual(ledger1AccountsAgain?.first?.balance, 1000)
    }
    
    // MARK: - 默认账本测试
    
    /// 测试6: 只能有一个默认账本
    func testSingleDefaultLedger() throws {
        // 创建多个账本
        let ledger1 = Ledger(name: "账本1", isDefault: true)
        let ledger2 = Ledger(name: "账本2", isDefault: false)
        let ledger3 = Ledger(name: "账本3", isDefault: false)
        
        modelContext.insert(ledger1)
        modelContext.insert(ledger2)
        modelContext.insert(ledger3)
        
        try modelContext.save()
        
        // 验证只有一个默认账本
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.isDefault == true }
        )
        let defaultLedgers = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(defaultLedgers.count, 1)
        XCTAssertEqual(defaultLedgers.first?.name, "账本1")
        
        // 设置另一个账本为默认
        ledger2.isDefault = true
        ledger1.isDefault = false
        
        try modelContext.save()
        
        // 验证仍然只有一个默认账本
        let defaultLedgersAfter = try modelContext.fetch(descriptor)
        XCTAssertEqual(defaultLedgersAfter.count, 1)
        XCTAssertEqual(defaultLedgersAfter.first?.name, "账本2")
    }
    
    // MARK: - 账本复制测试
    
    /// 测试7: 账本设置复制功能
    func testCopyLedgerSettings() throws {
        // 创建源账本
        let sourceLedger = Ledger(name: "源账本")
        modelContext.insert(sourceLedger)
        
        // 为源账本创建账户
        let account1 = Account(ledger: sourceLedger, name: "银行卡", type: .checking, balance: 5000)
        let account2 = Account(ledger: sourceLedger, name: "现金", type: .cash, balance: 500)
        
        modelContext.insert(account1)
        modelContext.insert(account2)
        
        // 为源账本创建分类
        let parentCategory = Category(ledger: sourceLedger, name: "餐饮", type: .expense)
        modelContext.insert(parentCategory)
        
        let childCategory = Category(ledger: sourceLedger, name: "早餐", type: .expense, parent: parentCategory)
        modelContext.insert(childCategory)
        
        try modelContext.save()
        
        // 创建目标账本
        let targetLedger = Ledger(name: "目标账本")
        modelContext.insert(targetLedger)
        try modelContext.save()
        
        // 执行复制
        let viewModel = LedgerViewModel(modelContext: modelContext)
        try viewModel.copyLedgerSettings(from: sourceLedger, to: targetLedger)
        
        // 验证: 账户结构被复制
        XCTAssertEqual(targetLedger.accounts?.count, 2)
        XCTAssertTrue(targetLedger.accounts?.contains(where: { $0.name == "银行卡" }) ?? false)
        XCTAssertTrue(targetLedger.accounts?.contains(where: { $0.name == "现金" }) ?? false)
        
        // 验证: 新账户余额为0
        let copiedAccount = targetLedger.accounts?.first(where: { $0.name == "银行卡" })
        XCTAssertEqual(copiedAccount?.balance, 0)
        
        // 验证: 分类结构被复制
        XCTAssertEqual(targetLedger.categories?.count, 2)
        XCTAssertTrue(targetLedger.categories?.contains(where: { $0.name == "餐饮" }) ?? false)
        XCTAssertTrue(targetLedger.categories?.contains(where: { $0.name == "早餐" }) ?? false)
    }
}
