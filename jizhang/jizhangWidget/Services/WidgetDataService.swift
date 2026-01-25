//
//  WidgetDataService.swift
//  jizhangWidget
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

/// Widget数据服务 (Actor保证线程安全)
actor WidgetDataService {
    static let shared = WidgetDataService()
    
    private let modelContainer: ModelContainer
    private let appGroupIdentifier = "group.com.xxl.jizhang"
    
    private init() {
        // 配置SwiftData Schema
        let schema = Schema([
            Ledger.self,
            Account.self,
            Category.self,
            Transaction.self,
            Budget.self,
            Tag.self
        ])
        
        // 获取App Groups共享容器URL
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("无法获取App Groups容器URL")
        }
        
        let storeURL = containerURL.appendingPathComponent("jizhang.sqlite")
        
        let config = ModelConfiguration(schema: schema, url: storeURL)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("无法创建ModelContainer: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// 获取Widget数据
    @MainActor
    func fetchWidgetData() async throws -> WidgetData {
        let context = modelContainer.mainContext
        
        // 1. 获取当前账本
        guard let currentLedger = try getCurrentLedgerSync(context: context) else {
            return WidgetData.empty()
        }
        
        // 2. 计算日期范围
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        // 3. 获取今日交易
        let todayTransactions = try getTransactionsSync(
            in: context,
            ledger: currentLedger,
            from: todayStart,
            to: todayEnd
        )
        
        // 4. 获取本月交易
        let monthTransactions = try getTransactionsSync(
            in: context,
            ledger: currentLedger,
            from: monthStart,
            to: monthEnd
        )
        
        // 5. 计算今日收支
        let todayExpense = todayTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let todayIncome = todayTransactions
            .filter { $0.type == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        // 6. 计算本月收支
        let monthExpense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let monthIncome = monthTransactions
            .filter { $0.type == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        // 7. 获取预算信息
        let budgets = try getBudgetsSync(in: context, ledger: currentLedger, now: now)
        let monthBudget = budgets.reduce(Decimal(0)) { $0 + $1.amount }
        let todayBudget = monthBudget / Decimal(calendar.range(of: .day, in: .month, for: now)?.count ?? 30)
        
        // 8. 计算预算使用率
        let budgetUsage = monthBudget > 0 ? Double(truncating: (monthExpense / monthBudget) as NSNumber) : 0
        
        // 9. 转换为简化模型 (最近5笔)
        let simpleTransactions = monthTransactions
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { transaction in
                WidgetTransaction(
                    id: transaction.id,
                    amount: transaction.amount,
                    categoryName: transaction.category?.name ?? "未分类",
                    categoryIcon: transaction.category?.iconName ?? "questionmark.circle",
                    date: transaction.date,
                    type: transaction.type.rawValue,
                    note: transaction.note
                )
            }
        
        return WidgetData(
            todayExpense: todayExpense,
            todayIncome: todayIncome,
            monthExpense: monthExpense,
            monthIncome: monthIncome,
            todayBudget: todayBudget,
            monthBudget: monthBudget,
            budgetUsagePercentage: budgetUsage,
            recentTransactions: Array(simpleTransactions),
            lastUpdateTime: Date(),
            ledgerName: currentLedger.name
        )
    }
    
    // MARK: - Private Methods (Sync versions for use in performAsync)
    
    /// 获取当前账本 (同步版本)
    @MainActor
    private func getCurrentLedgerSync(context: ModelContext) throws -> Ledger? {
        // 从UserDefaults获取当前账本ID
        let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
        guard let ledgerIdString = sharedDefaults?.string(forKey: "currentLedgerId"),
              let ledgerId = UUID(uuidString: ledgerIdString) else {
            // 如果没有保存的账本ID,获取第一个非归档账本
            let descriptor = FetchDescriptor<Ledger>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let allLedgers = try context.fetch(descriptor)
            return allLedgers.first { !$0.isArchived }
        }
        
        let descriptor = FetchDescriptor<Ledger>()
        let allLedgers = try context.fetch(descriptor)
        return allLedgers.first { $0.id == ledgerId }
    }
    
    /// 获取指定时间范围的交易 (同步版本)
    @MainActor
    private func getTransactionsSync(
        in context: ModelContext,
        ledger: Ledger,
        from startDate: Date,
        to endDate: Date
    ) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let allTransactions = try context.fetch(descriptor)
        return allTransactions.filter { transaction in
            transaction.ledger?.id == ledger.id &&
            transaction.date >= startDate &&
            transaction.date < endDate
        }
    }
    
    /// 获取当前有效的预算 (同步版本)
    @MainActor
    private func getBudgetsSync(in context: ModelContext, ledger: Ledger, now: Date) throws -> [Budget] {
        let descriptor = FetchDescriptor<Budget>()
        let allBudgets = try context.fetch(descriptor)
        
        // 筛选属于当前账本且在有效期内的预算
        return allBudgets.filter { budget in
            budget.ledger?.id == ledger.id &&
            budget.startDate <= now &&
            budget.endDate > now
        }
    }
}
