//
//  Tag.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

@Model
final class Tag {
    // MARK: - Properties
    
    @Attribute(.unique) var id: UUID
    
    /// 标签名称
    var name: String
    
    /// 颜色
    var colorHex: String
    
    /// 排序顺序
    var sortOrder: Int
    
    /// 创建时间
    var createdAt: Date
    
    // MARK: - Relationships
    
    /// 所属账本
    var ledger: Ledger?
    
    /// 关联的交易
    var transactions: [Transaction]
    
    // MARK: - Initialization
    
    init(
        ledger: Ledger,
        name: String,
        colorHex: String = "#007AFF",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.ledger = ledger
        self.transactions = []
    }
}

// MARK: - Computed Properties

extension Tag {
    /// 标签使用次数
    var usageCount: Int {
        transactions.count
    }
    
    /// 本月使用次数
    var thisMonthUsageCount: Int {
        let calendar = Calendar.current
        let now = Date()
        
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }.count
    }
    
    /// 标签总金额(支出为负, 收入为正)
    var totalAmount: Decimal {
        transactions.reduce(0) { total, transaction in
            switch transaction.type {
            case .expense:
                return total - transaction.amount
            case .income:
                return total + transaction.amount
            case .transfer, .adjustment:
                return total
            }
        }
    }
}
