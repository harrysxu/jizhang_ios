//
//  LedgerImportService.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//
//  账本导入服务 - 从JSON文件导入账本数据
//

import Foundation
import SwiftData

// MARK: - Ledger Import Service

/// 账本导入服务
@MainActor
class LedgerImportService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    /// 进度回调
    var progressHandler: ((Double, String) -> Void)?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Import Methods
    
    /// 预览导入数据（不实际导入）
    /// - Parameter data: JSON数据
    /// - Returns: 导入预览信息
    func preview(from data: Data) throws -> ImportPreview {
        let exportData = try decodeAndValidate(data)
        
        return ImportPreview(
            ledgerName: exportData.ledger.name,
            version: exportData.version,
            exportDate: exportData.exportDate,
            accountCount: exportData.accounts.count,
            categoryCount: exportData.categories.count,
            transactionCount: exportData.transactions.count,
            budgetCount: exportData.budgets.count,
            tagCount: exportData.tags.count,
            currencyCode: exportData.ledger.currencyCode
        )
    }
    
    /// 导入账本数据
    /// - Parameters:
    ///   - data: JSON数据
    ///   - newName: 可选的新账本名称（用于处理重名）
    /// - Returns: 导入的账本
    func importLedger(from data: Data, newName: String? = nil) throws -> Ledger {
        progressHandler?(0.05, "正在解析数据...")
        let exportData = try decodeAndValidate(data)
        let importContext = ModelContext(modelContext.container)
        let worker = LedgerImportService(modelContext: importContext)
        worker.progressHandler = progressHandler

        do {
            let importedID = try worker.importValidated(exportData, newName: newName)
            let descriptor = FetchDescriptor<Ledger>(
                predicate: #Predicate { $0.id == importedID }
            )
            guard let importedLedger = try modelContext.fetch(descriptor).first else {
                throw LedgerImportError.saveFailed("保存后无法重新读取账本")
            }
            return importedLedger
        } catch {
            importContext.rollback()
            throw error
        }
    }

    private func importValidated(
        _ exportData: LedgerExportData,
        newName: String?
    ) throws -> UUID {
        
        progressHandler?(0.1, "正在创建账本...")
        
        // 2. 创建新账本
        let ledgerName = newName ?? generateUniqueName(for: exportData.ledger.name)
        let newLedger = Ledger(
            name: ledgerName,
            currencyCode: exportData.ledger.currencyCode,
            colorHex: exportData.ledger.colorHex,
            iconName: exportData.ledger.iconName,
            sortOrder: getNextSortOrder(),
            isDefault: false
        )
        newLedger.ledgerDescription = exportData.ledger.ledgerDescription
        newLedger.isArchived = exportData.ledger.isArchived
        
        modelContext.insert(newLedger)
        
        progressHandler?(0.2, "正在导入账户...")
        
        // 3. 创建映射表
        var accountMap: [UUID: Account] = [:]
        var categoryMap: [UUID: Category] = [:]
        var tagMap: [UUID: Tag] = [:]
        
        // 4. 创建账户
        for accountDTO in exportData.accounts {
            let account = createAccount(from: accountDTO, ledger: newLedger)
            accountMap[accountDTO.id] = account
        }
        
        progressHandler?(0.35, "正在导入分类...")
        
        // 5. 创建分类（先创建父分类，再创建子分类）
        // 5.1 首先创建所有父分类（parentId为nil的）
        let parentCategories = exportData.categories.filter { $0.parentId == nil }
        for categoryDTO in parentCategories {
            let category = createCategory(from: categoryDTO, ledger: newLedger, parent: nil)
            categoryMap[categoryDTO.id] = category
        }
        
        // 5.2 然后创建所有子分类
        let childCategories = exportData.categories.filter { $0.parentId != nil }
        for categoryDTO in childCategories {
            let parent = categoryDTO.parentId.flatMap { categoryMap[$0] }
            let category = createCategory(from: categoryDTO, ledger: newLedger, parent: parent)
            categoryMap[categoryDTO.id] = category
        }
        
        progressHandler?(0.5, "正在导入标签...")
        
        // 6. 创建标签
        for tagDTO in exportData.tags {
            let tag = createTag(from: tagDTO, ledger: newLedger)
            tagMap[tagDTO.id] = tag
        }
        
        progressHandler?(0.65, "正在导入交易记录...")
        
        // 7. 创建交易
        let totalTransactions = exportData.transactions.count
        for (index, transactionDTO) in exportData.transactions.enumerated() {
            createTransaction(
                from: transactionDTO,
                ledger: newLedger,
                accountMap: accountMap,
                categoryMap: categoryMap,
                tagMap: tagMap
            )
            
            // 更新进度
            if totalTransactions > 0 && index % 100 == 0 {
                let transactionProgress = 0.65 + (Double(index) / Double(totalTransactions)) * 0.2
                progressHandler?(transactionProgress, "正在导入交易记录 (\(index)/\(totalTransactions))...")
            }
        }
        
        progressHandler?(0.85, "正在导入预算...")
        
        // 8. 创建预算
        for budgetDTO in exportData.budgets {
            createBudget(from: budgetDTO, ledger: newLedger, categoryMap: categoryMap)
        }
        
        progressHandler?(0.95, "正在保存数据...")
        
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw LedgerImportError.saveFailed(error.localizedDescription)
        }
        
        progressHandler?(1.0, "导入完成")
        
        return newLedger.id
    }

    private func decodeAndValidate(_ data: Data) throws -> LedgerExportData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData: LedgerExportData
        do {
            exportData = try decoder.decode(LedgerExportData.self, from: data)
        } catch {
            throw LedgerImportError.decodingFailed(error.localizedDescription)
        }

        guard exportData.version == "1.0" || exportData.version == "2.0" else {
            throw LedgerImportError.invalidVersion(exportData.version)
        }
        if exportData.version == "2.0" {
            guard let expectedChecksum = exportData.checksum else {
                throw LedgerImportError.dataCorrupted("备份缺少校验和")
            }
            let actualChecksum = try exportData.calculatedChecksum()
            guard expectedChecksum == actualChecksum else {
                throw LedgerImportError.dataCorrupted("校验和不匹配，文件可能已损坏")
            }
            let expectedManifest = BackupManifest(
                accountCount: exportData.accounts.count,
                categoryCount: exportData.categories.count,
                transactionCount: exportData.transactions.count,
                budgetCount: exportData.budgets.count,
                tagCount: exportData.tags.count
            )
            guard exportData.manifest == expectedManifest else {
                throw LedgerImportError.dataCorrupted("数据计数与清单不一致")
            }
        }

        try validateReferences(in: exportData)
        return exportData
    }

    private func validateReferences(in data: LedgerExportData) throws {
        try requireUnique(data.accounts.map(\.id), entity: "账户")
        try requireUnique(data.categories.map(\.id), entity: "分类")
        try requireUnique(data.transactions.map(\.id), entity: "交易")
        try requireUnique(data.budgets.map(\.id), entity: "预算")
        try requireUnique(data.tags.map(\.id), entity: "标签")

        let accountIDs = Set(data.accounts.map(\.id))
        let categoryIDs = Set(data.categories.map(\.id))
        let tagIDs = Set(data.tags.map(\.id))

        guard data.accounts.allSatisfy({ AccountType(rawValue: $0.type) != nil }) else {
            throw LedgerImportError.dataCorrupted("包含未知账户类型")
        }
        guard data.categories.allSatisfy({ CategoryType(rawValue: $0.type) != nil }) else {
            throw LedgerImportError.dataCorrupted("包含未知分类类型")
        }
        for category in data.categories {
            if let parentID = category.parentId {
                guard parentID != category.id, categoryIDs.contains(parentID) else {
                    throw LedgerImportError.dataCorrupted("分类父级引用无效")
                }
            }
        }

        for transaction in data.transactions {
            guard let type = TransactionType(rawValue: transaction.type) else {
                throw LedgerImportError.dataCorrupted("包含未知交易类型")
            }
            guard transaction.amount != 0,
                  transaction.tagIds.allSatisfy(tagIDs.contains),
                  transaction.categoryId.map(categoryIDs.contains) ?? true,
                  transaction.fromAccountId.map(accountIDs.contains) ?? true,
                  transaction.toAccountId.map(accountIDs.contains) ?? true else {
                throw LedgerImportError.dataCorrupted("交易包含缺失引用或无效金额")
            }
            switch type {
            case .expense:
                guard transaction.amount > 0,
                      transaction.fromAccountId != nil,
                      transaction.categoryId != nil else {
                    throw LedgerImportError.dataCorrupted("支出交易缺少账户或分类")
                }
            case .income:
                guard transaction.amount > 0,
                      transaction.fromAccountId != nil || transaction.toAccountId != nil,
                      transaction.categoryId != nil else {
                    throw LedgerImportError.dataCorrupted("收入交易缺少账户或分类")
                }
            case .transfer:
                guard transaction.amount > 0,
                      let fromID = transaction.fromAccountId,
                      let toID = transaction.toAccountId,
                      fromID != toID else {
                    throw LedgerImportError.dataCorrupted("转账交易账户引用无效")
                }
            case .adjustment:
                guard transaction.fromAccountId != nil || transaction.toAccountId != nil else {
                    throw LedgerImportError.dataCorrupted("调整交易缺少账户")
                }
            }
        }

        for budget in data.budgets {
            guard budget.amount > 0,
                  BudgetPeriod(rawValue: budget.period) != nil,
                  budget.endDate > budget.startDate,
                  budget.categoryId.map(categoryIDs.contains) == true else {
                throw LedgerImportError.dataCorrupted("预算周期、金额或分类引用无效")
            }
        }
    }

    private func requireUnique(_ ids: [UUID], entity: String) throws {
        guard Set(ids).count == ids.count else {
            throw LedgerImportError.dataCorrupted("\(entity)包含重复 ID")
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// 生成唯一的账本名称
    private func generateUniqueName(for baseName: String) -> String {
        // 检查是否存在同名账本
        let descriptor = FetchDescriptor<Ledger>()
        guard let existingLedgers = try? modelContext.fetch(descriptor) else {
            return baseName
        }
        
        let existingNames = Set(existingLedgers.map { $0.name })
        
        if !existingNames.contains(baseName) {
            return baseName
        }
        
        // 添加后缀
        var counter = 1
        var newName = "\(baseName) (\(counter))"
        while existingNames.contains(newName) {
            counter += 1
            newName = "\(baseName) (\(counter))"
        }
        
        return newName
    }
    
    /// 获取下一个排序序号
    private func getNextSortOrder() -> Int {
        let descriptor = FetchDescriptor<Ledger>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        if let maxLedger = try? modelContext.fetch(descriptor).first {
            return maxLedger.sortOrder + 1
        }
        return 0
    }
    
    /// 从DTO创建账户
    private func createAccount(from dto: AccountDTO, ledger: Ledger) -> Account {
        let accountType = AccountType(rawValue: dto.type) ?? .cash
        
        let account = Account(
            ledger: ledger,
            name: dto.name,
            type: accountType,
            balance: dto.balance,
            iconName: dto.iconName,
            colorHex: dto.colorHex,
            sortOrder: dto.sortOrder
        )
        
        // 设置可选属性
        account.creditLimit = dto.creditLimit
        account.statementDay = dto.statementDay
        account.dueDay = dto.dueDay
        account.cardNumberLast4 = dto.cardNumberLast4
        account.excludeFromTotal = dto.excludeFromTotal
        account.isArchived = dto.isArchived
        account.note = dto.note
        
        // 插入到 context 并添加到账本关系
        modelContext.insert(account)
        if ledger.accounts == nil { ledger.accounts = [] }
        ledger.accounts?.append(account)
        
        return account
    }
    
    /// 从DTO创建分类
    private func createCategory(from dto: CategoryDTO, ledger: Ledger, parent: Category?) -> Category {
        let categoryType = CategoryType(rawValue: dto.type) ?? .expense
        
        let category = Category(
            ledger: ledger,
            name: dto.name,
            type: categoryType,
            iconName: dto.iconName,
            parent: parent,
            colorHex: dto.colorHex,
            sortOrder: dto.sortOrder
        )
        
        category.isHidden = dto.isHidden
        category.isQuickSelect = dto.isQuickSelect
        
        // 插入到 context 并添加到账本关系
        modelContext.insert(category)
        if ledger.categories == nil { ledger.categories = [] }
        ledger.categories?.append(category)
        
        // 如果有父分类，添加到父分类的 children
        if let parent = parent {
            if parent.children == nil { parent.children = [] }
            parent.children?.append(category)
        }
        
        return category
    }
    
    /// 从DTO创建标签
    private func createTag(from dto: TagDTO, ledger: Ledger) -> Tag {
        let tag = Tag(
            ledger: ledger,
            name: dto.name,
            colorHex: dto.colorHex,
            sortOrder: dto.sortOrder
        )
        
        // 插入到 context 并添加到账本关系
        modelContext.insert(tag)
        if ledger.tags == nil { ledger.tags = [] }
        ledger.tags?.append(tag)
        
        return tag
    }
    
    /// 从DTO创建交易
    @discardableResult
    private func createTransaction(
        from dto: TransactionDTO,
        ledger: Ledger,
        accountMap: [UUID: Account],
        categoryMap: [UUID: Category],
        tagMap: [UUID: Tag]
    ) -> Transaction {
        let transactionType = TransactionType(rawValue: dto.type) ?? .expense
        
        // 查找关联实体
        let fromAccount = dto.fromAccountId.flatMap { accountMap[$0] }
        let toAccount = dto.toAccountId.flatMap { accountMap[$0] }
        let category = dto.categoryId.flatMap { categoryMap[$0] }
        
        let transaction = Transaction(
            ledger: ledger,
            amount: dto.amount,
            date: dto.date,
            type: transactionType,
            fromAccount: fromAccount,
            toAccount: toAccount,
            category: category,
            note: dto.note,
            payee: dto.payee
        )
        
        transaction.imageURL = dto.imageURL
        
        // 关联标签
        if !dto.tagIds.isEmpty {
            if transaction.tags == nil { transaction.tags = [] }
            for tagId in dto.tagIds {
                if let tag = tagMap[tagId] {
                    transaction.tags?.append(tag)
                    if tag.transactions == nil { tag.transactions = [] }
                    tag.transactions?.append(transaction)
                }
            }
        }
        
        // 插入到 context 并添加到账本关系
        modelContext.insert(transaction)
        if ledger.transactions == nil { ledger.transactions = [] }
        ledger.transactions?.append(transaction)
        
        // 更新账户的交易关系
        if let fromAccount = fromAccount {
            if fromAccount.outgoingTransactions == nil { fromAccount.outgoingTransactions = [] }
            fromAccount.outgoingTransactions?.append(transaction)
        }
        if let toAccount = toAccount {
            if toAccount.incomingTransactions == nil { toAccount.incomingTransactions = [] }
            toAccount.incomingTransactions?.append(transaction)
        }
        
        // 更新分类的交易关系
        if let category = category {
            if category.transactions == nil { category.transactions = [] }
            category.transactions?.append(transaction)
        }
        
        return transaction
    }
    
    /// 从DTO创建预算
    @discardableResult
    private func createBudget(
        from dto: BudgetDTO,
        ledger: Ledger,
        categoryMap: [UUID: Category]
    ) -> Budget? {
        let period = BudgetPeriod(rawValue: dto.period) ?? .monthly
        
        // 查找关联分类
        guard let categoryId = dto.categoryId,
              let category = categoryMap[categoryId] else {
            // 如果没有关联分类，跳过此预算
            return nil
        }
        
        let budget = Budget(
            ledger: ledger,
            category: category,
            amount: dto.amount,
            period: period,
            startDate: dto.startDate,
            endDate: dto.endDate,
            enableRollover: dto.enableRollover
        )
        
        budget.rolloverAmount = dto.rolloverAmount
        
        // 插入到 context 并添加到账本关系
        modelContext.insert(budget)
        if ledger.budgets == nil { ledger.budgets = [] }
        ledger.budgets?.append(budget)
        
        // 更新分类的预算关系
        if category.budgets == nil { category.budgets = [] }
        category.budgets?.append(budget)
        
        return budget
    }
}

// MARK: - Import Preview

/// 导入预览信息
struct ImportPreview {
    let ledgerName: String
    let version: String
    let exportDate: Date
    let accountCount: Int
    let categoryCount: Int
    let transactionCount: Int
    let budgetCount: Int
    let tagCount: Int
    let currencyCode: String
    
    var summary: String {
        var parts: [String] = []
        if accountCount > 0 { parts.append("\(accountCount) 个账户") }
        if categoryCount > 0 { parts.append("\(categoryCount) 个分类") }
        if transactionCount > 0 { parts.append("\(transactionCount) 笔交易") }
        if budgetCount > 0 { parts.append("\(budgetCount) 个预算") }
        if tagCount > 0 { parts.append("\(tagCount) 个标签") }
        return parts.isEmpty ? "无数据" : parts.joined(separator: "、")
    }
    
    var formattedExportDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: exportDate)
    }
}

// MARK: - Import Errors

enum LedgerImportError: LocalizedError {
    case decodingFailed(String)
    case invalidVersion(String)
    case dataCorrupted(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .decodingFailed(let reason):
            return "数据解析失败: \(reason)"
        case .invalidVersion(let version):
            return "不支持的文件版本: \(version)"
        case .dataCorrupted(let reason):
            return "数据损坏: \(reason)"
        case .saveFailed(let reason):
            return "保存失败: \(reason)"
        }
    }
}
