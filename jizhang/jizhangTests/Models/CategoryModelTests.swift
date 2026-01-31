//
//  CategoryModelTests.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class CategoryModelTests: XCTestCase {
    
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
    
    // MARK: - 分类类型测试
    
    func testCategoryTypes() {
        XCTAssertEqual(CategoryType.expense.displayName, "支出")
        XCTAssertEqual(CategoryType.income.displayName, "收入")
    }
    
    func testCategoryTypeColors() {
        XCTAssertEqual(CategoryType.expense.color, "#FF3B30")
        XCTAssertEqual(CategoryType.income.color, "#34C759")
    }
    
    // MARK: - 分类创建测试
    
    func testCreateExpenseCategory() {
        let category = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense,
            iconName: "fork.knife"
        )
        
        XCTAssertEqual(category.name, "餐饮")
        XCTAssertEqual(category.type, .expense)
        XCTAssertEqual(category.iconName, "fork.knife")
        XCTAssertFalse(category.isHidden)
        XCTAssertFalse(category.isQuickSelect)
    }
    
    func testCreateIncomeCategory() {
        let category = Category(
            ledger: testLedger,
            name: "工资",
            type: .income,
            iconName: "banknote.fill"
        )
        
        XCTAssertEqual(category.type, .income)
    }
    
    // MARK: - 分类层级结构测试
    
    func testParentChildHierarchy() {
        let parent = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense,
            iconName: "fork.knife"
        )
        modelContext.insert(parent)
        
        let child = Category(
            ledger: testLedger,
            name: "早餐",
            type: .expense,
            iconName: "fork.knife",
            parent: parent
        )
        modelContext.insert(child)
        
        XCTAssertNil(parent.parent)
        XCTAssertNotNil(child.parent)
        XCTAssertEqual(child.parent?.id, parent.id)
    }
    
    func testIsParentCategory() {
        let parent = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        
        XCTAssertTrue(parent.isParentCategory)
        XCTAssertFalse(parent.isChildCategory)
    }
    
    func testIsChildCategory() {
        let parent = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        modelContext.insert(parent)
        
        let child = Category(
            ledger: testLedger,
            name: "早餐",
            type: .expense,
            parent: parent
        )
        
        XCTAssertFalse(child.isParentCategory)
        XCTAssertTrue(child.isChildCategory)
    }
    
    // MARK: - 完整路径名测试
    
    func testFullPathForParentCategory() {
        let parent = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        
        XCTAssertEqual(parent.fullPath, "餐饮")
    }
    
    func testFullPathForChildCategory() {
        let parent = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        modelContext.insert(parent)
        
        let child = Category(
            ledger: testLedger,
            name: "早餐",
            type: .expense,
            parent: parent
        )
        
        XCTAssertEqual(child.fullPath, "餐饮 > 早餐")
    }
    
    // MARK: - 所有交易聚合测试
    
    func testAllTransactionsForParentCategory() {
        let parent = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        modelContext.insert(parent)
        
        let child1 = Category(
            ledger: testLedger,
            name: "早餐",
            type: .expense,
            parent: parent
        )
        modelContext.insert(child1)
        
        let child2 = Category(
            ledger: testLedger,
            name: "午餐",
            type: .expense,
            parent: parent
        )
        modelContext.insert(child2)
        
        let account = TestHelpers.createTestAccount(
            ledger: testLedger,
            balance: 1000,
            context: modelContext
        )
        
        // 父分类的交易
        let parentTransaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: parent
        )
        modelContext.insert(parentTransaction)
        
        // 子分类的交易
        let child1Transaction = Transaction(
            ledger: testLedger,
            amount: 20,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: child1
        )
        modelContext.insert(child1Transaction)
        
        let child2Transaction = Transaction(
            ledger: testLedger,
            amount: 30,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: child2
        )
        modelContext.insert(child2Transaction)
        
        try? modelContext.save()
        
        // 父分类的allTransactions应包含自己和所有子分类的交易
        let allTransactions = parent.allTransactions
        XCTAssertEqual(allTransactions.count, 3)
    }
    
    func testAllTransactionsForChildCategory() {
        let parent = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        modelContext.insert(parent)
        
        let child = Category(
            ledger: testLedger,
            name: "早餐",
            type: .expense,
            parent: parent
        )
        modelContext.insert(child)
        
        let account = TestHelpers.createTestAccount(
            ledger: testLedger,
            balance: 1000,
            context: modelContext
        )
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 20,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: child
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 子分类的allTransactions只包含自己的交易
        let allTransactions = child.allTransactions
        XCTAssertEqual(allTransactions.count, 1)
    }
    
    // MARK: - 快速选择测试
    
    func testQuickSelectFlag() {
        let category = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        
        XCTAssertFalse(category.isQuickSelect)
        
        category.isQuickSelect = true
        
        XCTAssertTrue(category.isQuickSelect)
    }
    
    // MARK: - 隐藏状态测试
    
    func testHiddenFlag() {
        let category = Category(
            ledger: testLedger,
            name: "旧分类",
            type: .expense
        )
        
        XCTAssertFalse(category.isHidden)
        
        category.isHidden = true
        
        XCTAssertTrue(category.isHidden)
    }
    
    // MARK: - 分类排序测试
    
    func testCategorySortOrder() {
        let category1 = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense,
            sortOrder: 0
        )
        
        let category2 = Category(
            ledger: testLedger,
            name: "交通",
            type: .expense,
            sortOrder: 1
        )
        
        XCTAssertLessThan(category1.sortOrder, category2.sortOrder)
    }
    
    // MARK: - 自定义颜色测试
    
    func testCustomColor() {
        let category = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense,
            colorHex: "#FF6B6B"
        )
        
        XCTAssertEqual(category.colorHex, "#FF6B6B")
    }
    
    func testDefaultColorForExpense() {
        let category = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        
        XCTAssertEqual(category.colorHex, CategoryType.expense.color)
    }
    
    func testDefaultColorForIncome() {
        let category = Category(
            ledger: testLedger,
            name: "工资",
            type: .income
        )
        
        XCTAssertEqual(category.colorHex, CategoryType.income.color)
    }
    
    // MARK: - 创建时间测试
    
    func testCategoryCreatedAt() {
        let beforeCreation = Date()
        
        let category = Category(
            ledger: testLedger,
            name: "新分类",
            type: .expense
        )
        
        let afterCreation = Date()
        
        XCTAssertTrue(category.createdAt >= beforeCreation)
        XCTAssertTrue(category.createdAt <= afterCreation)
    }
}
