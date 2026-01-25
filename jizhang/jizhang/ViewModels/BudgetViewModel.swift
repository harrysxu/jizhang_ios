//
//  BudgetViewModel.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var showBudgetForm = false
    @Published var showBudgetDetail = false
    @Published var selectedBudget: Budget?
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Computed Properties
    
    /// 计算总预算金额
    func calculateTotalBudget(budgets: [Budget]) -> Decimal {
        budgets.reduce(0) { $0 + $1.amount + $1.rolloverAmount }
    }
    
    /// 计算总已用金额
    func calculateTotalUsed(budgets: [Budget]) -> Decimal {
        budgets.reduce(0) { $0 + $1.usedAmount }
    }
    
    /// 计算距月底剩余天数
    func remainingDaysInMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1),
                                             to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!) else {
            return 0
        }
        
        let components = calendar.dateComponents([.day], from: now, to: endOfMonth)
        return max(components.day ?? 0, 0)
    }
    
    // MARK: - Budget Operations
    
    /// 创建新预算
    func createBudget(
        ledger: Ledger,
        category: Category,
        amount: Decimal,
        period: BudgetPeriod,
        startDate: Date,
        enableRollover: Bool
    ) throws {
        // 验证:检查是否已存在相同分类的预算
        let categoryId = category.id
        
        // 简化查询 - 先获取所有预算，然后在内存中过滤
        let allBudgets = try modelContext.fetch(FetchDescriptor<Budget>())
        
        let existingBudgets = allBudgets.filter { budget in
            budget.category?.id == categoryId &&
            budget.startDate <= startDate &&
            budget.endDate > startDate
        }
        
        if !existingBudgets.isEmpty {
            throw BudgetError.duplicateBudget
        }
        
        let budget = Budget(
            ledger: ledger,
            category: category,
            amount: amount,
            period: period,
            startDate: startDate,
            enableRollover: enableRollover
        )
        
        modelContext.insert(budget)
        try modelContext.save()
    }
    
    /// 更新预算
    func updateBudget(
        _ budget: Budget,
        amount: Decimal,
        period: BudgetPeriod,
        startDate: Date,
        enableRollover: Bool
    ) throws {
        budget.amount = amount
        budget.period = period
        budget.startDate = startDate
        budget.enableRollover = enableRollover
        
        // 重新计算结束日期
        let calendar = Calendar.current
        switch period {
        case .monthly:
            budget.endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .yearly:
            budget.endDate = calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .custom:
            // 自定义周期保持不变
            break
        }
        
        try modelContext.save()
    }
    
    /// 删除预算
    func deleteBudget(_ budget: Budget) throws {
        modelContext.delete(budget)
        try modelContext.save()
    }
    
    /// 检查并执行预算结转
    func checkAndRolloverBudgets(budgets: [Budget]) {
        let now = Date()
        
        for budget in budgets where budget.enableRollover {
            // 如果预算周期已结束
            if now >= budget.endDate {
                budget.rolloverToNextPeriod()
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "预算结转失败: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - UI Actions
    
    func showCreateBudget() {
        selectedBudget = nil
        showBudgetForm = true
    }
    
    func showEditBudget(_ budget: Budget) {
        selectedBudget = budget
        showBudgetForm = true
    }
    
    func showDetails(_ budget: Budget) {
        selectedBudget = budget
        showBudgetDetail = true
    }
}

// MARK: - BudgetError

enum BudgetError: LocalizedError {
    case duplicateBudget
    case invalidAmount
    case invalidPeriod
    
    var errorDescription: String? {
        switch self {
        case .duplicateBudget:
            return "该分类在此周期内已有预算"
        case .invalidAmount:
            return "预算金额必须大于0"
        case .invalidPeriod:
            return "无效的预算周期"
        }
    }
}
