//
//  Ledger.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

@Model
final class Ledger {
    // MARK: - Properties
    
    /// 唯一标识符
    @Attribute(.unique) var id: UUID
    
    /// 账本名称
    var name: String
    
    /// 本位币代码 (ISO 4217)
    var currencyCode: String
    
    /// 创建时间
    var createdAt: Date
    
    /// 主题颜色 (Hex)
    var colorHex: String
    
    /// 图标名称 (SF Symbols)
    var iconName: String
    
    /// 是否归档
    var isArchived: Bool
    
    /// 是否为默认账本
    var isDefault: Bool
    
    /// 排序顺序
    var sortOrder: Int
    
    /// 描述信息(可选)
    var ledgerDescription: String?
    
    // MARK: - Relationships
    
    /// 关联的账户
    @Relationship(deleteRule: .cascade, inverse: \Account.ledger)
    var accounts: [Account]
    
    /// 关联的分类
    @Relationship(deleteRule: .cascade, inverse: \Category.ledger)
    var categories: [Category]
    
    /// 关联的流水
    @Relationship(deleteRule: .cascade, inverse: \Transaction.ledger)
    var transactions: [Transaction]
    
    /// 关联的预算
    @Relationship(deleteRule: .cascade, inverse: \Budget.ledger)
    var budgets: [Budget]
    
    /// 关联的标签
    @Relationship(deleteRule: .cascade, inverse: \Tag.ledger)
    var tags: [Tag]
    
    // MARK: - Initialization
    
    init(
        name: String,
        currencyCode: String = "CNY",
        colorHex: String = "#007AFF",
        iconName: String = "book.fill",
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.currencyCode = currencyCode
        self.createdAt = Date()
        self.colorHex = colorHex
        self.iconName = iconName
        self.isArchived = false
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.accounts = []
        self.categories = []
        self.transactions = []
        self.budgets = []
        self.tags = []
    }
}

// MARK: - Computed Properties

extension Ledger {
    /// 计算总资产
    var totalAssets: Decimal {
        accounts
            .filter { !$0.excludeFromTotal && !$0.isArchived }
            .reduce(0) { $0 + $1.balance }
    }
    
    /// 活跃账户数量
    var activeAccountsCount: Int {
        accounts.filter { !$0.isArchived }.count
    }
    
    /// 本月交易数量
    var thisMonthTransactionCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }.count
    }
}

// MARK: - Business Logic

extension Ledger {
    /// 创建默认分类 (使用参考UI样式)
    func createDefaultCategories() {
        // 支出分类 - 使用CategoryIconConfig
        for (index, categoryName) in CategoryIconConfig.expenseCategoryNames.enumerated() {
            let style = CategoryIconConfig.expenseStyle(for: categoryName)
            
            let category = Category(
                ledger: self,
                name: categoryName,
                type: .expense,
                iconName: style.icon,
                colorHex: style.color,
                sortOrder: index
            )
            categories.append(category)
        }
        
        // 收入分类 - 使用CategoryIconConfig
        let expenseCount = CategoryIconConfig.expenseCategoryNames.count
        for (index, categoryName) in CategoryIconConfig.incomeCategoryNames.enumerated() {
            let style = CategoryIconConfig.incomeStyle(for: categoryName)
            
            let category = Category(
                ledger: self,
                name: categoryName,
                type: .income,
                iconName: style.icon,
                colorHex: style.color,
                sortOrder: expenseCount + index
            )
            categories.append(category)
        }
    }
    
    /// 创建默认账户
    func createDefaultAccounts() {
        let cash = Account(
            ledger: self,
            name: "现金",
            type: .cash,
            iconName: "banknote.fill"
        )
        accounts.append(cash)
    }
}
