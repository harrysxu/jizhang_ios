//
//  WidgetData.swift
//  jizhangWidget
//
//  Created by Cursor on 2026/1/24.
//

import Foundation

/// Widget数据模型 (简化版本，用于跨进程传输)
struct WidgetData: Codable {
    /// 今日总支出
    let todayExpense: Decimal
    
    /// 今日总收入
    let todayIncome: Decimal
    
    /// 本月总支出
    let monthExpense: Decimal
    
    /// 本月总收入
    let monthIncome: Decimal
    
    /// 今日预算
    let todayBudget: Decimal
    
    /// 本月预算
    let monthBudget: Decimal
    
    /// 预算使用百分比 (0.0-1.0+)
    let budgetUsagePercentage: Double
    
    /// 最近交易列表
    let recentTransactions: [WidgetTransaction]
    
    /// 最后更新时间
    let lastUpdateTime: Date
    
    /// 当前账本名称
    let ledgerName: String
    
    /// 初始化空数据
    static func empty() -> WidgetData {
        WidgetData(
            todayExpense: 0,
            todayIncome: 0,
            monthExpense: 0,
            monthIncome: 0,
            todayBudget: 0,
            monthBudget: 0,
            budgetUsagePercentage: 0,
            recentTransactions: [],
            lastUpdateTime: Date(),
            ledgerName: "默认账本"
        )
    }
}

/// 简化的交易模型 (用于Widget显示)
struct WidgetTransaction: Codable, Identifiable, Hashable {
    let id: UUID
    let amount: Decimal
    let categoryName: String
    let categoryIcon: String
    let date: Date
    let type: String  // "expense" or "income" or "transfer"
    let note: String?
    
    /// 显示金额 (带符号)
    var displayAmount: String {
        let prefix = type == "expense" ? "-" : "+"
        return "\(prefix)¥\(amount)"
    }
}
