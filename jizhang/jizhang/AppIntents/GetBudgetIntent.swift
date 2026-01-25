//
//  GetBudgetIntent.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import AppIntents
import Foundation
import SwiftData

/// 查询预算Intent
@available(iOS 16.0, *)
struct GetBudgetIntent: AppIntent {
    static var title: LocalizedStringResource = "查询本月预算"
    static var description: IntentDescription = IntentDescription("查询本月预算使用情况")
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // 1. 获取ModelContainer
        let appGroupIdentifier = "group.com.yourcompany.jizhang"
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
        
        // 3. 获取本月支出
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        let ledgerId = ledger.id
        let expenseType = TransactionType.expense
        
        // 简化 Predicate - 先按日期筛选
        let allThisMonth = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.date >= monthStart && transaction.date < monthEnd
            }
        )
        
        let allTransactions = try context.fetch(allThisMonth)
        
        // 在内存中筛选
        let transactions = allTransactions.filter { transaction in
            transaction.ledger?.id == ledgerId && transaction.type == expenseType
        }
        
        let monthExpense = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        
        // 4. 获取本月预算
        let ledgerIdForBudget = ledger.id
        let budgetDescriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { budget in
                budget.ledger?.id == ledgerIdForBudget
            }
        )
        
        let budgets = try context.fetch(budgetDescriptor)
        let totalBudget = budgets.reduce(Decimal(0)) { $0 + $1.amount }
        
        // 5. 构建响应
        let message: String
        if totalBudget > 0 {
            let remaining = totalBudget - monthExpense
            let percentage = Int((Double(truncating: (monthExpense / totalBudget) as NSNumber)) * 100)
            
            if remaining > 0 {
                message = "本月预算还剩 ¥\(formatAmount(remaining))，已使用\(percentage)%"
            } else {
                message = "本月预算已超支 ¥\(formatAmount(abs(remaining)))，使用了\(percentage)%"
            }
        } else {
            message = "本月支出 ¥\(formatAmount(monthExpense))，未设置预算"
        }
        
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
