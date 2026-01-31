//
//  HomeViewModelTests.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class HomeViewModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: HomeViewModel!
    var testLedger: Ledger!
    
    override func setUp() async throws {
        modelContainer = try TestHelpers.createInMemoryContainer()
        modelContext = ModelContext(modelContainer)
        viewModel = HomeViewModel(modelContext: modelContext)
        
        testLedger = TestHelpers.createFullTestLedger(name: "测试账本", context: modelContext)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        try TestHelpers.cleanup(context: modelContext)
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 数据加载测试
    
    func testLoadDataCalculatesTotalAssets() async {
        await viewModel.loadData(for: testLedger)
        
        let expectedAssets = testLedger.totalAssets
        XCTAssertEqual(viewModel.totalAssets, expectedAssets)
    }
    
    func testLoadDataCalculatesTodayExpense() async {
        let account = (testLedger.accounts ?? []).first!
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        // 创建今天的支出
        let todayExpense1 = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(todayExpense1)
        
        let todayExpense2 = Transaction(
            ledger: testLedger,
            amount: 50,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(todayExpense2)
        
        // 创建昨天的支出（不应计入）
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayExpense = Transaction(
            ledger: testLedger,
            amount: 200,
            date: yesterday,
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(yesterdayExpense)
        
        try? modelContext.save()
        
        await viewModel.loadData(for: testLedger)
        
        XCTAssertEqual(viewModel.todayExpense, 150)
    }
    
    func testLoadDataCalculatesMonthIncome() async {
        let account = (testLedger.accounts ?? []).first!
        let category = (testLedger.categories ?? []).filter { $0.type == .income }.first!
        
        // 本月收入
        let income1 = Transaction(
            ledger: testLedger,
            amount: 5000,
            date: Date(),
            type: .income,
            toAccount: account,
            category: category
        )
        modelContext.insert(income1)
        
        let income2 = Transaction(
            ledger: testLedger,
            amount: 1000,
            date: Date(),
            type: .income,
            toAccount: account,
            category: category
        )
        modelContext.insert(income2)
        
        try? modelContext.save()
        
        await viewModel.loadData(for: testLedger)
        
        XCTAssertEqual(viewModel.monthIncome, 6000)
    }
    
    func testLoadDataCalculatesMonthExpense() async {
        let account = (testLedger.accounts ?? []).first!
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        // 本月支出
        let expense1 = Transaction(
            ledger: testLedger,
            amount: 200,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(expense1)
        
        let expense2 = Transaction(
            ledger: testLedger,
            amount: 300,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(expense2)
        
        try? modelContext.save()
        
        await viewModel.loadData(for: testLedger)
        
        XCTAssertEqual(viewModel.monthExpense, 500)
    }
    
    func testLoadDataLoadsRecentTransactions() async {
        let account = (testLedger.accounts ?? []).first!
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        // 创建多笔交易
        for i in 0..<10 {
            let transaction = Transaction(
                ledger: testLedger,
                amount: Decimal(i * 10),
                date: Date(),
                type: .expense,
                fromAccount: account,
                category: category
            )
            modelContext.insert(transaction)
        }
        
        try? modelContext.save()
        
        await viewModel.loadData(for: testLedger)
        
        XCTAssertEqual(viewModel.recentTransactions.count, 10)
        
        // 验证按日期倒序排列
        for i in 0..<(viewModel.recentTransactions.count - 1) {
            XCTAssertGreaterThanOrEqual(
                viewModel.recentTransactions[i].date,
                viewModel.recentTransactions[i + 1].date
            )
        }
    }
    
    // MARK: - 刷新数据测试
    
    func testRefreshData() async {
        await viewModel.loadData(for: testLedger)
        
        let initialExpense = viewModel.monthExpense
        
        // 添加新交易
        let account = (testLedger.accounts ?? []).first!
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        let newTransaction = Transaction(
            ledger: testLedger,
            amount: 100,
            date: Date(),
            type: .expense,
            fromAccount: account,
            category: category
        )
        modelContext.insert(newTransaction)
        try? modelContext.save()
        
        // 刷新数据
        await viewModel.refreshData()
        
        // 验证数据已更新
        XCTAssertEqual(viewModel.monthExpense, initialExpense + 100)
    }
    
    // MARK: - 创建交易测试
    
    func testCreateExpenseTransaction() async throws {
        let account = (testLedger.accounts ?? []).first!
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        await viewModel.loadData(for: testLedger)
        
        let initialBalance = account.balance
        
        let transaction = try await viewModel.createTransaction(
            type: .expense,
            amount: 100,
            fromAccount: account,
            category: category,
            note: "测试支出"
        )
        
        XCTAssertEqual(transaction.amount, 100)
        XCTAssertEqual(transaction.type, .expense)
        XCTAssertEqual(account.balance, initialBalance - 100)
    }
    
    func testCreateIncomeTransaction() async throws {
        let account = (testLedger.accounts ?? []).first!
        let category = (testLedger.categories ?? []).filter { $0.type == .income }.first!
        
        await viewModel.loadData(for: testLedger)
        
        let initialBalance = account.balance
        
        let transaction = try await viewModel.createTransaction(
            type: .income,
            amount: 500,
            toAccount: account,
            category: category
        )
        
        XCTAssertEqual(transaction.amount, 500)
        XCTAssertEqual(transaction.type, .income)
        XCTAssertEqual(account.balance, initialBalance + 500)
    }
    
    func testCreateTransactionWithoutLedgerThrowsError() async {
        let viewModelWithoutLedger = HomeViewModel(modelContext: modelContext)
        
        do {
            _ = try await viewModelWithoutLedger.createTransaction(
                type: .expense,
                amount: 100
            )
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertEqual(error as? HomeViewModelError, .noLedger)
        }
    }
    
    // MARK: - 删除交易测试
    
    func testDeleteTransaction() async throws {
        let account = (testLedger.accounts ?? []).first!
        let category = (testLedger.categories ?? []).filter { $0.type == .expense }.first!
        
        await viewModel.loadData(for: testLedger)
        
        let initialBalance = account.balance
        
        // 创建交易
        let transaction = try await viewModel.createTransaction(
            type: .expense,
            amount: 100,
            fromAccount: account,
            category: category
        )
        
        let balanceAfterCreate = account.balance
        XCTAssertEqual(balanceAfterCreate, initialBalance - 100)
        
        // 删除交易
        try await viewModel.deleteTransaction(transaction)
        
        // 验证余额恢复
        XCTAssertEqual(account.balance, initialBalance)
    }
    
    // MARK: - Loading状态测试
    
    func testLoadingStateToggle() async {
        XCTAssertFalse(viewModel.isLoading)
        
        let loadingTask = Task {
            await viewModel.loadData(for: testLedger)
        }
        
        // 等待加载完成
        await loadingTask.value
        
        XCTAssertFalse(viewModel.isLoading)
    }
}
