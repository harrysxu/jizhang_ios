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
}
