//
//  TestHelpers.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import Foundation
import SwiftData
@testable import jizhang

/// 测试辅助工具类
@MainActor
class TestHelpers {
    
    // MARK: - Model Container Setup
    
    /// 创建内存数据库容器（用于测试）
    static func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Ledger.self,
            Account.self,
            Category.self,
            Transaction.self,
            Budget.self,
            Tag.self
        ])
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    // MARK: - Ledger Creation
    
    /// 创建测试账本
    static func createTestLedger(
        name: String = "测试账本",
        currencyCode: String = "CNY",
        context: ModelContext
    ) -> Ledger {
        let ledger = Ledger(
            name: name,
            currencyCode: currencyCode,
            isDefault: false
        )
        context.insert(ledger)
        return ledger
    }
    
    /// 创建完整的测试账本（包含默认账户和分类）
    static func createFullTestLedger(
        name: String = "测试账本",
        context: ModelContext
    ) -> Ledger {
        let ledger = createTestLedger(name: name, context: context)
        
        // 创建默认账户
        let cash = Account(
            ledger: ledger,
            name: "现金",
            type: .cash,
            balance: 1000
        )
        context.insert(cash)
        
        let checking = Account(
            ledger: ledger,
            name: "银行卡",
            type: .checking,
            balance: 5000
        )
        context.insert(checking)
        
        // 创建默认分类
        createDefaultCategories(for: ledger, context: context)
        
        return ledger
    }
    
    // MARK: - Category Creation
    
    /// 创建默认分类（简化版）
    static func createDefaultCategories(for ledger: Ledger, context: ModelContext) {
        // 支出分类
        let food = Category(
            ledger: ledger,
            name: "餐饮",
            type: .expense,
            iconName: "fork.knife"
        )
        context.insert(food)
        
        let breakfast = Category(
            ledger: ledger,
            name: "早餐",
            type: .expense,
            iconName: "fork.knife",
            parent: food
        )
        context.insert(breakfast)
        
        let transport = Category(
            ledger: ledger,
            name: "交通",
            type: .expense,
            iconName: "car.fill"
        )
        context.insert(transport)
        
        let shopping = Category(
            ledger: ledger,
            name: "购物",
            type: .expense,
            iconName: "cart.fill"
        )
        context.insert(shopping)
        
        // 收入分类
        let salary = Category(
            ledger: ledger,
            name: "工资",
            type: .income,
            iconName: "banknote.fill"
        )
        context.insert(salary)
        
        let investment = Category(
            ledger: ledger,
            name: "投资",
            type: .income,
            iconName: "chart.line.uptrend.xyaxis"
        )
        context.insert(investment)
    }
    
    // MARK: - Account Creation
    
    /// 创建测试账户
    static func createTestAccount(
        ledger: Ledger,
        name: String = "测试账户",
        type: AccountType = .cash,
        balance: Decimal = 0,
        context: ModelContext
    ) -> Account {
        let account = Account(
            ledger: ledger,
            name: name,
            type: type,
            balance: balance
        )
        context.insert(account)
        return account
    }
    
    /// 创建信用卡账户
    static func createCreditCardAccount(
        ledger: Ledger,
        name: String = "信用卡",
        balance: Decimal = 0,
        creditLimit: Decimal = 10000,
        context: ModelContext
    ) -> Account {
        let account = Account(
            ledger: ledger,
            name: name,
            type: .creditCard,
            balance: balance
        )
        account.creditLimit = creditLimit
        account.statementDay = 5
        account.dueDay = 25
        context.insert(account)
        return account
    }
    
    // MARK: - Transaction Creation
    
    /// 创建测试交易
    static func createTestTransaction(
        ledger: Ledger,
        amount: Decimal,
        date: Date = Date(),
        type: TransactionType,
        fromAccount: Account? = nil,
        toAccount: Account? = nil,
        category: jizhang.Category? = nil,
        note: String? = nil,
        context: ModelContext
    ) -> Transaction {
        let transaction = Transaction(
            ledger: ledger,
            amount: amount,
            date: date,
            type: type,
            fromAccount: fromAccount,
            toAccount: toAccount,
            category: category,
            note: note
        )
        context.insert(transaction)
        return transaction
    }
    
    // MARK: - Budget Creation
    
    /// 创建测试预算
    static func createTestBudget(
        ledger: Ledger,
        category: jizhang.Category,
        amount: Decimal,
        period: BudgetPeriod = .monthly,
        context: ModelContext
    ) -> Budget {
        let budget = Budget(
            ledger: ledger,
            category: category,
            amount: amount,
            period: period
        )
        context.insert(budget)
        return budget
    }
    
    // MARK: - Tag Creation
    
    /// 创建测试标签
    static func createTestTag(
        ledger: Ledger,
        name: String,
        context: ModelContext
    ) -> Tag {
        let tag = Tag(
            ledger: ledger,
            name: name
        )
        context.insert(tag)
        return tag
    }
    
    // MARK: - Date Helpers
    
    /// 创建指定日期
    static func date(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// 今天
    static var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    /// 昨天
    static var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
    }
    
    /// 本月第一天
    static var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// 上月第一天
    static var lastMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
    }
    
    // MARK: - Cleanup
    
    /// 清理测试数据
    static func cleanup(context: ModelContext) throws {
        // 删除所有数据
        try context.delete(model: Transaction.self)
        try context.delete(model: Budget.self)
        try context.delete(model: Tag.self)
        try context.delete(model: Category.self)
        try context.delete(model: Account.self)
        try context.delete(model: Ledger.self)
        
        try context.save()
    }
}
