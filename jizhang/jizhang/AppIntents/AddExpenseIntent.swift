//
//  AddExpenseIntent.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import AppIntents
import Foundation
import SwiftData

/// 快速记录支出Intent
@available(iOS 16.0, *)
struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "记一笔支出"
    static var description: IntentDescription = IntentDescription("快速记录一笔支出交易")
    
    /// 金额
    @Parameter(title: "金额", description: "支出金额")
    var amount: Double
    
    /// 分类 (可选)
    @Parameter(title: "分类", description: "支出分类", default: nil)
    var categoryName: String?
    
    /// 备注 (可选)
    @Parameter(title: "备注", description: "交易备注", default: nil)
    var note: String?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // 1. 验证金额
        guard amount > 0 else {
            throw IntentError.invalidAmount
        }
        
        // 转换 Double 到 Decimal
        let decimalAmount = Decimal(amount)
        
        // 使用与主 App 相同的无损容器工厂；打开失败时绝不创建替代空库。
        let result = try ModelContainerFactory().makeContainer(mode: .production)
        let context = result.container.mainContext
        
        // 3. 获取当前账本
        guard let ledger = try await getCurrentLedger(
            context: context,
            appGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            throw IntentError.noLedger
        }
        
        // 4. 获取默认账户
        guard let account = try await getDefaultAccount(context: context, ledger: ledger) else {
            throw IntentError.noAccount
        }
        
        // 5. 查找分类 (如果指定了)
        var category: Category? = nil
        if let categoryName = categoryName {
            category = try await findCategory(context: context, ledger: ledger, name: categoryName)
        }
        
        // 如果没有指定或找不到分类，使用默认分类
        if category == nil {
            category = try await getDefaultExpenseCategory(context: context, ledger: ledger)
        }
        
        guard let category else { throw IntentError.noCategory }
        let service = TransactionService(
            modelContext: context,
            reloadWidgets: refreshAllWidgets
        )
        _ = try service.create(TransactionDraft(
            ledgerID: ledger.id,
            type: .expense,
            amount: decimalAmount,
            date: Date(),
            primaryAccountID: account.id,
            destinationAccountID: nil,
            categoryID: category.id,
            tagIDs: [],
            note: note,
            payee: nil
        ))
        
        // 10. 返回结果
        let message = "已记录支出 ¥\(amount)"
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
        
        // 获取第一个非归档账本
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor).first
    }
    
    private func getDefaultAccount(context: ModelContext, ledger: Ledger) async throws -> Account? {
        let ledgerId = ledger.id
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { account in
                account.ledger?.id == ledgerId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor).first
    }
    
    private func findCategory(context: ModelContext, ledger: Ledger, name: String) async throws -> Category? {
        let ledgerId = ledger.id
        let expenseType = CategoryType.expense
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.ledger?.id == ledgerId &&
                category.name.contains(name) &&
                category.type == expenseType
            }
        )
        return try context.fetch(descriptor).first
    }
    
    private func getDefaultExpenseCategory(context: ModelContext, ledger: Ledger) async throws -> Category? {
        let ledgerId = ledger.id
        let expenseType = CategoryType.expense
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.ledger?.id == ledgerId &&
                category.type == expenseType
            },
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        return try context.fetch(descriptor).first
    }
}

// MARK: - Intent Errors

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    case noLedger
    case noAccount
    case dataAccessFailed
    case noCategory
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidAmount:
            return "金额必须大于0"
        case .noLedger:
            return "未找到账本，请先在App中创建账本"
        case .noAccount:
            return "未找到账户，请先在App中创建账户"
        case .dataAccessFailed:
            return "数据访问失败"
        case .noCategory:
            return "未找到支出分类，请先在App中创建分类"
        }
    }
}
