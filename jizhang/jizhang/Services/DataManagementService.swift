//
//  DataManagementService.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import Foundation
import SwiftData

// MARK: - Data Management Service

/// 数据管理服务 - 处理账本的删除和重置操作
@MainActor
class DataManagementService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    /// 操作进度回调 (0.0 - 1.0)
    var progressHandler: ((Double, String) -> Void)?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Delete Operations
    
    /// 物理删除多个账本及其所有关联数据
    /// - Parameter ledgers: 要删除的账本数组
    /// - Returns: 删除的账本数量
    @discardableResult
    func deleteLedgers(_ ledgers: [Ledger]) throws -> Int {
        guard !ledgers.isEmpty else { return 0 }
        
        progressHandler?(0.0, "准备删除 \(ledgers.count) 个账本...")
        
        var deletedCount = 0
        let totalCount = ledgers.count
        
        for (index, ledger) in ledgers.enumerated() {
            let progress = Double(index) / Double(totalCount)
            progressHandler?(progress, "正在删除: \(ledger.name)...")
            
            // 由于 Ledger 模型使用了 cascade 删除规则，
            // 删除账本会自动级联删除所有关联的：
            // - 账户 (accounts)
            // - 分类 (categories)
            // - 交易 (transactions)
            // - 预算 (budgets)
            // - 标签 (tags)
            
            modelContext.delete(ledger)
            deletedCount += 1
        }
        
        progressHandler?(0.9, "正在保存更改...")
        try modelContext.save()
        
        progressHandler?(1.0, "已删除 \(deletedCount) 个账本")
        return deletedCount
    }
    
    /// 物理删除单个账本
    /// - Parameter ledger: 要删除的账本
    func deleteLedger(_ ledger: Ledger) throws {
        try deleteLedgers([ledger])
    }
    
    // MARK: - Reset Operations
    
    /// 重置多个账本（保留结构，清空数据）
    /// - Parameter ledgers: 要重置的账本数组
    /// - Returns: 重置的账本数量
    @discardableResult
    func resetLedgers(_ ledgers: [Ledger]) throws -> Int {
        guard !ledgers.isEmpty else { return 0 }
        
        progressHandler?(0.0, "准备重置 \(ledgers.count) 个账本...")
        
        var resetCount = 0
        let totalCount = ledgers.count
        
        for (index, ledger) in ledgers.enumerated() {
            let progress = Double(index) / Double(totalCount) * 0.9
            progressHandler?(progress, "正在重置: \(ledger.name)...")
            
            try resetLedgerData(ledger)
            resetCount += 1
        }
        
        progressHandler?(0.9, "正在保存更改...")
        try modelContext.save()
        
        progressHandler?(1.0, "已重置 \(resetCount) 个账本")
        return resetCount
    }
    
    /// 重置单个账本（保留结构，清空数据）
    /// - Parameter ledger: 要重置的账本
    /// 
    /// 重置操作会：
    /// - 删除所有交易记录
    /// - 删除所有预算
    /// - 删除所有标签
    /// - 重置所有账户余额为0
    /// 
    /// 保留：
    /// - 账本基本信息
    /// - 账户结构（名称、类型等）
    /// - 分类结构
    func resetLedger(_ ledger: Ledger) throws {
        try resetLedgers([ledger])
    }
    
    /// 重置账本数据的内部实现
    private func resetLedgerData(_ ledger: Ledger) throws {
        // 1. 删除所有交易
        for transaction in (ledger.transactions ?? []) {
            modelContext.delete(transaction)
        }
        
        // 2. 删除所有预算
        for budget in (ledger.budgets ?? []) {
            modelContext.delete(budget)
        }
        
        // 3. 删除所有标签
        for tag in (ledger.tags ?? []) {
            modelContext.delete(tag)
        }
        
        // 4. 重置所有账户余额
        for account in (ledger.accounts ?? []) {
            account.balance = 0
            // 清空信用卡的已用额度
            if account.type == .creditCard {
                account.balance = 0
            }
        }
    }
    
    // MARK: - Validation
    
    /// 获取账本的数据统计信息
    func getLedgerStatistics(_ ledger: Ledger) -> LedgerStatistics {
        return LedgerStatistics(
            transactionCount: (ledger.transactions ?? []).count,
            accountCount: (ledger.accounts ?? []).count,
            categoryCount: (ledger.categories ?? []).count,
            budgetCount: (ledger.budgets ?? []).count,
            tagCount: (ledger.tags ?? []).count,
            totalAssets: ledger.totalAssets
        )
    }
    
    /// 批量获取账本统计信息
    func getLedgersStatistics(_ ledgers: [Ledger]) -> [UUID: LedgerStatistics] {
        var result: [UUID: LedgerStatistics] = [:]
        for ledger in ledgers {
            result[ledger.id] = getLedgerStatistics(ledger)
        }
        return result
    }
}

// MARK: - Ledger Statistics

/// 账本数据统计
struct LedgerStatistics {
    let transactionCount: Int
    let accountCount: Int
    let categoryCount: Int
    let budgetCount: Int
    let tagCount: Int
    let totalAssets: Decimal
    
    /// 是否有数据
    var hasData: Bool {
        transactionCount > 0 || budgetCount > 0 || tagCount > 0
    }
    
    /// 格式化的摘要信息
    var summary: String {
        var parts: [String] = []
        if transactionCount > 0 {
            parts.append("\(transactionCount) 笔交易")
        }
        if accountCount > 0 {
            parts.append("\(accountCount) 个账户")
        }
        if budgetCount > 0 {
            parts.append("\(budgetCount) 个预算")
        }
        return parts.isEmpty ? "无数据" : parts.joined(separator: "、")
    }
}

// MARK: - Data Management Errors

enum DataManagementError: LocalizedError {
    case noLedgersSelected
    case cannotDeleteDefaultLedger
    case deletionFailed(String)
    case resetFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noLedgersSelected:
            return "请至少选择一个账本"
        case .cannotDeleteDefaultLedger:
            return "无法删除默认账本，请先设置其他账本为默认"
        case .deletionFailed(let reason):
            return "删除失败: \(reason)"
        case .resetFailed(let reason):
            return "重置失败: \(reason)"
        }
    }
}
