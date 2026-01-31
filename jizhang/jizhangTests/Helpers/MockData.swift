//
//  MockData.swift
//  jizhangTests
//
//  Created by Test Suite on 2026/1/31.
//

import Foundation
import SwiftData
@testable import jizhang

/// 模拟数据生成器
@MainActor
class MockData {
    
    // MARK: - Batch Creation
    
    /// 批量创建交易
    static func createMultipleTransactions(
        ledger: Ledger,
        account: Account,
        category: jizhang.Category,
        count: Int,
        type: TransactionType = .expense,
        startDate: Date = Date(),
        context: ModelContext
    ) -> [Transaction] {
        var transactions: [Transaction] = []
        
        for i in 0..<count {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: startDate) ?? startDate
            let amount = Decimal(Double.random(in: 10...100))
            
            let transaction = Transaction(
                ledger: ledger,
                amount: amount,
                date: date,
                type: type,
                fromAccount: type == .expense ? account : nil,
                toAccount: type == .income ? account : nil,
                category: category,
                note: "测试交易 \(i + 1)"
            )
            
            context.insert(transaction)
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    /// 创建本月交易数据（模拟真实使用场景）
    static func createMonthlyTransactions(
        ledger: Ledger,
        accounts: [Account],
        categories: [jizhang.Category],
        context: ModelContext
    ) -> [Transaction] {
        guard let cashAccount = accounts.first,
              let foodCategory = categories.first(where: { $0.name == "餐饮" }),
              let transportCategory = categories.first(where: { $0.name == "交通" })
        else {
            return []
        }
        
        var transactions: [Transaction] = []
        let today = Date()
        
        // 本月每天的餐饮支出
        for day in 1...15 {
            let date = Calendar.current.date(byAdding: .day, value: -day, to: today) ?? today
            
            // 早餐
            let breakfast = Transaction(
                ledger: ledger,
                amount: Decimal(Double.random(in: 15...25)),
                date: date,
                type: .expense,
                fromAccount: cashAccount,
                category: foodCategory,
                note: "早餐"
            )
            context.insert(breakfast)
            transactions.append(breakfast)
            
            // 午餐
            let lunch = Transaction(
                ledger: ledger,
                amount: Decimal(Double.random(in: 25...50)),
                date: date,
                type: .expense,
                fromAccount: cashAccount,
                category: foodCategory,
                note: "午餐"
            )
            context.insert(lunch)
            transactions.append(lunch)
            
            // 交通
            if day % 2 == 0 {
                let transport = Transaction(
                    ledger: ledger,
                    amount: Decimal(Double.random(in: 10...30)),
                    date: date,
                    type: .expense,
                    fromAccount: cashAccount,
                    category: transportCategory,
                    note: "交通"
                )
                context.insert(transport)
                transactions.append(transport)
            }
        }
        
        return transactions
    }
    
    /// 创建大量测试数据（性能测试用）
    static func createLargeDataset(
        ledger: Ledger,
        transactionCount: Int = 1000,
        context: ModelContext
    ) {
        // 创建账户
        let accounts = (1...5).map { i in
            let account = Account(
                ledger: ledger,
                name: "账户\(i)",
                type: AccountType.allCases.randomElement() ?? .cash,
                balance: Decimal(Double.random(in: 1000...10000))
            )
            context.insert(account)
            return account
        }
        
        // 创建分类
        let categories = ["餐饮", "交通", "购物", "娱乐", "医疗"].map { name in
            let category = Category(
                ledger: ledger,
                name: name,
                type: .expense,
                iconName: "folder.fill"
            )
            context.insert(category)
            return category
        }
        
        // 创建交易
        let today = Date()
        for i in 0..<transactionCount {
            let daysAgo = i % 365
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            
            let transaction = Transaction(
                ledger: ledger,
                amount: Decimal(Double.random(in: 1...1000)),
                date: date,
                type: .expense,
                fromAccount: accounts.randomElement(),
                category: categories.randomElement(),
                note: "交易\(i)"
            )
            context.insert(transaction)
        }
    }
    
    // MARK: - Scenario Data
    
    /// 创建预算超支场景
    static func createOverBudgetScenario(
        ledger: Ledger,
        context: ModelContext
    ) -> (budget: Budget, transactions: [Transaction]) {
        let account = TestHelpers.createTestAccount(
            ledger: ledger,
            name: "现金",
            balance: 10000,
            context: context
        )
        
        let category = Category(
            ledger: ledger,
            name: "餐饮",
            type: .expense,
            iconName: "fork.knife"
        )
        context.insert(category)
        
        let budget = Budget(
            ledger: ledger,
            category: category,
            amount: 500,
            period: .monthly
        )
        context.insert(budget)
        
        // 创建超过预算的交易
        var transactions: [Transaction] = []
        for i in 0..<10 {
            let transaction = Transaction(
                ledger: ledger,
                amount: 60, // 总计600，超过500的预算
                date: Date(),
                type: .expense,
                fromAccount: account,
                category: category,
                note: "餐饮支出\(i)"
            )
            context.insert(transaction)
            transactions.append(transaction)
        }
        
        return (budget, transactions)
    }
    
    /// 创建转账场景
    static func createTransferScenario(
        ledger: Ledger,
        context: ModelContext
    ) -> (fromAccount: Account, toAccount: Account, transaction: Transaction) {
        let fromAccount = TestHelpers.createTestAccount(
            ledger: ledger,
            name: "银行卡",
            type: .checking,
            balance: 5000,
            context: context
        )
        
        let toAccount = TestHelpers.createTestAccount(
            ledger: ledger,
            name: "现金",
            type: .cash,
            balance: 500,
            context: context
        )
        
        let transaction = Transaction(
            ledger: ledger,
            amount: 1000,
            date: Date(),
            type: .transfer,
            fromAccount: fromAccount,
            toAccount: toAccount,
            note: "取现"
        )
        context.insert(transaction)
        
        return (fromAccount, toAccount, transaction)
    }
    
    /// 创建信用卡还款场景
    static func createCreditCardScenario(
        ledger: Ledger,
        context: ModelContext
    ) -> (creditCard: Account, transactions: [Transaction]) {
        let creditCard = TestHelpers.createCreditCardAccount(
            ledger: ledger,
            name: "信用卡",
            balance: -3000, // 欠款3000
            creditLimit: 10000,
            context: context
        )
        
        let category = Category(
            ledger: ledger,
            name: "购物",
            type: .expense,
            iconName: "cart.fill"
        )
        context.insert(category)
        
        var transactions: [Transaction] = []
        
        // 信用卡消费
        for i in 0..<5 {
            let transaction = Transaction(
                ledger: ledger,
                amount: 600,
                date: Date(),
                type: .expense,
                fromAccount: creditCard,
                category: category,
                note: "信用卡消费\(i)"
            )
            context.insert(transaction)
            transactions.append(transaction)
        }
        
        return (creditCard, transactions)
    }
}
