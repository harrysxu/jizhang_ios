//
//  Budget.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

// MARK: - BudgetPeriod Enum

/// 预算周期
enum BudgetPeriod: String, Codable {
    case monthly = "monthly"    // 月度
    case yearly = "yearly"      // 年度
    case custom = "custom"      // 自定义
    
    var displayName: String {
        switch self {
        case .monthly: return "每月"
        case .yearly: return "每年"
        case .custom: return "自定义"
        }
    }
}

// MARK: - Budget Model

@Model
final class Budget {
    // MARK: - Properties
    
    @Attribute(.unique) var id: UUID
    
    /// 预算金额
    var amount: Decimal
    
    /// 预算周期
    var period: BudgetPeriod
    
    /// 开始日期
    var startDate: Date
    
    /// 结束日期
    var endDate: Date
    
    /// 是否启用结转
    var enableRollover: Bool
    
    /// 结转金额
    var rolloverAmount: Decimal
    
    /// 创建时间
    var createdAt: Date
    
    // MARK: - Relationships
    
    /// 所属账本
    var ledger: Ledger?
    
    /// 关联的分类
    var category: Category?
    
    // MARK: - Initialization
    
    init(
        ledger: Ledger,
        category: Category,
        amount: Decimal,
        period: BudgetPeriod = .monthly,
        startDate: Date = Date(),
        enableRollover: Bool = false
    ) {
        self.id = UUID()
        self.amount = amount
        self.period = period
        self.startDate = startDate
        self.enableRollover = enableRollover
        self.rolloverAmount = 0
        self.createdAt = Date()
        
        // 计算结束日期
        let calendar = Calendar.current
        switch period {
        case .monthly:
            self.endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .yearly:
            self.endDate = calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .custom:
            self.endDate = startDate
        }
        
        self.ledger = ledger
        self.category = category
    }
}

// MARK: - Computed Properties

extension Budget {
    /// 当前周期已使用金额
    var usedAmount: Decimal {
        guard let category = category else { return 0 }
        
        let transactions = category.allTransactions
        
        return transactions
            .filter { $0.type == .expense }
            .filter { transaction in
                transaction.date >= startDate && transaction.date < endDate
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// 剩余金额
    var remainingAmount: Decimal {
        let total = amount + rolloverAmount
        return total - usedAmount
    }
    
    /// 使用进度(0-1)
    var progress: Double {
        let total = amount + rolloverAmount
        guard total > 0 else { return 0 }
        return Double(truncating: usedAmount / total as NSNumber)
    }
    
    /// 是否超支
    var isOverBudget: Bool {
        remainingAmount < 0
    }
    
    /// 预算状态
    var status: BudgetStatus {
        let progress = self.progress
        if progress >= 1.0 {
            return .exceeded
        } else if progress >= 0.9 {
            return .warning
        } else if progress >= 0.8 {
            return .caution
        } else {
            return .safe
        }
    }
    
    /// 日均可用金额
    var dailyAverage: Decimal {
        let calendar = Calendar.current
        let today = Date()
        
        guard today < endDate else { return 0 }
        
        let remainingDays = calendar.dateComponents([.day], from: today, to: endDate).day ?? 1
        guard remainingDays > 0 else { return 0 }
        
        return remainingAmount / Decimal(remainingDays)
    }
}

// MARK: - BudgetStatus Enum

enum BudgetStatus {
    case safe       // 安全(0-79%)
    case caution    // 注意(80-89%)
    case warning    // 预警(90-99%)
    case exceeded   // 超支(100%+)
    
    var color: String {
        switch self {
        case .safe: return "#34C759"      // 绿色
        case .caution: return "#FF9500"   // 橙色
        case .warning: return "#FF9500"   // 橙色
        case .exceeded: return "#FF3B30"  // 红色
        }
    }
    
    var displayName: String {
        switch self {
        case .safe: return "安全"
        case .caution: return "注意"
        case .warning: return "预警"
        case .exceeded: return "超支"
        }
    }
}

// MARK: - Business Logic

extension Budget {
    /// 结转到下一周期
    func rolloverToNextPeriod() {
        guard enableRollover else { return }
        
        let remaining = remainingAmount
        if remaining > 0 {
            rolloverAmount = remaining
        } else {
            rolloverAmount = 0
        }
        
        // 更新周期
        let calendar = Calendar.current
        switch period {
        case .monthly:
            startDate = endDate
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .yearly:
            startDate = endDate
            endDate = calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .custom:
            break
        }
    }
}
