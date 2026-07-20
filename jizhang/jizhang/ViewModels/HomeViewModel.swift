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
    private let transactionService: any TransactionServicing
    private var currentLedger: Ledger?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.transactionService = TransactionService(modelContext: modelContext)
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
        
        let primaryAccount: Account?
        switch type {
        case .expense, .transfer:
            primaryAccount = fromAccount
        case .income, .adjustment:
            primaryAccount = toAccount ?? fromAccount
        }
        guard let primaryAccount else { throw HomeViewModelError.noAccount }
        let receipt = try transactionService.create(TransactionDraft(
            ledgerID: ledger.id,
            type: type,
            amount: amount,
            date: date,
            primaryAccountID: primaryAccount.id,
            destinationAccountID: type == .transfer ? toAccount?.id : nil,
            categoryID: category?.id,
            tagIDs: [],
            note: note,
            payee: nil
        ))
        
        // 刷新数据
        await refreshData()
        
        let transactionID = receipt.transactionID
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.id == transactionID }
        )
        guard let transaction = try modelContext.fetch(descriptor).first else {
            throw HomeViewModelError.transactionNotFound
        }
        return transaction
    }
    
    /// 删除交易
    func deleteTransaction(_ transaction: Transaction) async throws {
        _ = try transactionService.delete(id: transaction.id)
        
        // 刷新数据
        await refreshData()
    }
}

// MARK: - HomeViewModelError

enum HomeViewModelError: LocalizedError {
    case noLedger
    case noAccount
    case transactionNotFound
    
    var errorDescription: String? {
        switch self {
        case .noLedger:
            return "未找到账本"
        case .noAccount:
            return "未找到账户"
        case .transactionNotFound:
            return "保存后无法读取流水"
        }
    }
}
