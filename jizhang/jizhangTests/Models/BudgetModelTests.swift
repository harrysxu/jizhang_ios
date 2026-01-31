//
//  BudgetModelTests.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class BudgetModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testLedger: Ledger!
    var testCategory: jizhang.Category!
    var testAccount: Account!
    
    override func setUp() async throws {
        modelContainer = try TestHelpers.createInMemoryContainer()
        modelContext = ModelContext(modelContainer)
        
        testLedger = TestHelpers.createTestLedger(context: modelContext)
        
        testCategory = Category(
            ledger: testLedger,
            name: "餐饮",
            type: .expense
        )
        modelContext.insert(testCategory)
        
        testAccount = TestHelpers.createTestAccount(
            ledger: testLedger,
            balance: 10000,
            context: modelContext
        )
        
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        try TestHelpers.cleanup(context: modelContext)
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 预算周期测试
    
    func testBudgetPeriodTypes() {
        XCTAssertEqual(BudgetPeriod.monthly.displayName, "每月")
        XCTAssertEqual(BudgetPeriod.yearly.displayName, "每年")
        XCTAssertEqual(BudgetPeriod.custom.displayName, "自定义")
    }
    
    // MARK: - 预算创建测试
    
    func testCreateMonthlyBudget() {
        let startDate = Date()
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500,
            period: .monthly,
            startDate: startDate
        )
        
        XCTAssertEqual(budget.amount, 500)
        XCTAssertEqual(budget.period, .monthly)
        XCTAssertEqual(budget.startDate, startDate)
        XCTAssertFalse(budget.enableRollover)
        XCTAssertEqual(budget.rolloverAmount, 0)
        
        // 验证结束日期是下个月
        let calendar = Calendar.current
        let expectedEndDate = calendar.date(byAdding: .month, value: 1, to: startDate)
        XCTAssertNotNil(expectedEndDate)
    }
    
    func testCreateYearlyBudget() {
        let startDate = Date()
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 6000,
            period: .yearly,
            startDate: startDate
        )
        
        XCTAssertEqual(budget.period, .yearly)
        
        // 验证结束日期是明年
        let calendar = Calendar.current
        let expectedEndDate = calendar.date(byAdding: .year, value: 1, to: startDate)
        XCTAssertNotNil(expectedEndDate)
    }
    
    func testCreateBudgetWithRollover() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500,
            enableRollover: true
        )
        
        XCTAssertTrue(budget.enableRollover)
    }
    
    // MARK: - 已使用金额测试
    
    func testUsedAmountCalculation() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        // 创建支出交易
        for i in 0..<3 {
            let transaction = Transaction(
                ledger: testLedger,
                amount: Decimal(50 + i * 10),
                date: Date(),
                type: .expense,
                fromAccount: testAccount,
                category: testCategory
            )
            modelContext.insert(transaction)
        }
        
        try? modelContext.save()
        
        // 已使用金额 = 50 + 60 + 70 = 180
        XCTAssertEqual(budget.usedAmount, 180)
    }
    
    func testUsedAmountOnlyCountsExpenses() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        // 支出交易
        let expense = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(expense)
        
        // 收入交易（不应该计入预算使用）
        let income = Transaction(
            ledger: testLedger,
            amount: 50,
            date: Date(),
            type: .income,
            toAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(income)
        
        try? modelContext.save()
        
        // 只计入支出
        XCTAssertEqual(budget.usedAmount, 100)
    }
    
    func testUsedAmountOnlyCountsTransactionsInPeriod() {
        let startDate = TestHelpers.date(year: 2026, month: 1, day: 1)
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500,
            period: .monthly,
            startDate: startDate
        )
        modelContext.insert(budget)
        
        // 周期内的交易
        let insideTransaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: TestHelpers.date(year: 2026, month: 1, day: 15),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(insideTransaction)
        
        // 周期外的交易
        let outsideTransaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: TestHelpers.date(year: 2025, month: 12, day: 31),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(outsideTransaction)
        
        try? modelContext.save()
        
        // 只计入周期内的交易
        XCTAssertEqual(budget.usedAmount, 100)
    }
    
    // MARK: - 剩余金额测试
    
    func testRemainingAmountCalculation() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 剩余 = 500 - 200 = 300
        XCTAssertEqual(budget.remainingAmount, 300)
    }
    
    func testRemainingAmountWithRollover() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500,
            enableRollover: true
        )
        budget.rolloverAmount = 100
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 剩余 = (500 + 100) - 200 = 400
        XCTAssertEqual(budget.remainingAmount, 400)
    }
    
    // MARK: - 使用进度测试
    
    func testProgressCalculation() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 250,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 进度 = 250 / 500 = 0.5
        XCTAssertEqual(budget.progress, 0.5, accuracy: 0.01)
    }
    
    func testProgressOver100Percent() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 600,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 进度 = 600 / 500 = 1.2 (120%)
        XCTAssertGreaterThan(budget.progress, 1.0)
    }
    
    // MARK: - 超支判断测试
    
    func testIsOverBudget() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        XCTAssertFalse(budget.isOverBudget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 600,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        XCTAssertTrue(budget.isOverBudget)
    }
    
    // MARK: - 预算状态测试
    
    func testBudgetStatusSafe() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 300, // 60%
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        XCTAssertEqual(budget.status, .safe)
    }
    
    func testBudgetStatusCaution() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 420, // 84%
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        XCTAssertEqual(budget.status, .caution)
    }
    
    func testBudgetStatusWarning() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 460, // 92%
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        XCTAssertEqual(budget.status, .warning)
    }
    
    func testBudgetStatusExceeded() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500
        )
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 600, // 120%
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        XCTAssertEqual(budget.status, .exceeded)
    }
    
    // MARK: - 日均可用金额测试
    
    func testDailyAverage() {
        let today = Date()
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500,
            period: .monthly,
            startDate: today
        )
        modelContext.insert(budget)
        
        let transaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: today,
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 日均可用金额 = 剩余金额 / 剩余天数
        let dailyAverage = budget.dailyAverage
        XCTAssertGreaterThan(dailyAverage, 0)
    }
    
    // MARK: - 预算结转测试
    
    func testRolloverToNextPeriod() {
        let startDate = TestHelpers.date(year: 2026, month: 1, day: 1)
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500,
            period: .monthly,
            startDate: startDate,
            enableRollover: true
        )
        modelContext.insert(budget)
        
        // 只花了200，剩余300
        let transaction = Transaction(
            ledger: testLedger,
            amount: 200,
            date: startDate,
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        // 执行结转
        budget.rolloverToNextPeriod()
        
        // 验证结转金额
        XCTAssertEqual(budget.rolloverAmount, 300)
        
        // 验证日期更新
        let expectedNewStart = Calendar.current.date(byAdding: .month, value: 1, to: startDate)
        XCTAssertNotNil(expectedNewStart)
    }
    
    func testRolloverNotEnabledDoesNothing() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500,
            enableRollover: false
        )
        
        budget.rolloverToNextPeriod()
        
        // 没有启用结转，结转金额应该为0
        XCTAssertEqual(budget.rolloverAmount, 0)
    }
    
    func testRolloverWithOverspending() {
        let budget = Budget(
            ledger: testLedger,
            category: testCategory,
            amount: 500,
            enableRollover: true
        )
        modelContext.insert(budget)
        
        // 超支
        let transaction = Transaction(
            ledger: testLedger,
            amount: 600,
            date: Date(),
            type: .expense,
            fromAccount: testAccount,
            category: testCategory
        )
        modelContext.insert(transaction)
        
        try? modelContext.save()
        
        budget.rolloverToNextPeriod()
        
        // 超支时结转金额为0
        XCTAssertEqual(budget.rolloverAmount, 0)
    }
}
