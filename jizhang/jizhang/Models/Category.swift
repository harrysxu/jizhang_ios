//
//  Category.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

// MARK: - CategoryType Enum

/// 分类类型
enum CategoryType: String, Codable {
    case expense = "expense"    // 支出
    case income = "income"      // 收入
    
    var displayName: String {
        switch self {
        case .expense: return "支出"
        case .income: return "收入"
        }
    }
    
    var color: String {
        switch self {
        case .expense: return "#FF3B30" // 红色
        case .income: return "#34C759"  // 绿色
        }
    }
}

// MARK: - Category Model

@Model
final class Category {
    // MARK: - Properties
    
    @Attribute(.unique) var id: UUID
    
    /// 分类名称
    var name: String
    
    /// 图标名称
    var iconName: String
    
    /// 分类类型
    var type: CategoryType
    
    /// 颜色
    var colorHex: String
    
    /// 排序顺序
    var sortOrder: Int
    
    /// 是否隐藏
    var isHidden: Bool
    
    /// 是否快速选择（在记账页面显示为快捷按钮）
    var isQuickSelect: Bool
    
    /// 创建时间
    var createdAt: Date
    
    // MARK: - Relationships
    
    /// 所属账本
    var ledger: Ledger?
    
    /// 父分类
    var parent: Category?
    
    /// 子分类
    @Relationship(deleteRule: .cascade, inverse: \Category.parent)
    var children: [Category]
    
    /// 关联的交易
    @Relationship(inverse: \Transaction.category)
    var transactions: [Transaction]
    
    /// 关联的预算
    @Relationship(deleteRule: .cascade, inverse: \Budget.category)
    var budgets: [Budget]
    
    // MARK: - Initialization
    
    init(
        ledger: Ledger,
        name: String,
        type: CategoryType,
        iconName: String = "folder.fill",
        parent: Category? = nil,
        colorHex: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.iconName = iconName
        self.parent = parent
        self.colorHex = colorHex ?? type.color
        self.sortOrder = sortOrder
        self.isHidden = false
        self.isQuickSelect = false
        self.createdAt = Date()
        self.ledger = ledger
        self.children = []
        self.transactions = []
        self.budgets = []
    }
}

// MARK: - Computed Properties

extension Category {
    /// 是否为一级分类
    var isParentCategory: Bool {
        parent == nil
    }
    
    /// 是否为二级分类
    var isChildCategory: Bool {
        parent != nil
    }
    
    /// 完整路径名(如:餐饮 > 早餐)
    var fullPath: String {
        if let parent = parent {
            return "\(parent.name) > \(name)"
        }
        return name
    }
    
    /// 所有子分类的交易(包括自己)
    var allTransactions: [Transaction] {
        var all = transactions
        for child in children {
            all.append(contentsOf: child.transactions)
        }
        return all
    }
}
