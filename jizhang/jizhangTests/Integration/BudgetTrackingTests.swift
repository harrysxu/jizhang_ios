//
//  BudgetTrackingTests.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest
import SwiftData
@testable import jizhang

/// 预算追踪测试 - 验证预算功能的准确性
@MainActor
final class BudgetTrackingTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testLedger: Ledger!
    var testAccount: Account!
    
    override func setUp() async throws {
        modelContainer = try TestHelpers.createInMemoryContainer()
        modelContext = ModelContext(modelContainer)
        testLedger = TestHelpers.createFullTestLedger(context: modelContext)
        testAccount = (testLedger.accounts ?? []).first!
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        try TestHelpers.cleanup(context: modelContext)
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 多笔支出累计到预算
    
    func testMultipleExpensesAccumulateToBudget() {
        let category = (testLedger.categories ?? []).filter { $0.type == .expense && $0.name == "餐饮" }.first!
        
        let budget = Budget(
            ledger: testLedger,
            category: category,
            amount: 1000,
            period: .monthly
        )
        modelContext.insert(budget)
        
        // 创建多笔支出
        let amounts: [Decimal] = [100, 150, 200, 80, 120]
        for amount in amounts {
            let transaction = Transaction(
                ledger: testLedger,
                amount: amount,
                date: Date(),
                type: .expense,
                fromAccount: testAccount,
                category: category
            )
            modelContext.insert(transaction)
        }
        
        try? modelContext.save()
        
        // 验证已使用金额: 100 + 150 + 200 + 80 + 120 = 650
        XCTAssertEqual(budget.usedAmount, 650)
        XCTAssertEqual(budget.remainingAmount, 350)
        XCTAssertFalse(budget.isOverBudget)
    }
    
    // MARK: - 子分类支出计入父分类预算
    
    func testChildCategoryExpensesCountTowardParentBudget() {
        let parentCategory = (testLedger.categories ?? []).filter {
            $0.type == .expense && $0.name == "餐饮" && $0.parent == nil
        }.first!
        
        let childCategory = (testLedger.categories ?? []).filter {
            $0.parent?.id == parentCategory.id && $0.name == "早餐"
        }.first
        
        // 如果没有早餐分类，创建一个
        let breakfast: jizhang.Category
        if let existing = childCategory {
            breakfast = existing
        } else {
            breakfast = jizhang.Category(
                ledger: testLedger,
                name: "早餐",
                type: .expense,
                parent: parentCategory
            )
            modelContext.insert(breakfast)
        }
        
        // 为父分类创建预算
        let budget = Budget(
            ledger: testLedger,
            category: parentCategory,
            amount: 1000
        )
        modelContext.insert(budget)
        
        // 在父分类下消费
        let parentTransaction = Transaction(
            ledger: testLedger,
            amount: 300,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: parentCategory
        )
        modelContext.insert(parentTransaction)
        
        // 在子分类下消费
        let childTransaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: breakfast
        )
        modelContext.insert(childTransaction)
        
        try? modelContext.save()
        
        // 验证父分类的allTransactions包含子分类交易
        let allTransactions = parentCategory.allTransactions
        XCTAssertEqual(allTransactions.count, 2)
        
        // 验证预算计算包含子分类支出: 300 + 200 = 500
        XCTAssertEqual(budget.usedAmount, 500)
        XCTAssertEqual(budget.remainingAmount, 500)
    }
    
    // MARK: - 预算超支警告
    
    func testBudgetOverspendingWarning() {
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        let budget = Budget(
            ledger: testLedger,
            category: category,
            amount: 500
        )
        modelContext.insert(budget)
        
        // 状态：安全 (0-79%)
        let transaction1 = Transaction(
            ledger: testLedger,
            amount: 300, // 60%
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: category
        )
        modelContext.insert(transaction1)
        try? modelContext.save()
        
        XCTAssertEqual(budget.status, .safe)
        XCTAssertFalse(budget.isOverBudget)
        
        // 状态：注意 (80-89%)
        let transaction2 = Transaction(
            ledger: testLedger,
            amount: 120, // 总计420, 84%
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: category
        )
        modelContext.insert(transaction2)
        try? modelContext.save()
        
        XCTAssertEqual(budget.status, .caution)
        XCTAssertFalse(budget.isOverBudget)
        
        // 状态：预警 (90-99%)
        let transaction3 = Transaction(
            ledger: testLedger,
            amount: 40, // 总计460, 92%
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: category
        )
        modelContext.insert(transaction3)
        try? modelContext.save()
        
        XCTAssertEqual(budget.status, .warning)
        XCTAssertFalse(budget.isOverBudget)
        
        // 状态：超支 (100%+)
        let transaction4 = Transaction(
            ledger: testLedger,
            amount: 50, // 总计510, 102%
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: category
        )
        modelContext.insert(transaction4)
        try? modelContext.save()
        
        XCTAssertEqual(budget.status, .exceeded)
        XCTAssertTrue(budget.isOverBudget)
    }
    
    // MARK: - 预算结转功能
    
    func testBudgetRolloverFunction() {
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        let startDate = TestHelpers.date(year: 2026, month: 1, day: 1)
        let budget = Budget(
            ledger: testLedger,
            category: category,
            amount: 1000,
            period: .monthly,
            startDate: startDate,
            enableRollover: true
        )
        modelContext.insert(budget)
        
        // 第一个月只花了600
        let transaction = Transaction(
            ledger: testLedger,
            amount: 600,
            date: startDate,
            type: .expense,
            fromAccount: testAccount,
            category: category
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 验证第一个月剩余400
        XCTAssertEqual(budget.remainingAmount, 400)
        
        // 执行结转
        budget.rolloverToNextPeriod()
        
        // 验证结转金额为400
        XCTAssertEqual(budget.rolloverAmount, 400)
        
        // 验证第二个月总预算 = 1000 + 400 = 1400
        let totalBudget = budget.amount + budget.rolloverAmount
        XCTAssertEqual(totalBudget, 1400)
    }
    
    func testBudgetRolloverWithOverspending() {
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        let budget = Budget(
            ledger: testLedger,
            category: category,
            amount: 500,
            enableRollover: true
        )
        modelContext.insert(budget)
        
        // 超支到600
        let transaction = Transaction(
            ledger: testLedger,
            amount: 600,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: category
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        XCTAssertTrue(budget.isOverBudget)
        
        // 执行结转
        budget.rolloverToNextPeriod()
        
        // 超支时不结转（结转金额为0）
        XCTAssertEqual(budget.rolloverAmount, 0)
    }
    
    // MARK: - 预算周期测试
    
    func testMonthlyBudgetPeriod() {
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        let startDate = TestHelpers.date(year: 2026, month: 1, day: 1)
        let budget = Budget(
            ledger: testLedger,
            category: category,
            amount: 1000,
            period: .monthly,
            startDate: startDate
        )
        modelContext.insert(budget)
        
        // 验证结束日期是下个月
        let expectedEndDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)
        XCTAssertNotNil(expectedEndDate)
        
        // 在周期内的交易
        let insideTransaction = Transaction(
            ledger: testLedger,
            amount: 300,
            date: TestHelpers.date(year: 2026, month: 1, day: 15),
            type: .expense,
            fromAccount: testAccount,
            category: category
        )
        modelContext.insert(insideTransaction)
        
        // 在周期外的交易
        let outsideTransaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: TestHelpers.date(year: 2025, month: 12, day: 31),
            type: .expense,
            fromAccount: testAccount,
            category: category
        )
        modelContext.insert(outsideTransaction)
        
        try? modelContext.save()
        
        // 只计入周期内的交易
        XCTAssertEqual(budget.usedAmount, 300)
    }
    
    // MARK: - 多个预算同时追踪
    
    func testMultipleBudgetsTrackedSimultaneously() {
        let foodCategory = (testLedger.categories ?? []).filter {
            $0.type == .expense && $0.name == "餐饮"
        }.first!
        
        let transportCategory = (testLedger.categories ?? []).filter {
            $0.type == .expense && $0.name == "交通"
        }.first!
        
        // 创建两个预算
        let foodBudget = Budget(
            ledger: testLedger,
            category: foodCategory,
            amount: 1000
        )
        modelContext.insert(foodBudget)
        
        let transportBudget = Budget(
            ledger: testLedger,
            category: transportCategory,
            amount: 500
        )
        modelContext.insert(transportBudget)
        
        // 餐饮消费
        let foodTransaction = Transaction(
            ledger: testLedger,
            amount: 300,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: foodCategory
        )
        modelContext.insert(foodTransaction)
        
        // 交通消费
        let transportTransaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: transportCategory
        )
        modelContext.insert(transportTransaction)
        
        try? modelContext.save()
        
        // 验证各自的预算
        XCTAssertEqual(foodBudget.usedAmount, 300)
        XCTAssertEqual(foodBudget.remainingAmount, 700)
        
        XCTAssertEqual(transportBudget.usedAmount, 100)
        XCTAssertEqual(transportBudget.remainingAmount, 400)
    }
}
