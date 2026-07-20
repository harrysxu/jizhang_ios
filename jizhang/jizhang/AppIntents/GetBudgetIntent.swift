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
        let result = try ModelContainerFactory().makeContainer(mode: .production)
        let context = result.container.mainContext
        
        // 2. 获取当前账本
        guard let ledger = try await getCurrentLedger(
            context: context,
            appGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            throw IntentError.noLedger
        }
        
        let now = Date()
        let summary = try BudgetCalculator(modelContext: context)
            .summary(ledgerID: ledger.id, at: now)
        
        // 5. 构建响应
        let message: String
        if summary.totalBudget > 0 {
            let remaining = summary.remaining
            let percentage = Int(summary.progress * 100)
            
            if remaining > 0 {
                message = "本月预算还剩 ¥\(formatAmount(remaining))，已使用\(percentage)%"
            } else {
                message = "本月预算已超支 ¥\(formatAmount(abs(remaining)))，使用了\(percentage)%"
            }
        } else {
            message = "当前没有生效中的预算"
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
