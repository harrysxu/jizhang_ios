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
    /// 创建默认分类
    func createDefaultCategories() {
        // 支出分类 (带颜色)
        let expenseCategories: [(String, String, String, [String])] = [
            ("餐饮", "fork.knife", "#FF8F59", ["早餐", "午餐", "晚餐", "零食", "咖啡", "请客"]),
            ("交通", "car.fill", "#5B9FED", ["地铁", "公交", "打车", "加油", "停车"]),
            ("购物", "cart.fill", "#FF6B9D", ["日用品", "服饰", "电子产品", "图书"]),
            ("居住", "house.fill", "#9B59B6", ["房租", "水电", "物业", "维修"]),
            ("娱乐", "gamecontroller.fill", "#F368E0", ["电影", "游戏", "运动", "旅游"]),
            ("医疗", "cross.case.fill", "#00D2D3", ["药品", "就医", "保健"]),
            ("教育", "book.fill", "#FFA502", ["学费", "培训", "书籍"]),
            ("通讯", "phone.fill", "#786BED", ["话费", "宽带", "会员"])
        ]
        
        for (index, (parentName, icon, color, children)) in expenseCategories.enumerated() {
            let parent = Category(
                ledger: self,
                name: parentName,
                type: .expense,
                iconName: icon,
                colorHex: color,
                sortOrder: index
            )
            categories.append(parent)
            
            for (childIndex, childName) in children.enumerated() {
                let child = Category(
                    ledger: self,
                    name: childName,
                    type: .expense,
                    iconName: icon,
                    parent: parent,
                    colorHex: color,
                    sortOrder: childIndex
                )
                categories.append(child)
            }
        }
        
        // 收入分类 (带颜色)
        let incomeCategories: [(String, String, String, [String])] = [
            ("工资", "banknote.fill", "#26DE81", ["基本工资", "奖金", "补贴"]),
            ("投资", "chart.line.uptrend.xyaxis", "#1E88E5", ["股票", "基金", "利息"]),
            ("其他", "ellipsis.circle.fill", "#A8A8A8", ["礼金", "报销", "兼职"])
        ]
        
        for (index, (parentName, icon, color, children)) in incomeCategories.enumerated() {
            let parent = Category(
                ledger: self,
                name: parentName,
                type: .income,
                iconName: icon,
                colorHex: color,
                sortOrder: expenseCategories.count + index
            )
            categories.append(parent)
            
            for (childIndex, childName) in children.enumerated() {
                let child = Category(
                    ledger: self,
                    name: childName,
                    type: .income,
                    iconName: icon,
                    parent: parent,
                    colorHex: color,
                    sortOrder: childIndex
                )
                categories.append(child)
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
        accounts.append(cash)
    }
}
