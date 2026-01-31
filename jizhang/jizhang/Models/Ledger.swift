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
    
    /// 唯一标识符 (CloudKit不支持unique约束，但UUID本身保证唯一性)
    var id: UUID = UUID()
    
    /// 账本名称
    var name: String = ""
    
    /// 本位币代码 (ISO 4217)
    var currencyCode: String = "CNY"
    
    /// 创建时间
    var createdAt: Date = Date()
    
    /// 主题颜色 (Hex)
    var colorHex: String = "#007AFF"
    
    /// 图标名称 (SF Symbols)
    var iconName: String = "book.fill"
    
    /// 是否归档
    var isArchived: Bool = false
    
    /// 是否为默认账本
    var isDefault: Bool = false
    
    /// 排序顺序
    var sortOrder: Int = 0
    
    /// 描述信息(可选)
    var ledgerDescription: String?
    
    // MARK: - Relationships
    
    /// 关联的账户 (CloudKit要求关系必须为可选)
    @Relationship(deleteRule: .cascade, inverse: \Account.ledger)
    var accounts: [Account]?
    
    /// 关联的分类 (CloudKit要求关系必须为可选)
    @Relationship(deleteRule: .cascade, inverse: \Category.ledger)
    var categories: [Category]?
    
    /// 关联的流水 (CloudKit要求关系必须为可选)
    @Relationship(deleteRule: .cascade, inverse: \Transaction.ledger)
    var transactions: [Transaction]?
    
    /// 关联的预算 (CloudKit要求关系必须为可选)
    @Relationship(deleteRule: .cascade, inverse: \Budget.ledger)
    var budgets: [Budget]?
    
    /// 关联的标签 (CloudKit要求关系必须为可选)
    @Relationship(deleteRule: .cascade, inverse: \Tag.ledger)
    var tags: [Tag]?
    
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
        self.accounts = nil
        self.categories = nil
        self.transactions = nil
        self.budgets = nil
        self.tags = nil
    }
}

// MARK: - Computed Properties

extension Ledger {
    /// 计算总资产
    var totalAssets: Decimal {
        (accounts ?? [])
            .filter { !$0.excludeFromTotal && !$0.isArchived }
            .reduce(0) { $0 + $1.balance }
    }
    
    /// 活跃账户数量
    var activeAccountsCount: Int {
        (accounts ?? []).filter { !$0.isArchived }.count
    }
    
    /// 本月交易数量
    var thisMonthTransactionCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return (transactions ?? []).filter { transaction in
            calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }.count
    }
}

// MARK: - Business Logic

extension Ledger {
    /// 创建默认分类 (使用层级结构)
    func createDefaultCategories() {
        var sortOrder = 0
        
        // 支出分类 - 使用层级结构
        for hierarchy in CategoryIconConfig.expenseHierarchy {
            // 创建一级分类（父分类）
            let parentCategory = Category(
                ledger: self,
                name: hierarchy.name,
                type: .expense,
                iconName: hierarchy.style.iconName,
                colorHex: hierarchy.style.color,
                sortOrder: sortOrder
            )
            if categories == nil { categories = [] }
            categories?.append(parentCategory)
            sortOrder += 1
            
            // 创建二级分类（子分类）
            for (childIndex, child) in hierarchy.children.enumerated() {
                let childCategory = Category(
                    ledger: self,
                    name: child.name,
                    type: .expense,
                    iconName: child.style.iconName,
                    parent: parentCategory,
                    colorHex: child.style.color,
                    sortOrder: childIndex
                )
                categories?.append(childCategory)
            }
        }
        
        // 收入分类 - 使用层级结构
        for hierarchy in CategoryIconConfig.incomeHierarchy {
            // 创建一级分类（父分类）
            let parentCategory = Category(
                ledger: self,
                name: hierarchy.name,
                type: .income,
                iconName: hierarchy.style.iconName,
                colorHex: hierarchy.style.color,
                sortOrder: sortOrder
            )
            if categories == nil { categories = [] }
            categories?.append(parentCategory)
            sortOrder += 1
            
            // 创建二级分类（子分类）
            for (childIndex, child) in hierarchy.children.enumerated() {
                let childCategory = Category(
                    ledger: self,
                    name: child.name,
                    type: .income,
                    iconName: child.style.iconName,
                    parent: parentCategory,
                    colorHex: child.style.color,
                    sortOrder: childIndex
                )
                categories?.append(childCategory)
            }
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
        if accounts == nil { accounts = [] }
        accounts?.append(cash)
    }
}
