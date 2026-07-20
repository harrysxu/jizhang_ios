import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class BudgetCalculatorTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var ledger: Ledger!
    private var account: Account!
    private var food: jizhang.Category!
    private var breakfast: jizhang.Category!
    private var transport: jizhang.Category!
    private var calculator: BudgetCalculator!

    override func setUpWithError() throws {
        container = try TestHelpers.createInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        ledger = TestHelpers.createTestLedger(context: context)
        account = TestHelpers.createTestAccount(ledger: ledger, context: context)
        food = jizhang.Category(ledger: ledger, name: "餐饮", type: .expense)
        breakfast = jizhang.Category(
            ledger: ledger,
            name: "早餐",
            type: .expense,
            parent: food
        )
        transport = jizhang.Category(ledger: ledger, name: "交通", type: .expense)
        context.insert(food)
        context.insert(breakfast)
        context.insert(transport)
        try context.save()
        calculator = BudgetCalculator(modelContext: context, calendar: calendar)
    }

    override func tearDown() {
        calculator = nil
        food = nil
        breakfast = nil
        transport = nil
        account = nil
        ledger = nil
        context = nil
        container = nil
    }

    func testSummarySeparatesCoveredAndUncoveredExpense() throws {
        let start = date(2026, 7, 1)
        context.insert(Budget(
            ledger: ledger,
            category: food,
            amount: 1_000,
            period: .monthly,
            startDate: start
        ))
        insertExpense(300, category: breakfast, date: date(2026, 7, 5))
        insertExpense(120, category: transport, date: date(2026, 7, 6))
        try context.save()

        let summary = try calculator.summary(ledgerID: ledger.id, at: date(2026, 7, 10))

        XCTAssertEqual(summary.totalBudget, 1_000)
        XCTAssertEqual(summary.coveredExpense, 300)
        XCTAssertEqual(summary.uncoveredExpense, 120)
        XCTAssertEqual(summary.remaining, 700)
        XCTAssertEqual(summary.activeBudgetCount, 1)
    }

    func testYearlyBudgetUsesFullAmountAndRemainingYear() throws {
        let start = date(2026, 1, 1)
        let budget = Budget(
            ledger: ledger,
            category: food,
            amount: 12_000,
            period: .yearly,
            startDate: start
        )
        context.insert(budget)
        insertExpense(2_000, category: food, date: date(2026, 3, 1))
        try context.save()

        let detail = try calculator.detail(budgetID: budget.id, at: date(2026, 7, 1))

        XCTAssertEqual(detail.amount, 12_000)
        XCTAssertEqual(detail.used, 2_000)
        XCTAssertEqual(detail.remaining, 10_000)
        XCTAssertGreaterThan(detail.safeDaily, 0)
        XCTAssertLessThan(detail.safeDaily, 100)
    }

    func testCustomBudgetHonorsExplicitCrossMonthEndDate() throws {
        let budget = Budget(
            ledger: ledger,
            category: food,
            amount: 900,
            period: .custom,
            startDate: date(2026, 6, 20),
            endDate: date(2026, 8, 10)
        )
        context.insert(budget)
        insertExpense(90, category: food, date: date(2026, 7, 15))
        try context.save()

        let detail = try calculator.detail(budgetID: budget.id, at: date(2026, 7, 20))

        XCTAssertEqual(detail.used, 90)
        XCTAssertEqual(detail.remaining, 810)
    }

    func testSummaryDoesNotLeakTransactionsAcrossLedgers() throws {
        let start = date(2026, 7, 1)
        context.insert(Budget(
            ledger: ledger,
            category: food,
            amount: 1_000,
            startDate: start
        ))
        let otherLedger = TestHelpers.createTestLedger(name: "其他", context: context)
        let otherAccount = TestHelpers.createTestAccount(ledger: otherLedger, context: context)
        let otherCategory = jizhang.Category(ledger: otherLedger, name: "餐饮", type: .expense)
        context.insert(otherCategory)
        context.insert(Transaction(
            ledger: otherLedger,
            amount: 600,
            date: date(2026, 7, 5),
            type: .expense,
            fromAccount: otherAccount,
            category: otherCategory
        ))
        try context.save()

        let summary = try calculator.summary(ledgerID: ledger.id, at: date(2026, 7, 10))

        XCTAssertEqual(summary.coveredExpense, 0)
        XCTAssertEqual(summary.uncoveredExpense, 0)
        XCTAssertEqual(summary.remaining, 1_000)
    }

    func testFreeUserCanCreateOneBudgetButNotTwo() throws {
        let viewModel = BudgetViewModel(modelContext: context)
        let start = date(2026, 7, 1)
        try viewModel.createBudget(
            ledger: ledger,
            category: food,
            amount: 1_000,
            period: .monthly,
            startDate: start,
            endDate: start,
            canCreateAdditionalBudget: false,
            enableRollover: false
        )

        XCTAssertThrowsError(try viewModel.createBudget(
            ledger: ledger,
            category: transport,
            amount: 500,
            period: .monthly,
            startDate: start,
            endDate: start,
            canCreateAdditionalBudget: false,
            enableRollover: false
        )) { error in
            guard case BudgetError.freeLimitReached = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testCustomBudgetRejectsEndBeforeStart() throws {
        let viewModel = BudgetViewModel(modelContext: context)
        let start = date(2026, 7, 10)

        XCTAssertThrowsError(try viewModel.createBudget(
            ledger: ledger,
            category: food,
            amount: 1_000,
            period: .custom,
            startDate: start,
            endDate: date(2026, 7, 9),
            canCreateAdditionalBudget: true,
            enableRollover: false
        )) { error in
            guard case BudgetError.invalidPeriod = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    private func insertExpense(_ amount: Decimal, category: jizhang.Category, date: Date) {
        context.insert(Transaction(
            ledger: ledger,
            amount: amount,
            date: date,
            type: .expense,
            fromAccount: account,
            category: category
        ))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
