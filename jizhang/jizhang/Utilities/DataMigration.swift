//
//  DataMigration.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import Foundation
import SwiftData

/// 数据迁移服务
class DataMigration {
    
    /// 执行完整的数据迁移检查和修复
    @MainActor
    static func migrateIfNeeded(context: ModelContext) {
        print("📦 开始数据迁移检查...")
        
        do {
            // 1. 确保至少有一个账本
            try ensureDefaultLedger(context: context)
            
            // 2. 确保所有数据都关联到账本
            try ensureDataLinkedToLedger(context: context)
            
            // 3. 确保至少有一个默认账本
            try ensureDefaultLedgerExists(context: context)
            
            print("✅ 数据迁移完成")
        } catch {
            print("❌ 数据迁移失败: \(error)")
        }
    }
    
    /// 1. 确保至少有一个账本
    @MainActor
    private static func ensureDefaultLedger(context: ModelContext) throws {
        let ledgerDescriptor = FetchDescriptor<Ledger>()
        let ledgers = try context.fetch(ledgerDescriptor)
        
        if ledgers.isEmpty {
            print("📝 创建默认账本...")
            
            let defaultLedger = Ledger(
                name: "日常账本",
                currencyCode: "CNY",
                colorHex: "#007AFF",
                iconName: "book.fill",
                sortOrder: 0,
                isDefault: true
            )
            
            context.insert(defaultLedger)
            
            // 创建默认分类和账户
            defaultLedger.createDefaultCategories()
            defaultLedger.createDefaultAccounts()
            
            try context.save()
            print("✅ 已创建默认账本")
        }
    }
    
    /// 2. 确保所有数据都关联到账本
    @MainActor
    private static func ensureDataLinkedToLedger(context: ModelContext) throws {
        // 获取默认账本或第一个账本
        let ledgerDescriptor = FetchDescriptor<Ledger>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        guard let defaultLedger = try context.fetch(ledgerDescriptor).first else {
            print("⚠️ 未找到账本,跳过数据关联检查")
            return
        }
        
        var hasChanges = false
        
        // 检查并关联账户
        let accountDescriptor = FetchDescriptor<Account>()
        let accounts = try context.fetch(accountDescriptor)
        let orphanAccounts = accounts.filter { $0.ledger == nil }
        
        if !orphanAccounts.isEmpty {
            print("🔗 关联 \(orphanAccounts.count) 个孤立账户到账本...")
            for account in orphanAccounts {
                account.ledger = defaultLedger
            }
            hasChanges = true
        }
        
        // 检查并关联分类
        let categoryDescriptor = FetchDescriptor<Category>()
        let categories = try context.fetch(categoryDescriptor)
        let orphanCategories = categories.filter { $0.ledger == nil }
        
        if !orphanCategories.isEmpty {
            print("🔗 关联 \(orphanCategories.count) 个孤立分类到账本...")
            for category in orphanCategories {
                category.ledger = defaultLedger
            }
            hasChanges = true
        }
        
        // 检查并关联交易
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(transactionDescriptor)
        let orphanTransactions = transactions.filter { $0.ledger == nil }
        
        if !orphanTransactions.isEmpty {
            print("🔗 关联 \(orphanTransactions.count) 个孤立交易到账本...")
            for transaction in orphanTransactions {
                transaction.ledger = defaultLedger
            }
            hasChanges = true
        }
        
        // 检查并关联预算
        let budgetDescriptor = FetchDescriptor<Budget>()
        let budgets = try context.fetch(budgetDescriptor)
        let orphanBudgets = budgets.filter { $0.ledger == nil }
        
        if !orphanBudgets.isEmpty {
            print("🔗 关联 \(orphanBudgets.count) 个孤立预算到账本...")
            for budget in orphanBudgets {
                budget.ledger = defaultLedger
            }
            hasChanges = true
        }
        
        // 检查并关联标签
        let tagDescriptor = FetchDescriptor<Tag>()
        let tags = try context.fetch(tagDescriptor)
        let orphanTags = tags.filter { $0.ledger == nil }
        
        if !orphanTags.isEmpty {
            print("🔗 关联 \(orphanTags.count) 个孤立标签到账本...")
            for tag in orphanTags {
                tag.ledger = defaultLedger
            }
            hasChanges = true
        }
        
        if hasChanges {
            try context.save()
            print("✅ 数据关联完成")
        } else {
            print("✓ 所有数据已正确关联")
        }
    }
    
    /// 3. 确保至少有一个默认账本
    @MainActor
    private static func ensureDefaultLedgerExists(context: ModelContext) throws {
        let defaultDescriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.isDefault == true }
        )
        let defaultLedgers = try context.fetch(defaultDescriptor)
        
        if defaultLedgers.isEmpty {
            print("⚙️ 设置第一个账本为默认...")
            
            let firstDescriptor = FetchDescriptor<Ledger>(
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            if let firstLedger = try context.fetch(firstDescriptor).first {
                firstLedger.isDefault = true
                try context.save()
                print("✅ 已设置默认账本: \(firstLedger.name)")
            }
        } else if defaultLedgers.count > 1 {
            // 如果有多个默认账本,只保留第一个
            print("⚠️ 发现多个默认账本,修正中...")
            for (index, ledger) in defaultLedgers.enumerated() {
                if index > 0 {
                    ledger.isDefault = false
                }
            }
            try context.save()
            print("✅ 已修正默认账本")
        } else {
            print("✓ 默认账本设置正确")
        }
    }
    
    /// 清理无效数据
    @MainActor
    static func cleanupInvalidData(context: ModelContext) throws {
        print("🧹 开始清理无效数据...")
        
        var hasChanges = false
        
        // 清理没有账本关联的交易
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(transactionDescriptor)
        let invalidTransactions = transactions.filter { $0.ledger == nil }
        
        if !invalidTransactions.isEmpty {
            print("🗑️ 删除 \(invalidTransactions.count) 个无效交易...")
            for transaction in invalidTransactions {
                context.delete(transaction)
            }
            hasChanges = true
        }
        
        // 清理没有账本关联的预算
        let budgetDescriptor = FetchDescriptor<Budget>()
        let budgets = try context.fetch(budgetDescriptor)
        let invalidBudgets = budgets.filter { $0.ledger == nil || $0.category == nil }
        
        if !invalidBudgets.isEmpty {
            print("🗑️ 删除 \(invalidBudgets.count) 个无效预算...")
            for budget in invalidBudgets {
                context.delete(budget)
            }
            hasChanges = true
        }
        
        if hasChanges {
            try context.save()
            print("✅ 无效数据清理完成")
        } else {
            print("✓ 没有发现无效数据")
        }
    }
}
