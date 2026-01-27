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
    
    // 对比分析数据
    @Published var monthOverMonthExpense: PeriodComparisonData?
    @Published var monthOverMonthIncome: PeriodComparisonData?
    @Published var yearOverYearExpense: PeriodComparisonData?
    @Published var yearOverYearIncome: PeriodComparisonData?
    @Published var monthCategoryComparisons: [CategoryComparisonData] = []  // 月度分类对比
    @Published var yearCategoryComparisons: [CategoryComparisonData] = []   // 年度分类对比
    
    // 净资产趋势数据
    @Published var monthlyAssetTrend: [MonthlyAssetData] = []
    @Published var assetTrendRange: NetAssetTrendView.TrendRange = .sixMonths
    
    // 账户统计数据
    @Published var accountStatistics: [AccountStatisticsData] = []
    
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
            
            // 生成对比分析数据
            await generateComparisonData(
                allTransactions: transactions,
                currentRange: range
            )
            
            // 生成净资产趋势数据
            await generateAssetTrendData(
                accounts: accounts,
                transactions: transactions
            )
            
            // 生成账户统计数据
            await generateAccountStatistics(
                transactions: filteredTransactions,
                accounts: accounts,
                allTransactions: transactions,
                endDate: range.end
            )
            
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
    
    // MARK: - Comparison Data Generation
    
    private func generateComparisonData(
        allTransactions: [Transaction],
        currentRange: (start: Date, end: Date)
    ) async {
        let calendar = Calendar.current
        
        // 计算上月日期范围
        let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentRange.start)!
        let previousMonthEnd = calendar.date(byAdding: .month, value: -1, to: currentRange.end)!
        
        // 计算去年同期日期范围
        let lastYearStart = calendar.date(byAdding: .year, value: -1, to: currentRange.start)!
        let lastYearEnd = calendar.date(byAdding: .year, value: -1, to: currentRange.end)!
        
        // 筛选各周期的交易
        let currentTransactions = allTransactions.filter {
            $0.date >= currentRange.start && $0.date <= currentRange.end
        }
        
        let previousMonthTransactions = allTransactions.filter {
            $0.date >= previousMonthStart && $0.date <= previousMonthEnd
        }
        
        let lastYearTransactions = allTransactions.filter {
            $0.date >= lastYearStart && $0.date <= lastYearEnd
        }
        
        // 计算月度环比
        let momExpense = ChartDataProcessor.calculatePeriodComparison(
            currentTransactions: currentTransactions,
            previousTransactions: previousMonthTransactions,
            type: .expense
        )
        
        let momIncome = ChartDataProcessor.calculatePeriodComparison(
            currentTransactions: currentTransactions,
            previousTransactions: previousMonthTransactions,
            type: .income
        )
        
        // 计算年度同比
        let yoyExpense = ChartDataProcessor.calculatePeriodComparison(
            currentTransactions: currentTransactions,
            previousTransactions: lastYearTransactions,
            type: .expense
        )
        
        let yoyIncome = ChartDataProcessor.calculatePeriodComparison(
            currentTransactions: currentTransactions,
            previousTransactions: lastYearTransactions,
            type: .income
        )
        
        // 计算月度分类对比
        let monthCategoryComp = ChartDataProcessor.calculateCategoryComparison(
            currentTransactions: currentTransactions,
            previousTransactions: previousMonthTransactions,
            type: reportType
        )
        
        // 计算年度分类对比
        let yearCategoryComp = ChartDataProcessor.calculateCategoryComparison(
            currentTransactions: currentTransactions,
            previousTransactions: lastYearTransactions,
            type: reportType
        )
        
        await MainActor.run {
            self.monthOverMonthExpense = momExpense
            self.monthOverMonthIncome = momIncome
            self.yearOverYearExpense = yoyExpense
            self.yearOverYearIncome = yoyIncome
            self.monthCategoryComparisons = monthCategoryComp
            self.yearCategoryComparisons = yearCategoryComp
        }
    }
    
    // MARK: - Asset Trend Data Generation
    
    private func generateAssetTrendData(
        accounts: [Account],
        transactions: [Transaction]
    ) async {
        let trendData = ChartDataProcessor.calculateMonthlyAssetTrend(
            accounts: accounts,
            transactions: transactions,
            months: assetTrendRange.months
        )
        
        await MainActor.run {
            self.monthlyAssetTrend = trendData
        }
    }
    
    /// 更新资产趋势范围
    func updateAssetTrendRange(_ range: NetAssetTrendView.TrendRange, accounts: [Account], transactions: [Transaction]) {
        assetTrendRange = range
        Task {
            await generateAssetTrendData(accounts: accounts, transactions: transactions)
        }
    }
    
    // MARK: - Account Statistics Generation
    
    private func generateAccountStatistics(
        transactions: [Transaction],
        accounts: [Account],
        allTransactions: [Transaction],
        endDate: Date
    ) async {
        let statistics = ChartDataProcessor.calculateAccountStatistics(
            transactions: transactions,
            accounts: accounts,
            allTransactions: allTransactions,
            endDate: endDate
        )
        
        await MainActor.run {
            self.accountStatistics = statistics
        }
    }
    
    // MARK: - Export
    
    func exportCSV(transactions: [Transaction]) -> String {
        return CSVExporter.export(transactions: transactions)
    }
}
