//
//  TestDataGenerator.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import Foundation
import SwiftData

// MARK: - Test Data Configuration

/// 测试数据生成配置
struct TestDataConfig: Sendable {
    /// 数据时间跨度（月）
    var durationMonths: Int = 3
    
    /// 每日平均交易数量
    var transactionsPerDay: Int = 5
    
    /// 账户数量
    var accountCount: Int = 4
    
    /// 预算数量
    var budgetCount: Int = 5
    
    /// 是否包含转账交易
    var includeTransfers: Bool = true
    
    /// 支出/收入比例（支出占比）
    var expenseRatio: Double = 0.85
    
    /// 默认配置
    static let `default` = TestDataConfig()
    
    /// 最小配置（快速测试）
    static let minimal = TestDataConfig(
        durationMonths: 1,
        transactionsPerDay: 2,
        accountCount: 2,
        budgetCount: 2,
        includeTransfers: false
    )
    
    /// 完整配置（压力测试）
    static let full = TestDataConfig(
        durationMonths: 12,
        transactionsPerDay: 10,
        accountCount: 8,
        budgetCount: 10,
        includeTransfers: true
    )
}

// MARK: - Test Data Generator

/// 测试数据生成器
@MainActor
class TestDataGenerator {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var config: TestDataConfig
    
    /// 生成进度回调 (0.0 - 1.0)
    var progressHandler: ((Double, String) -> Void)?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, config: TestDataConfig) {
        self.modelContext = modelContext
        self.config = config
    }
    
    /// 使用默认配置初始化
    convenience init(modelContext: ModelContext) {
        self.init(modelContext: modelContext, config: .default)
    }
    
    // MARK: - Public Methods
    
    /// 为指定账本生成测试数据
    func generateTestData(for ledger: Ledger) async throws {
        progressHandler?(0.0, "开始生成测试数据...")
        
        // 1. 生成账户 (20%)
        progressHandler?(0.05, "正在生成账户...")
        let accounts = try generateAccounts(for: ledger)
        
        progressHandler?(0.20, "账户生成完成，共 \(accounts.count) 个")
        
        // 2. 确保分类存在 (30%)
        progressHandler?(0.25, "检查分类...")
        ensureCategoriesExist(for: ledger)
        
        progressHandler?(0.30, "分类检查完成")
        
        // 3. 生成交易 (80%)
        progressHandler?(0.35, "正在生成交易...")
        let transactionCount = try await generateTransactions(for: ledger, accounts: accounts)
        
        progressHandler?(0.80, "交易生成完成，共 \(transactionCount) 笔")
        
        // 4. 生成预算 (95%)
        progressHandler?(0.85, "正在生成预算...")
        let budgetCount = try generateBudgets(for: ledger)
        
        progressHandler?(0.95, "预算生成完成，共 \(budgetCount) 个")
        
        // 5. 保存数据
        progressHandler?(0.98, "正在保存数据...")
        try modelContext.save()
        
        progressHandler?(1.0, "测试数据生成完成！")
    }
    
    /// 为新账本生成完整测试数据（包括账本创建）
    func createLedgerWithTestData(name: String) async throws -> Ledger {
        progressHandler?(0.0, "正在创建账本...")
        
        // 创建账本
        let ledger = Ledger(
            name: name,
            currencyCode: "CNY",
            colorHex: randomLedgerColor(),
            iconName: "book.fill"
        )
        modelContext.insert(ledger)
        
        // 创建默认分类
        ledger.createDefaultCategories()
        
        progressHandler?(0.05, "账本创建完成")
        
        // 生成测试数据
        try await generateTestData(for: ledger)
        
        return ledger
    }
    
    // MARK: - Private Methods
    
    /// 生成账户
    private func generateAccounts(for ledger: Ledger) throws -> [Account] {
        var accounts: [Account] = []
        
        let accountTemplates: [(String, AccountType, Decimal, String)] = [
            ("现金钱包", .cash, Decimal(Int.random(in: 500...3000)), "#4CAF50"),
            ("工商银行储蓄卡", .checking, Decimal(Int.random(in: 10000...100000)), "#E53935"),
            ("招商银行储蓄卡", .checking, Decimal(Int.random(in: 5000...50000)), "#1E88E5"),
            ("建设银行储蓄卡", .checking, Decimal(Int.random(in: 3000...30000)), "#0D47A1"),
            ("招商银行信用卡", .creditCard, Decimal(-Int.random(in: 1000...10000)), "#FF5722"),
            ("交通银行信用卡", .creditCard, Decimal(-Int.random(in: 500...5000)), "#9C27B0"),
            ("微信钱包", .eWallet, Decimal(Int.random(in: 100...5000)), "#07C160"),
            ("支付宝", .eWallet, Decimal(Int.random(in: 200...8000)), "#1677FF"),
        ]
        
        let count = min(config.accountCount, accountTemplates.count)
        let selectedTemplates = Array(accountTemplates.shuffled().prefix(count))
        
        for (index, template) in selectedTemplates.enumerated() {
            let account = Account(
                ledger: ledger,
                name: template.0,
                type: template.1,
                balance: template.2,
                colorHex: template.3,
                sortOrder: index
            )
            
            // 配置信用卡特殊属性
            if template.1 == .creditCard {
                account.creditLimit = Decimal(Int.random(in: 10000...50000))
                account.statementDay = Int.random(in: 1...28)
                account.dueDay = Int.random(in: 1...28)
            }
            
            modelContext.insert(account)
            accounts.append(account)
        }
        
        return accounts
    }
    
    /// 确保分类存在
    private func ensureCategoriesExist(for ledger: Ledger) {
        if ledger.categories.isEmpty {
            ledger.createDefaultCategories()
        }
        
        // 为一些常用分类启用快速选择
        setupQuickSelectCategories(for: ledger)
    }
    
    /// 设置快速选择分类
    private func setupQuickSelectCategories(for ledger: Ledger) {
        // 常用的支出分类名称（子分类）
        let quickSelectExpenseNames = ["早餐", "午餐", "晚餐", "地铁公交", "打车", "日用品", "水果零食"]
        
        // 常用的收入分类名称
        let quickSelectIncomeNames = ["工资", "奖金"]
        
        for category in ledger.categories {
            if category.type == .expense && quickSelectExpenseNames.contains(category.name) {
                category.isQuickSelect = true
            } else if category.type == .income && quickSelectIncomeNames.contains(category.name) {
                category.isQuickSelect = true
            }
        }
    }
    
    /// 生成交易
    private func generateTransactions(for ledger: Ledger, accounts: [Account]) async throws -> Int {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -config.durationMonths, to: endDate) else {
            return 0
        }
        
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        var transactionCount = 0
        
        // 获取分类
        let expenseCategories = ledger.categories.filter { $0.type == .expense }
        let incomeCategories = ledger.categories.filter { $0.type == .income }
        
        guard !expenseCategories.isEmpty, !incomeCategories.isEmpty, !accounts.isEmpty else {
            return 0
        }
        
        // 按天生成交易
        for dayOffset in 0..<dayCount {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            // 每天生成随机数量的交易
            let dailyTransactionCount = Int.random(in: max(1, config.transactionsPerDay - 2)...config.transactionsPerDay + 2)
            
            for _ in 0..<dailyTransactionCount {
                // 随机决定交易类型
                let random = Double.random(in: 0...1)
                
                if random < config.expenseRatio {
                    // 生成支出
                    try generateExpenseTransaction(
                        ledger: ledger,
                        date: randomTimeOnDate(currentDate),
                        accounts: accounts,
                        categories: expenseCategories
                    )
                } else if config.includeTransfers && random < config.expenseRatio + 0.05 {
                    // 生成转账 (5%概率)
                    try generateTransferTransaction(
                        ledger: ledger,
                        date: randomTimeOnDate(currentDate),
                        accounts: accounts
                    )
                } else {
                    // 生成收入
                    try generateIncomeTransaction(
                        ledger: ledger,
                        date: randomTimeOnDate(currentDate),
                        accounts: accounts,
                        categories: incomeCategories
                    )
                }
                
                transactionCount += 1
            }
            
            // 更新进度
            let progress = 0.35 + (Double(dayOffset) / Double(dayCount)) * 0.45
            if dayOffset % 10 == 0 {
                progressHandler?(progress, "正在生成第 \(dayOffset + 1) 天的交易...")
            }
        }
        
        return transactionCount
    }
    
    /// 生成支出交易
    private func generateExpenseTransaction(
        ledger: Ledger,
        date: Date,
        accounts: [Account],
        categories: [Category]
    ) throws {
        guard let category = categories.randomElement(),
              let account = accounts.filter({ $0.type != .creditCard || $0.balance > -($0.creditLimit ?? 0) }).randomElement() ?? accounts.randomElement() else {
            return
        }
        
        let amount = randomExpenseAmount(for: category.name)
        
        let transaction = Transaction(
            ledger: ledger,
            amount: amount,
            date: date,
            type: .expense,
            fromAccount: account,
            category: category,
            note: randomExpenseNote(for: category.name)
        )
        
        modelContext.insert(transaction)
        transaction.updateAccountBalance()
    }
    
    /// 生成收入交易
    private func generateIncomeTransaction(
        ledger: Ledger,
        date: Date,
        accounts: [Account],
        categories: [Category]
    ) throws {
        guard let category = categories.randomElement(),
              let account = accounts.filter({ $0.type != .creditCard }).randomElement() else {
            return
        }
        
        let amount = randomIncomeAmount(for: category.name)
        
        let transaction = Transaction(
            ledger: ledger,
            amount: amount,
            date: date,
            type: .income,
            toAccount: account,
            category: category,
            note: randomIncomeNote(for: category.name)
        )
        
        modelContext.insert(transaction)
        transaction.updateAccountBalance()
    }
    
    /// 生成转账交易
    private func generateTransferTransaction(
        ledger: Ledger,
        date: Date,
        accounts: [Account]
    ) throws {
        guard accounts.count >= 2 else { return }
        
        var shuffledAccounts = accounts.shuffled()
        let fromAccount = shuffledAccounts.removeFirst()
        guard let toAccount = shuffledAccounts.first else { return }
        
        let amount = Decimal(Int.random(in: 100...5000))
        
        let transaction = Transaction(
            ledger: ledger,
            amount: amount,
            date: date,
            type: .transfer,
            fromAccount: fromAccount,
            toAccount: toAccount,
            note: "转账"
        )
        
        modelContext.insert(transaction)
        transaction.updateAccountBalance()
    }
    
    /// 生成预算
    private func generateBudgets(for ledger: Ledger) throws -> Int {
        let expenseCategories = ledger.categories.filter { $0.type == .expense && $0.parent == nil }
        guard !expenseCategories.isEmpty else { return 0 }
        
        let count = min(config.budgetCount, expenseCategories.count)
        let selectedCategories = Array(expenseCategories.shuffled().prefix(count))
        
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        
        for category in selectedCategories {
            let budgetAmount = randomBudgetAmount(for: category.name)
            
            let budget = Budget(
                ledger: ledger,
                category: category,
                amount: budgetAmount,
                period: .monthly,
                startDate: startOfMonth,
                enableRollover: Bool.random()
            )
            
            modelContext.insert(budget)
        }
        
        return count
    }
    
    // MARK: - Random Data Helpers
    
    /// 随机支出金额
    private func randomExpenseAmount(for categoryName: String) -> Decimal {
        let ranges: [String: ClosedRange<Int>] = [
            "三餐": 15...80,
            "零食": 5...50,
            "交通": 3...100,
            "日用品": 20...200,
            "衣服": 100...1000,
            "娱乐": 30...300,
            "运动": 20...200,
            "学习": 50...500,
            "住房": 1000...5000,
            "水电煤": 50...500,
            "话费网费": 50...200,
            "医疗": 50...1000,
            "美妆": 50...500,
            "电器数码": 200...5000,
            "汽车/加油": 100...500,
            "旅行": 500...5000,
            "请客送礼": 100...1000,
            "发红包": 50...500,
            "孩子": 100...1000,
            "宠物": 50...500,
            "烟酒": 30...200,
        ]
        
        let range = ranges[categoryName] ?? 10...500
        return Decimal(Int.random(in: range))
    }
    
    /// 随机收入金额
    private func randomIncomeAmount(for categoryName: String) -> Decimal {
        let ranges: [String: ClosedRange<Int>] = [
            "工资": 8000...25000,
            "奖金": 1000...10000,
            "兼职": 500...5000,
            "投资收益": 100...3000,
            "报销": 100...2000,
            "红包": 10...500,
        ]
        
        let range = ranges[categoryName] ?? 100...2000
        return Decimal(Int.random(in: range))
    }
    
    /// 随机预算金额
    private func randomBudgetAmount(for categoryName: String) -> Decimal {
        let amounts: [String: ClosedRange<Int>] = [
            "三餐": 1500...3000,
            "交通": 300...800,
            "娱乐": 500...1500,
            "购物": 500...2000,
            "住房": 2000...6000,
        ]
        
        let range = amounts[categoryName] ?? 500...2000
        return Decimal(Int.random(in: range))
    }
    
    /// 随机支出备注
    private func randomExpenseNote(for categoryName: String) -> String? {
        let notes: [String: [String]] = [
            "三餐": ["早餐", "午餐", "晚餐", "外卖", "食堂", "餐厅", nil].compactMap { $0 },
            "零食": ["奶茶", "咖啡", "水果", "甜点", nil].compactMap { $0 },
            "交通": ["地铁", "公交", "打车", "共享单车", nil].compactMap { $0 },
            "娱乐": ["电影", "KTV", "游戏", "演出", nil].compactMap { $0 },
        ]
        
        if let categoryNotes = notes[categoryName], Bool.random() {
            return categoryNotes.randomElement()
        }
        return nil
    }
    
    /// 随机收入备注
    private func randomIncomeNote(for categoryName: String) -> String? {
        let notes: [String: [String]] = [
            "工资": ["本月工资", "工资到账"],
            "奖金": ["季度奖", "年终奖", "绩效奖"],
            "投资收益": ["股票收益", "基金分红", "利息"],
        ]
        
        if let categoryNotes = notes[categoryName], Bool.random() {
            return categoryNotes.randomElement()
        }
        return nil
    }
    
    /// 在指定日期随机选择一个时间点
    private func randomTimeOnDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = Int.random(in: 7...23)
        components.minute = Int.random(in: 0...59)
        return calendar.date(from: components) ?? date
    }
    
    /// 随机账本颜色
    private func randomLedgerColor() -> String {
        let colors = [
            "#007AFF", "#34C759", "#FF9500", "#FF3B30",
            "#5856D6", "#AF52DE", "#FF2D55", "#00C7BE"
        ]
        return colors.randomElement() ?? "#007AFF"
    }
}
