//
//  DataRepository.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

/// 数据访问层
actor DataRepository {
    // MARK: - Properties
    
    static let shared = DataRepository()
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    private init(modelContext: ModelContext? = nil) {
        // 如果没有提供modelContext,创建一个新的
        if let context = modelContext {
            self.modelContext = context
        } else {
            let schema = Schema([
                Ledger.self,
                Account.self,
                Category.self,
                Transaction.self,
                Budget.self,
                Tag.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            do {
                let container = try ModelContainer(for: schema, configurations: [configuration])
                self.modelContext = ModelContext(container)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }
    
    // MARK: - Transaction Operations
    
    /// 创建交易
    func createTransaction(
        ledger: Ledger,
        type: TransactionType,
        amount: Decimal,
        date: Date = Date(),
        fromAccount: Account? = nil,
        toAccount: Account? = nil,
        category: Category? = nil,
        note: String? = nil,
        payee: String? = nil
    ) throws -> Transaction {
        let transaction = Transaction(
            ledger: ledger,
            amount: amount,
            date: date,
            type: type,
            fromAccount: fromAccount,
            toAccount: toAccount,
            category: category,
            note: note,
            payee: payee
        )
        
        modelContext.insert(transaction)
        transaction.updateAccountBalance()
        
        try modelContext.save()
        return transaction
    }
    
    /// 更新交易
    func updateTransaction(_ transaction: Transaction) throws {
        transaction.modifiedAt = Date()
        try modelContext.save()
    }
    
    /// 删除交易
    func deleteTransaction(_ transaction: Transaction) throws {
        // 先撤销余额变更
        transaction.revertAccountBalance()
        
        // 删除交易
        modelContext.delete(transaction)
        try modelContext.save()
    }
    
    /// 获取交易列表
    func fetchTransactions(
        for ledger: Ledger? = nil,
        type: TransactionType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 50
    ) throws -> [Transaction] {
        var descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        // 构建过滤条件
        var predicates: [Predicate<Transaction>] = []
        
        if let ledger = ledger {
            let ledgerId = ledger.id
            predicates.append(#Predicate { $0.ledger?.id == ledgerId })
        }
        
        if let type = type {
            predicates.append(#Predicate { $0.type == type })
        }
        
        if let startDate = startDate {
            predicates.append(#Predicate { $0.date >= startDate })
        }
        
        if let endDate = endDate {
            predicates.append(#Predicate { $0.date <= endDate })
        }
        
        // 组合所有过滤条件
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(nil) { result, predicate in
                if let result = result {
                    return #Predicate<Transaction> { transaction in
                        result.evaluate(transaction) && predicate.evaluate(transaction)
                    }
                }
                return predicate
            }
        }
        
        descriptor.fetchLimit = limit
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Ledger Operations
    
    /// 创建账本
    func createLedger(name: String, currencyCode: String = "CNY") throws -> Ledger {
        let ledger = Ledger(name: name, currencyCode: currencyCode)
        modelContext.insert(ledger)
        try modelContext.save()
        return ledger
    }
    
    /// 获取所有账本
    func fetchLedgers() throws -> [Ledger] {
        let descriptor = FetchDescriptor<Ledger>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Account Operations
    
    /// 创建账户
    func createAccount(
        ledger: Ledger,
        name: String,
        type: AccountType,
        balance: Decimal = 0
    ) throws -> Account {
        let account = Account(
            ledger: ledger,
            name: name,
            type: type,
            balance: balance
        )
        modelContext.insert(account)
        try modelContext.save()
        return account
    }
    
    /// 获取账户列表
    func fetchAccounts(for ledger: Ledger) throws -> [Account] {
        let ledgerId = ledger.id
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.ledger?.id == ledgerId },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Category Operations
    
    /// 创建分类
    func createCategory(
        ledger: Ledger,
        name: String,
        type: CategoryType,
        parent: Category? = nil
    ) throws -> Category {
        let category = Category(
            ledger: ledger,
            name: name,
            type: type,
            parent: parent
        )
        modelContext.insert(category)
        try modelContext.save()
        return category
    }
    
    /// 获取分类列表
    func fetchCategories(
        for ledger: Ledger,
        type: CategoryType? = nil,
        parentOnly: Bool = false
    ) throws -> [Category] {
        let ledgerId = ledger.id
        var predicates: [Predicate<Category>] = [
            #Predicate { $0.ledger?.id == ledgerId }
        ]
        
        if let type = type {
            predicates.append(#Predicate { $0.type == type })
        }
        
        if parentOnly {
            predicates.append(#Predicate { $0.parent == nil })
        }
        
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Budget Operations
    
    /// 创建预算
    func createBudget(
        ledger: Ledger,
        category: Category,
        amount: Decimal,
        period: BudgetPeriod = .monthly
    ) throws -> Budget {
        let budget = Budget(
            ledger: ledger,
            category: category,
            amount: amount,
            period: period
        )
        modelContext.insert(budget)
        try modelContext.save()
        return budget
    }
    
    /// 获取预算列表
    func fetchBudgets(for ledger: Ledger) throws -> [Budget] {
        let ledgerId = ledger.id
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.ledger?.id == ledgerId }
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Statistics
    
    /// 计算总资产
    func calculateTotalAssets(for ledger: Ledger) async -> Decimal {
        return ledger.totalAssets
    }
    
    /// 计算期间收支
    func calculatePeriodSummary(
        for ledger: Ledger,
        startDate: Date,
        endDate: Date
    ) async throws -> (income: Decimal, expense: Decimal) {
        let transactions = try fetchTransactions(
            for: ledger,
            startDate: startDate,
            endDate: endDate,
            limit: 10000
        )
        
        let income = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expense = transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        return (income, expense)
    }
}
