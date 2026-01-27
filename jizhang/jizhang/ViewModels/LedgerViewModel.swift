//
//  LedgerViewModel.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class LedgerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var showLedgerForm = false
    @Published var showLedgerPicker = false
    @Published var selectedLedger: Ledger?
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Ledger Operations
    
    /// 创建新账本
    func createLedger(
        name: String,
        currencyCode: String = "CNY",
        colorHex: String,
        iconName: String
    ) throws {
        // 验证名称
        guard !name.isEmpty else {
            throw LedgerError.emptyName
        }
        
        // 检查重名
        let ledgerName = name // 捕获到局部变量
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { ledger in
                ledger.name == ledgerName
            }
        )
        let existing = try modelContext.fetch(descriptor)
        if !existing.isEmpty {
            throw LedgerError.duplicateName
        }
        
        // 检查是否是第一个账本
        let ledgerCount = getLedgerCount()
        let isFirstLedger = ledgerCount == 0
        
        // 创建账本
        let ledger = Ledger(
            name: name,
            currencyCode: currencyCode,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: ledgerCount,
            isDefault: isFirstLedger // 第一个账本自动设为默认
        )
        
        // 先插入账本
        modelContext.insert(ledger)
        
        // 然后创建默认分类和账户（此时 ledger 已经在 context 中）
        createDefaultCategoriesForLedger(ledger)
        createDefaultAccountsForLedger(ledger)
        
        // 保存所有更改
        try modelContext.save()
    }
    
    /// 为账本创建默认分类
    private func createDefaultCategoriesForLedger(_ ledger: Ledger) {
        // 支出分类
        let expenseCategories: [(String, String, [String])] = [
            ("餐饮", "fork.knife", ["早餐", "午餐", "晚餐", "零食", "咖啡", "请客"]),
            ("交通", "car.fill", ["地铁", "公交", "打车", "加油", "停车"]),
            ("购物", "cart.fill", ["日用品", "服饰", "电子产品", "图书"]),
            ("居住", "house.fill", ["房租", "水电", "物业", "维修"]),
            ("娱乐", "gamecontroller.fill", ["电影", "游戏", "运动", "旅游"]),
            ("医疗", "cross.case.fill", ["药品", "就医", "保健"]),
            ("教育", "book.fill", ["学费", "培训", "书籍"]),
            ("通讯", "phone.fill", ["话费", "宽带", "会员"])
        ]
        
        for (index, (parentName, icon, children)) in expenseCategories.enumerated() {
            let parent = Category(
                ledger: ledger,
                name: parentName,
                type: .expense,
                iconName: icon,
                sortOrder: index
            )
            modelContext.insert(parent)
            
            for (childIndex, childName) in children.enumerated() {
                let child = Category(
                    ledger: ledger,
                    name: childName,
                    type: .expense,
                    iconName: icon,
                    parent: parent,
                    sortOrder: childIndex
                )
                modelContext.insert(child)
            }
        }
        
        // 收入分类
        let incomeCategories: [(String, String, [String])] = [
            ("工资", "banknote.fill", ["基本工资", "奖金", "补贴"]),
            ("投资", "chart.line.uptrend.xyaxis", ["股票", "基金", "利息"]),
            ("其他", "ellipsis.circle.fill", ["礼金", "报销", "兼职"])
        ]
        
        for (index, (parentName, icon, children)) in incomeCategories.enumerated() {
            let parent = Category(
                ledger: ledger,
                name: parentName,
                type: .income,
                iconName: icon,
                sortOrder: expenseCategories.count + index
            )
            modelContext.insert(parent)
            
            for (childIndex, childName) in children.enumerated() {
                let child = Category(
                    ledger: ledger,
                    name: childName,
                    type: .income,
                    iconName: icon,
                    parent: parent,
                    sortOrder: childIndex
                )
                modelContext.insert(child)
            }
        }
    }
    
    /// 为账本创建默认账户
    private func createDefaultAccountsForLedger(_ ledger: Ledger) {
        let cash = Account(
            ledger: ledger,
            name: "现金",
            type: .cash,
            iconName: "banknote.fill"
        )
        modelContext.insert(cash)
    }
    
    /// 更新账本
    func updateLedger(
        _ ledger: Ledger,
        name: String,
        currencyCode: String,
        colorHex: String,
        iconName: String
    ) throws {
        guard !name.isEmpty else {
            throw LedgerError.emptyName
        }
        
        // 检查重名(排除自己)
        let ledgerName = name // 捕获到局部变量
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { ledger in
                ledger.name == ledgerName
            }
        )
        let existing = try modelContext.fetch(descriptor)
        if let duplicate = existing.first, duplicate.id != ledger.id {
            throw LedgerError.duplicateName
        }
        
        ledger.name = name
        ledger.currencyCode = currencyCode
        ledger.colorHex = colorHex
        ledger.iconName = iconName
        
        try modelContext.save()
    }
    
    /// 删除账本
    func deleteLedger(_ ledger: Ledger) throws {
        // 检查是否有交易
        if !(ledger.transactions ?? []).isEmpty {
            throw LedgerError.hasTransactions
        }
        
        modelContext.delete(ledger)
        try modelContext.save()
    }
    
    /// 归档账本
    func archiveLedger(_ ledger: Ledger) throws {
        ledger.isArchived = true
        try modelContext.save()
    }
    
    /// 取消归档
    func unarchiveLedger(_ ledger: Ledger) throws {
        ledger.isArchived = false
        try modelContext.save()
    }
    
    /// 设置默认账本
    func setDefaultLedger(_ ledger: Ledger) throws {
        // 如果已经是默认账本，直接返回
        if ledger.isDefault {
            return
        }
        
        // 获取所有账本
        let descriptor = FetchDescriptor<Ledger>()
        let allLedgers = try modelContext.fetch(descriptor)
        
        // 将其他账本的默认状态设为 false
        for otherLedger in allLedgers where otherLedger.id != ledger.id {
            otherLedger.isDefault = false
        }
        
        // 设置当前账本为默认
        ledger.isDefault = true
        
        try modelContext.save()
    }
    
    // MARK: - Helper Methods
    
    private func getLedgerCount() -> Int {
        let descriptor = FetchDescriptor<Ledger>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    /// 复制账本设置(账户和分类结构)到新账本
    func copyLedgerSettings(from sourceLedger: Ledger, to targetLedger: Ledger) throws {
        // 1. 复制账户结构
        for sourceAccount in (sourceLedger.accounts ?? []) where !sourceAccount.isArchived {
            let newAccount = Account(
                ledger: targetLedger,
                name: sourceAccount.name,
                type: sourceAccount.type,
                balance: 0, // 新账本账户余额从0开始
                iconName: sourceAccount.iconName,
                colorHex: sourceAccount.colorHex,
                sortOrder: sourceAccount.sortOrder
            )
            
            // 复制信用卡特定字段
            if sourceAccount.type == .creditCard {
                newAccount.creditLimit = sourceAccount.creditLimit
                newAccount.statementDay = sourceAccount.statementDay
                newAccount.dueDay = sourceAccount.dueDay
            }
            
            newAccount.excludeFromTotal = sourceAccount.excludeFromTotal
            
            modelContext.insert(newAccount)
        }
        
        // 2. 复制分类结构
        // 先复制父分类
        var categoryMapping: [UUID: Category] = [:]
        
        let parentCategories = (sourceLedger.categories ?? []).filter { $0.parent == nil && !$0.isHidden }
        for sourceCategory in parentCategories {
            let newCategory = Category(
                ledger: targetLedger,
                name: sourceCategory.name,
                type: sourceCategory.type,
                iconName: sourceCategory.iconName,
                parent: nil,
                colorHex: sourceCategory.colorHex,
                sortOrder: sourceCategory.sortOrder
            )
            
            modelContext.insert(newCategory)
            categoryMapping[sourceCategory.id] = newCategory
        }
        
        // 再复制子分类
        let childCategories = (sourceLedger.categories ?? []).filter { $0.parent != nil && !$0.isHidden }
        for sourceCategory in childCategories {
            if let sourceParent = sourceCategory.parent,
               let newParent = categoryMapping[sourceParent.id] {
                let newCategory = Category(
                    ledger: targetLedger,
                    name: sourceCategory.name,
                    type: sourceCategory.type,
                    iconName: sourceCategory.iconName,
                    parent: newParent,
                    colorHex: sourceCategory.colorHex,
                    sortOrder: sourceCategory.sortOrder
                )
                
                modelContext.insert(newCategory)
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - UI Actions
    
    func showCreateLedger() {
        selectedLedger = nil
        showLedgerForm = true
    }
    
    func showEditLedger(_ ledger: Ledger) {
        selectedLedger = ledger
        showLedgerForm = true
    }
}

// MARK: - LedgerError

enum LedgerError: LocalizedError {
    case emptyName
    case duplicateName
    case hasTransactions
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "账本名称不能为空"
        case .duplicateName:
            return "账本名称已存在"
        case .hasTransactions:
            return "账本中还有交易记录,无法删除"
        }
    }
}
