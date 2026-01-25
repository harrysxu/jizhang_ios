//
//  ReportViewModel.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - Report Type Enum

enum ReportType {
    case income
    case expense
    
    var displayName: String {
        switch self {
        case .income: return "收入"
        case .expense: return "支出"
        }
    }
}

@MainActor
class ReportViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedRange: TimeRange = .thisMonth
    @Published var customStartDate: Date = Date()
    @Published var customEndDate: Date = Date()
    @Published var isLoading = false
    @Published var reportType: ReportType = .expense
    
    // 图表数据
    @Published var dailyData: [DailyData] = []
    @Published var categoryData: [CategoryData] = []
    @Published var assetData: [AssetData] = []
    @Published var topRanking: [TopRankingItem] = []
    
    // 统计汇总
    @Published var totalIncome: Decimal = 0
    @Published var totalExpense: Decimal = 0
    @Published var netAmount: Decimal = 0
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Computed Properties
    
    var dateRange: (start: Date, end: Date) {
        if selectedRange == .custom {
            return (customStartDate, customEndDate)
        } else {
            return selectedRange.dateRange
        }
    }
    
    // MARK: - Data Loading
    
    func loadData(transactions: [Transaction], accounts: [Account]) {
        isLoading = true
        
        Task {
            let range = dateRange
            
            // 筛选时间范围内的交易
            let filteredTransactions = transactions.filter { transaction in
                transaction.date >= range.start && transaction.date <= range.end
            }
            
            // 计算汇总数据
            await calculateSummary(from: filteredTransactions)
            
            // 生成图表数据
            await Task.detached {
                await self.generateChartData(
                    transactions: filteredTransactions,
                    accounts: accounts,
                    startDate: range.start,
                    endDate: range.end
                )
            }.value
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func calculateSummary(from transactions: [Transaction]) async {
        var income: Decimal = 0
        var expense: Decimal = 0
        
        for transaction in transactions {
            if transaction.type == .income {
                income += transaction.amount
            } else if transaction.type == .expense {
                expense += transaction.amount
            }
        }
        
        await MainActor.run {
            self.totalIncome = income
            self.totalExpense = expense
            self.netAmount = income - expense
        }
    }
    
    private func generateChartData(
        transactions: [Transaction],
        accounts: [Account],
        startDate: Date,
        endDate: Date
    ) async {
        // 根据reportType过滤交易数据
        let filteredTransactions = transactions.filter { transaction in
            switch reportType {
            case .income:
                return transaction.type == .income
            case .expense:
                return transaction.type == .expense
            }
        }
        
        // 按日聚合
        let daily = ChartDataProcessor.groupByDay(
            transactions,
            startDate: startDate,
            endDate: endDate
        )
        
        // 按分类聚合(使用过滤后的数据)
        let category = ChartDataProcessor.groupByCategory(filteredTransactions, type: reportType)
        
        // 资产趋势
        let asset = ChartDataProcessor.calculateAssetHistory(
            accounts: accounts,
            transactions: transactions,
            startDate: startDate,
            endDate: endDate
        )
        
        // Top排行(使用过滤后的数据)
        let ranking = ChartDataProcessor.getTopRanking(filteredTransactions, type: reportType, limit: 5)
        
        // 数据采样(如果数据点过多)
        let sampledDaily = ChartDataProcessor.sampleData(daily, maxPoints: 100)
        let sampledAsset = ChartDataProcessor.sampleData(asset, maxPoints: 100)
        
        await MainActor.run {
            self.dailyData = sampledDaily
            self.categoryData = category
            self.assetData = sampledAsset
            self.topRanking = ranking
        }
    }
    
    // MARK: - Export
    
    func exportCSV(transactions: [Transaction]) -> String {
        return CSVExporter.export(transactions: transactions)
    }
}
