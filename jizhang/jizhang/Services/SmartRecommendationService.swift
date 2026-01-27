//
//  SmartRecommendationService.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import Foundation
import SwiftData

/// 智能推荐服务 - 基于历史数据和规则推荐分类、账户等
@MainActor
class SmartRecommendationService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 分类推荐
    
    /// 推荐分类(基于时间段和历史记录)
    func suggestCategory(for type: TransactionType, ledger: Ledger) -> Category? {
        // 1. 基于时间段的规则推荐
        if let timeBasedCategory = suggestCategoryByTime(for: type, ledger: ledger) {
            return timeBasedCategory
        }
        
        // 2. 基于历史记录推荐
        if let historyBasedCategory = suggestCategoryByHistory(for: type, ledger: ledger) {
            return historyBasedCategory
        }
        
        // 3. 返回默认分类
        return getDefaultCategory(for: type, ledger: ledger)
    }
    
    private func suggestCategoryByTime(for type: TransactionType, ledger: Ledger) -> Category? {
        guard type == .expense else { return nil }
        
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        // 早餐时间 (7:00-9:00)
        if (7...9).contains(hour) {
            return findCategory(named: "早餐", in: ledger)
        }
        
        // 午餐时间 (11:00-14:00)
        if (11...14).contains(hour) {
            return findCategory(named: "午餐", in: ledger)
        }
        
        // 晚餐时间 (17:00-20:00)
        if (17...20).contains(hour) {
            return findCategory(named: "晚餐", in: ledger)
        }
        
        // 通勤时间 (7:00-9:00, 17:00-19:00)
        if (7...9).contains(hour) || (17...19).contains(hour) {
            if let transport = findCategory(named: "交通", in: ledger) {
                return transport
            }
        }
        
        return nil
    }
    
    private func suggestCategoryByHistory(for type: TransactionType, ledger: Ledger) -> Category? {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        // 获取最近50笔相同类型的交易
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allTransactions = try? modelContext.fetch(descriptor) else {
            return nil
        }
        
        // 手动过滤(避免Predicate宏的问题)
        let transactions = allTransactions
            .filter { $0.ledger?.id == ledger.id && $0.type == type }
            .prefix(50)
        
        // 统计分类使用频率
        var categoryFrequency: [UUID: Int] = [:]
        for transaction in transactions {
            if let categoryId = transaction.category?.id {
                categoryFrequency[categoryId, default: 0] += 1
            }
        }
        
        // 同时段历史记录 (前后1小时)
        let samePeriodTransactions = transactions.filter { transaction in
            let transactionHour = Calendar.current.component(.hour, from: transaction.date)
            return abs(transactionHour - hour) <= 1
        }
        
        // 如果有同时段记录,优先使用同时段最常用的分类
        if !samePeriodTransactions.isEmpty {
            var samePeriodFrequency: [UUID: Int] = [:]
            for transaction in samePeriodTransactions {
                if let categoryId = transaction.category?.id {
                    samePeriodFrequency[categoryId, default: 0] += 1
                }
            }
            
            if let mostCommonId = samePeriodFrequency.max(by: { $0.value < $1.value })?.key {
                return (ledger.categories ?? []).first { $0.id == mostCommonId }
            }
        }
        
        // 返回总体最常用的分类
        if let mostCommonId = categoryFrequency.max(by: { $0.value < $1.value })?.key {
            return (ledger.categories ?? []).first { $0.id == mostCommonId }
        }
        
        return nil
    }
    
    private func getDefaultCategory(for type: TransactionType, ledger: Ledger) -> Category? {
        let defaultNames: [String]
        switch type {
        case .expense:
            defaultNames = ["餐饮", "其他"]
        case .income:
            defaultNames = ["工资", "其他"]
        case .transfer, .adjustment:
            return nil
        }
        
        for name in defaultNames {
            if let category = findCategory(named: name, in: ledger) {
                return category
            }
        }
        
        return (ledger.categories ?? []).first { $0.type == (type == .expense ? .expense : .income) }
    }
    
    private func findCategory(named name: String, in ledger: Ledger) -> Category? {
        return (ledger.categories ?? []).first { category in
            category.name.contains(name) || name.contains(category.name)
        }
    }
    
    // MARK: - 账户推荐
    
    /// 推荐账户(基于最近使用)
    func suggestAccount(for type: TransactionType, ledger: Ledger) -> Account? {
        // 获取最近10笔交易
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allTransactions = try? modelContext.fetch(descriptor) else {
            return nil
        }
        
        // 手动过滤
        let recentTransactions = allTransactions
            .filter { $0.ledger?.id == ledger.id && $0.type == type }
            .prefix(10)
        
        // 统计账户使用频率
        var accountFrequency: [UUID: Int] = [:]
        for transaction in recentTransactions {
            if let accountId = transaction.fromAccount?.id {
                accountFrequency[accountId, default: 0] += 1
            }
        }
        
        // 返回最常用的账户
        if let mostCommonId = accountFrequency.max(by: { $0.value < $1.value })?.key {
            return (ledger.accounts ?? []).first { $0.id == mostCommonId }
        }
        
        // 如果没有历史记录,返回第一个非信用卡账户
        return (ledger.accounts ?? []).first { $0.type != .creditCard } ?? (ledger.accounts ?? []).first
    }
    
    // MARK: - 金额建议
    
    /// 建议金额(基于同分类历史记录)
    func suggestAmount(for category: Category?, account: Account?) -> [Decimal] {
        guard let category = category else { return [] }
        
        // 获取该分类最近20笔交易
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allTransactions = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        // 手动过滤
        let transactions = allTransactions
            .filter { $0.category?.id == category.id }
            .prefix(20)
        
        // 统计金额出现频率
        var amountFrequency: [Decimal: Int] = [:]
        for transaction in transactions {
            amountFrequency[transaction.amount, default: 0] += 1
        }
        
        // 返回前3个最常用的金额
        let sortedAmounts = amountFrequency.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        return Array(sortedAmounts)
    }
}

// MARK: - User Preferences

/// 用户偏好设置
class UserPreferences {
    static let shared = UserPreferences()
    private let defaults = UserDefaults.standard
    
    /// 记忆最后使用的账户
    func rememberLastAccount(id: UUID, for type: TransactionType) {
        defaults.set(id.uuidString, forKey: "last_account_\(type.rawValue)")
    }
    
    /// 获取最后使用的账户
    func getLastAccount(for type: TransactionType) -> UUID? {
        guard let uuidString = defaults.string(forKey: "last_account_\(type.rawValue)") else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
    
    /// 记忆最后使用的分类
    func rememberLastCategory(id: UUID, for type: TransactionType) {
        defaults.set(id.uuidString, forKey: "last_category_\(type.rawValue)")
    }
    
    /// 获取最后使用的分类
    func getLastCategory(for type: TransactionType) -> UUID? {
        guard let uuidString = defaults.string(forKey: "last_category_\(type.rawValue)") else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
    
    /// 是否使用快速记账模式
    var useQuickMode: Bool {
        get { defaults.bool(forKey: "use_quick_mode") }
        set { defaults.set(newValue, forKey: "use_quick_mode") }
    }
}
