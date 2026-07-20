//
//  AddTransactionViewModel.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class AddTransactionViewModel {
    // MARK: - Published Properties
    
    var type: TransactionType = .expense {
        didSet {
            if oldValue != type {
                handleTypeChange()
            }
        }
    }
    var amount: Decimal = 0
    var date: Date = Date()
    var selectedAccount: Account?
    var selectedToAccount: Account? // 仅用于转账
    var selectedCategory: Category?
    var selectedTags: Set<Tag> = []
    var note: String = ""
    
    // MARK: - Sheet State
    
    var showAccountPicker = false
    var showToAccountPicker = false
    var showCategoryPicker = false
    var showDatePicker = false
    var showTimePicker = false
    var showNotePicker = false
    var showTagPicker = false
    
    // MARK: - Alert State
    
    var showErrorAlert = false
    var errorMessage = ""
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    private var appState: AppState?
    private var recommendationService: SmartRecommendationService?
    private var transactionService: (any TransactionServicing)?
    
    // MARK: - Smart Defaults
    
    var suggestedAmounts: [Decimal] = []
    var showQuickMode: Bool = true
    
    // MARK: - Quick Select Categories
    
    /// 获取当前类型的快速选择分类（最多显示两行，每行约4-5个）
    var quickSelectCategories: [Category] {
        guard let ledger = appState?.currentLedger else { return [] }
        
        let categoryType: CategoryType = type == .expense ? .expense : .income
        
        // 获取标记为快速选择的分类，按排序顺序排列
        let categories = (ledger.categories ?? [])
            .filter { $0.type == categoryType && $0.isQuickSelect && !$0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
        
        // 最多返回10个（约两行）
        return Array(categories.prefix(10))
    }
    
    /// 选择快速分类
    func selectQuickCategory(_ category: Category) {
        selectedCategory = category
        HapticManager.light()
    }
    
    // MARK: - Initialization
    
    init() {}
    
    func configure(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
        self.recommendationService = SmartRecommendationService(modelContext: modelContext)
        self.transactionService = appState.transactionService
        
        // 应用智能推荐
        applySmartDefaults()
    }
    
    /// 应用智能默认值
    func applySmartDefaults() {
        guard let ledger = appState?.currentLedger,
              let service = recommendationService else { return }
        
        // 推荐账户
        if selectedAccount == nil {
            // 优先使用记忆的账户
            if let lastAccountId = UserPreferences.shared.getLastAccount(for: type),
               let account = (ledger.accounts ?? []).first(where: { $0.id == lastAccountId }) {
                selectedAccount = account
            } else {
                // 否则使用智能推荐
                selectedAccount = service.suggestAccount(for: type, ledger: ledger)
            }
        }
        
        // 推荐分类(仅非转账)
        if type != .transfer && selectedCategory == nil {
            selectDefaultCategory()
        }
        
        // 更新建议金额
        updateSuggestedAmounts()
    }
    
    /// 处理类型变化
    private func handleTypeChange() {
        // 清空当前选中的分类和转入账户
        selectedCategory = nil
        selectedToAccount = nil
        
        // 转账不需要分类，其他类型需要自动选择默认分类
        if type != .transfer {
            selectDefaultCategory()
        }
    }
    
    /// 选择默认分类
    private func selectDefaultCategory() {
        guard let ledger = appState?.currentLedger else { return }
        
        // 优先使用记忆的分类
        if let lastCategoryId = UserPreferences.shared.getLastCategory(for: type),
           let category = (ledger.categories ?? []).first(where: { $0.id == lastCategoryId }) {
            selectedCategory = category
            return
        }
        
        // 根据类型获取对应的分类列表
        let categoryType: CategoryType = type == .expense ? .expense : .income
        let categories = (ledger.categories ?? []).filter { $0.type == categoryType }
        
        // 选中第一个分类（优先选择子分类的第一个，如果没有则选父分类第一个）
        let childCategories = categories.filter { $0.parent != nil }.sorted { $0.sortOrder < $1.sortOrder }
        if !childCategories.isEmpty {
            selectedCategory = childCategories.first
        } else {
            let parentCategories = categories.filter { $0.parent == nil }.sorted { $0.sortOrder < $1.sortOrder }
            selectedCategory = parentCategories.first
        }
    }
    
    /// 更新建议金额
    private func updateSuggestedAmounts() {
        guard let service = recommendationService else { return }
        suggestedAmounts = service.suggestAmount(for: selectedCategory, account: selectedAccount)
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        guard amount > 0 else { return false }
        guard selectedAccount != nil else { return false }
        
        if type == .transfer {
            // 转账需要转入账户，且不能是同一账户
            return selectedToAccount != nil && selectedAccount?.id != selectedToAccount?.id
        }
        
        // 支出和收入需要选择分类
        return selectedCategory != nil
    }
    
    var validationError: String? {
        if amount <= 0 {
            return "请输入金额"
        }
        if selectedAccount == nil {
            return type == .transfer ? "请选择转出账户" : "请选择账户"
        }
        
        if type == .transfer {
            if selectedToAccount == nil {
                return "请选择转入账户"
            }
            if selectedAccount?.id == selectedToAccount?.id {
                return "转出和转入账户不能相同"
            }
            // 检查转出账户余额是否足够
            if let fromAccount = selectedAccount {
                if fromAccount.balance < 0 {
                    return "转出账户余额为负，无法转账"
                }
                if fromAccount.balance < amount {
                    return "转出账户余额不足"
                }
            }
        } else {
            if selectedCategory == nil {
                return "请选择分类"
            }
        }
        return nil
    }
    
    // MARK: - Actions
    
    func saveTransaction() async throws -> TransactionReceipt {
        guard let appState = appState,
              let transactionService,
              let ledger = appState.currentLedger else {
            throw TransactionError.missingDependencies
        }
        
        // 验证
        if let error = validationError {
            errorMessage = error
            showErrorAlert = true
            throw TransactionError.validationFailed(error)
        }
        
        guard let selectedAccount else {
            throw TransactionError.validationFailed("请选择账户")
        }

        let draft = TransactionDraft(
            ledgerID: ledger.id,
            type: type,
            amount: amount,
            date: date,
            primaryAccountID: selectedAccount.id,
            destinationAccountID: selectedToAccount?.id,
            categoryID: selectedCategory?.id,
            tagIDs: selectedTags.map(\.id),
            note: note.isEmpty ? nil : note,
            payee: nil
        )
        let receipt = try transactionService.create(draft)
        
        // 记忆用户选择
        UserPreferences.shared.rememberLastAccount(id: selectedAccount.id, for: type)
        if let categoryId = selectedCategory?.id {
            UserPreferences.shared.rememberLastCategory(id: categoryId, for: type)
        }
        
        // 触发震动反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        return receipt
    }

    func repeatLastTransaction() {
        guard let modelContext,
              let ledgerID = appState?.currentLedger?.id,
              let latest = try? modelContext.fetch(
                FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
              ).first(where: { $0.ledger?.id == ledgerID && $0.type != .adjustment }) else {
            return
        }
        type = latest.type
        amount = latest.amount
        date = Date()
        selectedAccount = latest.primaryAccount
        selectedToAccount = latest.type == .transfer ? latest.toAccount : nil
        selectedCategory = latest.category
        selectedTags = Set(latest.tags ?? [])
        note = latest.note ?? ""
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        amount = 0
        date = Date()
        selectedCategory = nil
        selectedToAccount = nil
        selectedTags = []
        note = ""
        // 保留账户和类型选择
    }
    
    var displayCategory: String {
        guard let category = selectedCategory else {
            return "请选择"
        }
        
        if let parent = category.parent {
            return "\(parent.name) - \(category.name)"
        } else {
            return category.name
        }
    }
}

// MARK: - Transaction Error

enum TransactionError: LocalizedError {
    case missingDependencies
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingDependencies:
            return "系统错误,请重试"
        case .validationFailed(let message):
            return message
        }
    }
}
