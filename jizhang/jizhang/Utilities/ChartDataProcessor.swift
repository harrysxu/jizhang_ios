//
//  ChartDataProcessor.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation

// MARK: - Data Models

struct DailyData: Identifiable {
    let id = UUID()
    let date: Date
    let income: Decimal
    let expense: Decimal
    
    var net: Decimal {
        income - expense
    }
}

struct CategoryData: Identifiable {
    let id = UUID()
    let categoryId: UUID
    let name: String
    let amount: Decimal
    let color: String
    let percentage: Double
}

struct AssetData: Identifiable {
    let id = UUID()
    let date: Date
    let totalAsset: Decimal
}

struct TopRankingItem: Identifiable {
    let id = UUID()
    let categoryName: String
    let iconName: String
    let colorHex: String
    let amount: Decimal
    let count: Int
}

// MARK: - ChartDataProcessor

struct ChartDataProcessor {
    // MARK: - Daily Aggregation
    
    /// 按日聚合交易数据
    static func groupByDay(_ transactions: [Transaction], startDate: Date, endDate: Date) -> [DailyData] {
        let calendar = Calendar.current
        var dataDict: [Date: DailyData] = [:]
        
        // 初始化日期范围内的所有日期
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            dataDict[dayStart] = DailyData(date: dayStart, income: 0, expense: 0)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // 聚合交易数据
        for transaction in transactions {
            let dayStart = calendar.startOfDay(for: transaction.date)
            
            guard let existingData = dataDict[dayStart] else { continue }
            
            let newData: DailyData
            if transaction.type == .income {
                newData = DailyData(
                    date: dayStart,
                    income: existingData.income + transaction.amount,
                    expense: existingData.expense
                )
            } else if transaction.type == .expense {
                newData = DailyData(
                    date: dayStart,
                    income: existingData.income,
                    expense: existingData.expense + transaction.amount
                )
            } else {
                newData = existingData
            }
            
            dataDict[dayStart] = newData
        }
        
        return dataDict.values.sorted { $0.date < $1.date }
    }
    
    // MARK: - Category Aggregation
    
    /// 按分类聚合数据(支持收入和支出)
    static func groupByCategory(_ transactions: [Transaction], type: ReportType) -> [CategoryData] {
        // 根据类型过滤交易
        let filteredTransactions = transactions.filter { 
            type == .income ? $0.type == .income : $0.type == .expense
        }
        
        // 按分类聚合
        var categoryDict: [UUID: (name: String, amount: Decimal, color: String)] = [:]
        
        for transaction in filteredTransactions {
            guard let category = transaction.category else { continue }
            
            // 使用一级分类
            let parentCategory = category.parent ?? category
            let categoryId = parentCategory.id
            
            if var existing = categoryDict[categoryId] {
                existing.amount += transaction.amount
                categoryDict[categoryId] = existing
            } else {
                categoryDict[categoryId] = (
                    name: parentCategory.name,
                    amount: transaction.amount,
                    color: parentCategory.colorHex
                )
            }
        }
        
        // 计算总金额
        let totalAmount = categoryDict.values.reduce(0) { $0 + $1.amount }
        
        // 转换为CategoryData并计算百分比
        let categoryData = categoryDict.map { (id, value) in
            CategoryData(
                categoryId: id,
                name: value.name,
                amount: value.amount,
                color: value.color,
                percentage: totalAmount > 0 ? Double(truncating: (value.amount / totalAmount) as NSNumber) : 0
            )
        }
        
        return categoryData.sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Asset History
    
    /// 计算资产历史趋势
    static func calculateAssetHistory(
        accounts: [Account],
        transactions: [Transaction],
        startDate: Date,
        endDate: Date
    ) -> [AssetData] {
        let calendar = Calendar.current
        var result: [AssetData] = []
        
        // 获取所有非归档账户
        let activeAccounts = accounts.filter { !$0.isArchived }
        
        // 计算起始资产
        var currentAsset = activeAccounts.reduce(0) { $0 + $1.balance }
        
        // 从结束日期往前推算
        var currentDate = endDate
        
        while currentDate >= startDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            result.insert(AssetData(date: dayStart, totalAsset: currentAsset), at: 0)
            
            // 计算前一天的资产(减去当天的收支)
            let dayTransactions = transactions.filter { transaction in
                transaction.date >= dayStart && transaction.date < dayEnd
            }
            
            for transaction in dayTransactions {
                if transaction.type == .income {
                    currentAsset -= transaction.amount
                } else if transaction.type == .expense {
                    currentAsset += transaction.amount
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return result
    }
    
    // MARK: - Top Ranking
    
    /// 获取Top排行(支持收入和支出)
    static func getTopRanking(_ transactions: [Transaction], type: ReportType, limit: Int = 5) -> [TopRankingItem] {
        // 按二级分类统计
        var categoryDict: [UUID: (category: Category, amount: Decimal, count: Int)] = [:]
        
        let filteredTransactions = transactions.filter {
            type == .income ? $0.type == .income : $0.type == .expense
        }
        
        for transaction in filteredTransactions {
            guard let category = transaction.category else { continue }
            
            let categoryId = category.id
            
            if var existing = categoryDict[categoryId] {
                existing.amount += transaction.amount
                existing.count += 1
                categoryDict[categoryId] = existing
            } else {
                categoryDict[categoryId] = (
                    category: category,
                    amount: transaction.amount,
                    count: 1
                )
            }
        }
        
        // 转换并排序
        let ranking = categoryDict.values
            .map { value in
                TopRankingItem(
                    categoryName: value.category.name,
                    iconName: value.category.iconName,
                    colorHex: value.category.colorHex,
                    amount: value.amount,
                    count: value.count
                )
            }
            .sorted { $0.amount > $1.amount }
            .prefix(limit)
        
        return Array(ranking)
    }
    
    // MARK: - Data Sampling
    
    /// 对数据进行采样(当数据点过多时)
    static func sampleData<T>(_ data: [T], maxPoints: Int = 100) -> [T] {
        guard data.count > maxPoints else { return data }
        
        let step = Double(data.count) / Double(maxPoints)
        var sampledData: [T] = []
        
        for i in 0..<maxPoints {
            let index = Int(Double(i) * step)
            sampledData.append(data[index])
        }
        
        return sampledData
    }
    
    // MARK: - Period Comparison (对比分析)
    
    /// 计算周期对比数据
    static func calculatePeriodComparison(
        currentTransactions: [Transaction],
        previousTransactions: [Transaction],
        type: ReportType
    ) -> PeriodComparisonData {
        let currentAmount = sumAmount(transactions: currentTransactions, type: type)
        let previousAmount = sumAmount(transactions: previousTransactions, type: type)
        
        let difference = currentAmount - previousAmount
        let changeRate: Double = previousAmount > 0 
            ? Double(truncating: (difference / previousAmount) as NSNumber) * 100 
            : (currentAmount > 0 ? 100 : 0)
        
        return PeriodComparisonData(
            currentAmount: currentAmount,
            previousAmount: previousAmount,
            difference: difference,
            changeRate: changeRate
        )
    }
    
    /// 计算分类对比数据
    static func calculateCategoryComparison(
        currentTransactions: [Transaction],
        previousTransactions: [Transaction],
        type: ReportType
    ) -> [CategoryComparisonData] {
        let currentByCategory = groupAmountByCategory(transactions: currentTransactions, type: type)
        let previousByCategory = groupAmountByCategory(transactions: previousTransactions, type: type)
        
        // 合并所有分类
        var allCategoryIds = Set(currentByCategory.keys)
        allCategoryIds.formUnion(previousByCategory.keys)
        
        var result: [CategoryComparisonData] = []
        
        for categoryId in allCategoryIds {
            let current = currentByCategory[categoryId]
            let previous = previousByCategory[categoryId]
            
            let currentAmount = current?.amount ?? 0
            let previousAmount = previous?.amount ?? 0
            let difference = currentAmount - previousAmount
            
            let changeRate: Double = previousAmount > 0
                ? Double(truncating: (difference / previousAmount) as NSNumber) * 100
                : (currentAmount > 0 ? 100 : 0)
            
            result.append(CategoryComparisonData(
                categoryId: categoryId,
                categoryName: current?.name ?? previous?.name ?? "未知",
                colorHex: current?.color ?? previous?.color ?? "#BDBDBD",
                currentAmount: currentAmount,
                previousAmount: previousAmount,
                difference: difference,
                changeRate: changeRate
            ))
        }
        
        // 按当前金额排序
        return result.sorted { $0.currentAmount > $1.currentAmount }
    }
    
    /// 按账户统计收支
    /// - Parameters:
    ///   - transactions: 选定时间范围内的交易
    ///   - accounts: 所有账户
    ///   - allTransactions: 所有交易（用于计算历史余额）
    ///   - endDate: 时间范围结束日期（用于计算期末余额）
    static func calculateAccountStatistics(
        transactions: [Transaction],
        accounts: [Account],
        allTransactions: [Transaction],
        endDate: Date
    ) -> [AccountStatisticsData] {
        var result: [AccountStatisticsData] = []
        
        for account in accounts where !account.isArchived {
            // 收入：toAccount 是当前账户
            let incomeTransactions = transactions.filter {
                $0.type == .income && $0.toAccount?.id == account.id
            }
            let income = incomeTransactions.reduce(Decimal(0)) { $0 + $1.amount }
            
            // 支出：fromAccount 是当前账户
            let expenseTransactions = transactions.filter {
                $0.type == .expense && $0.fromAccount?.id == account.id
            }
            let expense = expenseTransactions.reduce(Decimal(0)) { $0 + $1.amount }
            
            // 转入该账户（作为接收方）
            let transferInTransactions = transactions.filter {
                $0.type == .transfer && $0.toAccount?.id == account.id
            }
            let transferIn = transferInTransactions.reduce(Decimal(0)) { $0 + $1.amount }
            
            // 转出该账户（作为来源方）
            let transferOutTransactions = transactions.filter {
                $0.type == .transfer && $0.fromAccount?.id == account.id
            }
            let transferOut = transferOutTransactions.reduce(Decimal(0)) { $0 + $1.amount }
            
            // 总交易数
            let transactionCount = incomeTransactions.count + expenseTransactions.count + 
                                   transferInTransactions.count + transferOutTransactions.count
            
            // 计算期末余额：当前余额减去endDate之后的所有交易影响
            let periodEndBalance = calculateHistoricalBalance(
                for: account,
                at: endDate,
                currentBalance: account.balance,
                allTransactions: allTransactions
            )
            
            result.append(AccountStatisticsData(
                accountId: account.id,
                accountName: account.name,
                accountType: account.type,
                iconName: account.iconName,
                colorHex: account.colorHex,
                balance: periodEndBalance,
                income: income,
                expense: expense,
                netFlow: income - expense + transferIn - transferOut,
                transactionCount: transactionCount
            ))
        }
        
        return result.sorted { $0.balance > $1.balance }
    }
    
    /// 计算账户在指定日期的历史余额
    private static func calculateHistoricalBalance(
        for account: Account,
        at date: Date,
        currentBalance: Decimal,
        allTransactions: [Transaction]
    ) -> Decimal {
        // 计算 endDate 后一天的起始时间，以便包含 endDate 当天的所有交易
        let calendar = Calendar.current
        let nextDayStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        
        // 找出指定日期之后的所有影响该账户的交易
        let futureTransactions = allTransactions.filter { $0.date >= nextDayStart }
        
        var historicalBalance = currentBalance
        
        for transaction in futureTransactions {
            switch transaction.type {
            case .income:
                // 如果收入记到这个账户，回推时减去
                if transaction.toAccount?.id == account.id {
                    historicalBalance -= transaction.amount
                }
            case .expense:
                // 如果从这个账户支出，回推时加回
                if transaction.fromAccount?.id == account.id {
                    historicalBalance += transaction.amount
                }
            case .transfer:
                // 转入该账户，回推时减去
                if transaction.toAccount?.id == account.id {
                    historicalBalance -= transaction.amount
                }
                // 从该账户转出，回推时加回
                if transaction.fromAccount?.id == account.id {
                    historicalBalance += transaction.amount
                }
            case .adjustment:
                // 余额调整：直接影响目标账户
                if transaction.toAccount?.id == account.id {
                    historicalBalance -= transaction.amount
                }
            }
        }
        
        return historicalBalance
    }
    
    /// 计算月度净资产趋势（用于长期趋势图）
    static func calculateMonthlyAssetTrend(
        accounts: [Account],
        transactions: [Transaction],
        months: Int = 6
    ) -> [MonthlyAssetData] {
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlyAssetData] = []
        
        // 获取当前资产总额
        let activeAccounts = accounts.filter { !$0.isArchived && !$0.excludeFromTotal }
        let currentAsset = activeAccounts.reduce(Decimal(0)) { $0 + $1.balance }
        
        // 从当前月份往前推算
        for monthOffset in 0..<months {
            let targetDate = calendar.date(byAdding: .month, value: -monthOffset, to: now)!
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: targetDate))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: monthStart)!
            
            // 当前月使用实时资产，历史月需要回推
            if monthOffset == 0 {
                result.insert(MonthlyAssetData(
                    date: monthStart,
                    totalAsset: currentAsset,
                    monthLabel: formatMonthLabel(monthStart)
                ), at: 0)
            } else {
                // 获取这个月到现在的所有交易
                let futureTransactions = transactions.filter { $0.date > monthEnd }
                
                // 回推资产：减去未来的收入，加回未来的支出
                var historicalAsset = currentAsset
                for transaction in futureTransactions {
                    if transaction.type == .income {
                        historicalAsset -= transaction.amount
                    } else if transaction.type == .expense {
                        historicalAsset += transaction.amount
                    }
                    // 转账不影响总资产
                }
                
                result.insert(MonthlyAssetData(
                    date: monthStart,
                    totalAsset: historicalAsset,
                    monthLabel: formatMonthLabel(monthStart)
                ), at: 0)
            }
        }
        
        return result
    }
    
    // MARK: - Private Helpers
    
    private static func sumAmount(transactions: [Transaction], type: ReportType) -> Decimal {
        transactions
            .filter { type == .income ? $0.type == .income : $0.type == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    private static func groupAmountByCategory(
        transactions: [Transaction],
        type: ReportType
    ) -> [UUID: (name: String, amount: Decimal, color: String)] {
        var result: [UUID: (name: String, amount: Decimal, color: String)] = [:]
        
        let filtered = transactions.filter {
            type == .income ? $0.type == .income : $0.type == .expense
        }
        
        for transaction in filtered {
            guard let category = transaction.category else { continue }
            let parentCategory = category.parent ?? category
            let categoryId = parentCategory.id
            
            if var existing = result[categoryId] {
                existing.amount += transaction.amount
                result[categoryId] = existing
            } else {
                result[categoryId] = (
                    name: parentCategory.name,
                    amount: transaction.amount,
                    color: parentCategory.colorHex
                )
            }
        }
        
        return result
    }
    
    private static func formatMonthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }
}

// MARK: - Comparison Data Models

/// 周期对比数据
struct PeriodComparisonData {
    let currentAmount: Decimal
    let previousAmount: Decimal
    let difference: Decimal
    let changeRate: Double  // 百分比变化
    
    var isIncrease: Bool { difference > 0 }
    var isDecrease: Bool { difference < 0 }
}

/// 分类对比数据
struct CategoryComparisonData: Identifiable {
    let id = UUID()
    let categoryId: UUID
    let categoryName: String
    let colorHex: String
    let currentAmount: Decimal
    let previousAmount: Decimal
    let difference: Decimal
    let changeRate: Double
    
    var isIncrease: Bool { difference > 0 }
    var isDecrease: Bool { difference < 0 }
}

/// 账户统计数据
struct AccountStatisticsData: Identifiable {
    let id = UUID()
    let accountId: UUID
    let accountName: String
    let accountType: AccountType
    let iconName: String
    let colorHex: String
    let balance: Decimal
    let income: Decimal
    let expense: Decimal
    let netFlow: Decimal
    let transactionCount: Int
}

/// 月度资产数据
struct MonthlyAssetData: Identifiable {
    let id = UUID()
    let date: Date
    let totalAsset: Decimal
    let monthLabel: String
}
