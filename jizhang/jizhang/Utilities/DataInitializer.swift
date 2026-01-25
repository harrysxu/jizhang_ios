//
//  DataInitializer.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

/// 数据初始化器 - 用于创建默认数据和测试数据
struct DataInitializer {
    // MARK: - Properties
    
    let modelContext: ModelContext
    
    // MARK: - Public Methods
    
    /// 初始化默认账本和数据
    func initializeDefaultData() throws -> Ledger {
        // 创建默认账本
        let ledger = Ledger(name: "日常账本")
        modelContext.insert(ledger)
        
        // 创建默认分类
        ledger.createDefaultCategories()
        
        // 创建默认账户
        createDefaultAccounts(for: ledger)
        
        try modelContext.save()
        return ledger
    }
    
    /// 创建测试数据(用于开发和演示)
    func createTestData(for ledger: Ledger) throws {
        // 获取账户和分类
        guard let cashAccount = ledger.accounts.first(where: { $0.type == .cash }),
              let categories = getCategoriesForTest(from: ledger) else {
            return
        }
        
        // 生成最近30天的测试交易
        let calendar = Calendar.current
        let today = Date()
        
        // 测试交易数据
        let testTransactions: [(days: Int, category: String, amount: Decimal, note: String)] = [
            // 今天
            (0, "午餐", 45.0, "工作餐"),
            (0, "咖啡", 32.0, "星巴克"),
            
            // 昨天
            (1, "地铁", 6.0, "通勤"),
            (1, "晚餐", 68.0, "聚餐"),
            (1, "电影", 65.0, "周末休闲"),
            
            // 前天
            (2, "早餐", 15.0, "豆浆油条"),
            (2, "午餐", 42.0, "外卖"),
            (2, "地铁", 6.0, "通勤"),
            
            // 3天前
            (3, "日用品", 120.0, "超市购物"),
            (3, "话费", 50.0, "手机充值"),
            
            // 一周前
            (7, "服饰", 299.0, "买衣服"),
            (7, "午餐", 38.0, "快餐"),
            
            // 两周前
            (14, "房租", 2500.0, "月租"),
            (14, "水电", 180.0, "水电费"),
            
            // 收入
            (5, "工资", 8000.0, "本月工资")
        ]
        
        for testData in testTransactions {
            guard let date = calendar.date(byAdding: .day, value: -testData.days, to: today) else {
                continue
            }
            
            // 查找对应分类
            let category = categories.first { $0.name == testData.category }
            
            // 确定交易类型和账户
            let type: TransactionType = testData.category == "工资" ? .income : .expense
            let fromAccount: Account? = type == .expense ? cashAccount : nil
            let toAccount: Account? = type == .income ? cashAccount : nil
            
            let transaction = Transaction(
                ledger: ledger,
                amount: testData.amount,
                date: date,
                type: type,
                fromAccount: fromAccount,
                toAccount: toAccount,
                category: category,
                note: testData.note
            )
            
            modelContext.insert(transaction)
            transaction.updateAccountBalance()
        }
        
        try modelContext.save()
    }
    
    // MARK: - Private Methods
    
    /// 创建默认账户
    private func createDefaultAccounts(for ledger: Ledger) {
        let accounts: [(String, AccountType, Decimal)] = [
            ("现金", .cash, 1000.0),
            ("工行储蓄卡", .checking, 5000.0),
            ("招行信用卡", .creditCard, 0.0)
        ]
        
        for (index, accountData) in accounts.enumerated() {
            let account = Account(
                ledger: ledger,
                name: accountData.0,
                type: accountData.1,
                balance: accountData.2,
                sortOrder: index
            )
            
            // 如果是信用卡,设置信用额度
            if accountData.1 == .creditCard {
                account.creditLimit = 10000
                account.statementDay = 5
                account.dueDay = 23
            }
            
            ledger.accounts.append(account)
        }
    }
    
    /// 获取测试用的分类
    private func getCategoriesForTest(from ledger: Ledger) -> [Category]? {
        // 查找二级分类
        let categoryNames = ["早餐", "午餐", "晚餐", "咖啡", "地铁", "电影", "日用品", "话费", "服饰", "房租", "水电", "工资"]
        
        return ledger.categories.filter { categoryNames.contains($0.name) }
    }
}

// MARK: - Extension

extension Ledger {
    /// 检查是否需要初始化数据
    var needsInitialization: Bool {
        accounts.isEmpty || categories.isEmpty
    }
}
