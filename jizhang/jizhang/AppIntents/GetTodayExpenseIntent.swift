//
//  GetTodayExpenseIntent.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import AppIntents
import Foundation
import SwiftData

/// 查询今日支出Intent
@available(iOS 16.0, *)
struct GetTodayExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "查询今日支出"
    static var description: IntentDescription = IntentDescription("查询今天花了多少钱")
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // 1. 获取ModelContainer
        let appGroupIdentifier = "group.com.xxl.jizhang"
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw IntentError.dataAccessFailed
        }
        
        let storeURL = containerURL.appendingPathComponent("jizhang.sqlite")
        
        let schema = Schema([
            Ledger.self,
            Account.self,
            Category.self,
            Transaction.self,
            Budget.self,
            Tag.self
        ])
        
        let config = ModelConfiguration(schema: schema, url: storeURL)
        let modelContainer = try ModelContainer(for: schema, configurations: [config])
        let context = modelContainer.mainContext
        
        // 2. 获取当前账本
        guard let ledger = try await getCurrentLedger(context: context, appGroupIdentifier: appGroupIdentifier) else {
            throw IntentError.noLedger
        }
        
        // 3. 计算今日支出
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        
        let ledgerId = ledger.id
        let expenseType = TransactionType.expense
        
        // 先获取所有今天的交易
        let allToday = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.date >= todayStart && transaction.date < todayEnd
            }
        )
        
        let allTransactions = try context.fetch(allToday)
        
        // 在内存中筛选
        let transactions = allTransactions.filter { transaction in
            transaction.ledger?.id == ledgerId && transaction.type == expenseType
        }
        
        let totalExpense = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        
        // 4. 构建响应
        let formattedAmount = formatAmount(totalExpense)
        let message = totalExpense > 0
            ? "今天花了 ¥\(formattedAmount)，共\(transactions.count)笔"
            : "今天还没有支出记录"
        
        let dialog = IntentDialog(stringLiteral: message)
        
        return .result(value: message, dialog: dialog)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentLedger(context: ModelContext, appGroupIdentifier: String) async throws -> Ledger? {
        let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        if let ledgerIdString = sharedDefaults?.string(forKey: "currentLedgerId"),
           let ledgerId = UUID(uuidString: ledgerIdString) {
            let descriptor = FetchDescriptor<Ledger>(
                predicate: #Predicate { $0.id == ledgerId }
            )
            return try context.fetch(descriptor).first
        }
        
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor).first
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let nsNumber = amount as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: nsNumber) ?? "0.00"
    }
}
