//
//  HomeViewModel.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var totalAssets: Decimal = 0
    @Published var todayExpense: Decimal = 0
    @Published var monthIncome: Decimal = 0
    @Published var monthExpense: Decimal = 0
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let modelContext: ModelContext
    private var currentLedger: Ledger?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 加载数据
    func loadData(for ledger: Ledger) async {
        isLoading = true
        defer { isLoading = false }
        
        currentLedger = ledger
        
        // 计算总资产
        totalAssets = ledger.totalAssets
        
        // 计算今日支出
        let today = Date()
        let todayStart = today.startOfDay
        let todayEnd = today.endOfDay
        
        let todayTransactions = (ledger.transactions ?? []).filter {
            $0.date >= todayStart && $0.date <= todayEnd && $0.type == .expense
        }
        todayExpense = todayTransactions.reduce(0) { $0 + $1.amount }
        
        // 计算本月收支
        let monthStart = today.startOfMonth
        let monthEnd = today.endOfMonth
        
        let monthTransactions = (ledger.transactions ?? []).filter {
            $0.date >= monthStart && $0.date <= monthEnd
        }
        
        monthIncome = monthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        monthExpense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        // 获取最近交易
        recentTransactions = Array(
            (ledger.transactions ?? [])
                .sorted { $0.date > $1.date }
                .prefix(50)
        )
    }
    
    /// 刷新数据
    func refreshData() async {
        guard let ledger = currentLedger else { return }
        await loadData(for: ledger)
    }
    
    /// 创建交易
    func createTransaction(
        type: TransactionType,
        amount: Decimal,
        date: Date = Date(),
        fromAccount: Account? = nil,
        toAccount: Account? = nil,
        category: Category? = nil,
        note: String? = nil
    ) async throws -> Transaction {
        guard let ledger = currentLedger else {
            throw HomeViewModelError.noLedger
        }
        
        let transaction = Transaction(
            ledger: ledger,
            amount: amount,
            date: date,
            type: type,
            fromAccount: fromAccount,
            toAccount: toAccount,
            category: category,
            note: note
        )
        
        modelContext.insert(transaction)
        transaction.updateAccountBalance()
        
        try modelContext.save()
        
        // 刷新数据
        await refreshData()
        
        return transaction
    }
    
    /// 删除交易
    func deleteTransaction(_ transaction: Transaction) async throws {
        transaction.revertAccountBalance()
        modelContext.delete(transaction)
        try modelContext.save()
        
        // 刷新数据
        await refreshData()
    }
}

// MARK: - HomeViewModelError

enum HomeViewModelError: LocalizedError {
    case noLedger
    
    var errorDescription: String? {
        switch self {
        case .noLedger:
            return "未找到账本"
        }
    }
}
