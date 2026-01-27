//
//  LedgerExportService.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//
//  账本导出服务 - 将账本数据导出为JSON格式
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Custom UTType

extension UTType {
    /// 自定义账本备份文件类型
    static var jizhangBackup: UTType {
        UTType(exportedAs: "com.jizhang.ledger-backup", conformingTo: .json)
    }
}

// MARK: - Export Data Structure

/// 顶层导出数据结构
struct LedgerExportData: Codable {
    /// 导出格式版本号
    let version: String
    /// 导出时间
    let exportDate: Date
    /// App版本
    let appVersion: String
    /// 账本数据
    let ledger: LedgerDTO
    /// 账户列表
    let accounts: [AccountDTO]
    /// 分类列表
    let categories: [CategoryDTO]
    /// 交易列表
    let transactions: [TransactionDTO]
    /// 预算列表
    let budgets: [BudgetDTO]
    /// 标签列表
    let tags: [TagDTO]
    
    init(
        version: String = "1.0",
        exportDate: Date = Date(),
        appVersion: String = "1.0.0",
        ledger: LedgerDTO,
        accounts: [AccountDTO],
        categories: [CategoryDTO],
        transactions: [TransactionDTO],
        budgets: [BudgetDTO],
        tags: [TagDTO]
    ) {
        self.version = version
        self.exportDate = exportDate
        self.appVersion = appVersion
        self.ledger = ledger
        self.accounts = accounts
        self.categories = categories
        self.transactions = transactions
        self.budgets = budgets
        self.tags = tags
    }
}

// MARK: - Ledger DTO

struct LedgerDTO: Codable {
    let id: UUID
    let name: String
    let currencyCode: String
    let createdAt: Date
    let colorHex: String
    let iconName: String
    let isArchived: Bool
    let sortOrder: Int
    let ledgerDescription: String?
    
    init(from ledger: Ledger) {
        self.id = ledger.id
        self.name = ledger.name
        self.currencyCode = ledger.currencyCode
        self.createdAt = ledger.createdAt
        self.colorHex = ledger.colorHex
        self.iconName = ledger.iconName
        self.isArchived = ledger.isArchived
        self.sortOrder = ledger.sortOrder
        self.ledgerDescription = ledger.ledgerDescription
    }
}

// MARK: - Account DTO

struct AccountDTO: Codable {
    let id: UUID
    let name: String
    let type: String // AccountType.rawValue
    let balance: Decimal
    let creditLimit: Decimal?
    let statementDay: Int?
    let dueDay: Int?
    let cardNumberLast4: String?
    let colorHex: String
    let iconName: String
    let excludeFromTotal: Bool
    let isArchived: Bool
    let createdAt: Date
    let sortOrder: Int
    let note: String?
    
    init(from account: Account) {
        self.id = account.id
        self.name = account.name
        self.type = account.type.rawValue
        self.balance = account.balance
        self.creditLimit = account.creditLimit
        self.statementDay = account.statementDay
        self.dueDay = account.dueDay
        self.cardNumberLast4 = account.cardNumberLast4
        self.colorHex = account.colorHex
        self.iconName = account.iconName
        self.excludeFromTotal = account.excludeFromTotal
        self.isArchived = account.isArchived
        self.createdAt = account.createdAt
        self.sortOrder = account.sortOrder
        self.note = account.note
    }
}

// MARK: - Category DTO

struct CategoryDTO: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let type: String // CategoryType.rawValue
    let colorHex: String
    let sortOrder: Int
    let isHidden: Bool
    let createdAt: Date
    let parentId: UUID? // 父分类ID引用
    
    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.iconName = category.iconName
        self.type = category.type.rawValue
        self.colorHex = category.colorHex
        self.sortOrder = category.sortOrder
        self.isHidden = category.isHidden
        self.createdAt = category.createdAt
        self.parentId = category.parent?.id
    }
}

// MARK: - Transaction DTO

struct TransactionDTO: Codable {
    let id: UUID
    let amount: Decimal
    let date: Date
    let type: String // TransactionType.rawValue
    let note: String?
    let payee: String?
    let imageURL: String?
    let createdAt: Date
    let modifiedAt: Date
    let fromAccountId: UUID?
    let toAccountId: UUID?
    let categoryId: UUID?
    let tagIds: [UUID]
    
    init(from transaction: Transaction) {
        self.id = transaction.id
        self.amount = transaction.amount
        self.date = transaction.date
        self.type = transaction.type.rawValue
        self.note = transaction.note
        self.payee = transaction.payee
        self.imageURL = transaction.imageURL
        self.createdAt = transaction.createdAt
        self.modifiedAt = transaction.modifiedAt
        self.fromAccountId = transaction.fromAccount?.id
        self.toAccountId = transaction.toAccount?.id
        self.categoryId = transaction.category?.id
        self.tagIds = transaction.tags.map { $0.id }
    }
}

// MARK: - Budget DTO

struct BudgetDTO: Codable {
    let id: UUID
    let amount: Decimal
    let period: String // BudgetPeriod.rawValue
    let startDate: Date
    let endDate: Date
    let enableRollover: Bool
    let rolloverAmount: Decimal
    let createdAt: Date
    let categoryId: UUID?
    
    init(from budget: Budget) {
        self.id = budget.id
        self.amount = budget.amount
        self.period = budget.period.rawValue
        self.startDate = budget.startDate
        self.endDate = budget.endDate
        self.enableRollover = budget.enableRollover
        self.rolloverAmount = budget.rolloverAmount
        self.createdAt = budget.createdAt
        self.categoryId = budget.category?.id
    }
}

// MARK: - Tag DTO

struct TagDTO: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let sortOrder: Int
    let createdAt: Date
    
    init(from tag: Tag) {
        self.id = tag.id
        self.name = tag.name
        self.colorHex = tag.colorHex
        self.sortOrder = tag.sortOrder
        self.createdAt = tag.createdAt
    }
}

// MARK: - Ledger Export Service

/// 账本导出服务
@MainActor
class LedgerExportService {
    
    // MARK: - Properties
    
    /// 进度回调
    var progressHandler: ((Double, String) -> Void)?
    
    // MARK: - Export Methods
    
    /// 导出账本为JSON数据
    /// - Parameter ledger: 要导出的账本
    /// - Returns: JSON格式的Data
    func export(ledger: Ledger) throws -> Data {
        progressHandler?(0.1, "正在准备导出数据...")
        
        // 创建账本DTO
        let ledgerDTO = LedgerDTO(from: ledger)
        progressHandler?(0.2, "正在导出账户...")
        
        // 创建账户DTOs
        let accountDTOs = ledger.accounts.map { AccountDTO(from: $0) }
        progressHandler?(0.3, "正在导出分类...")
        
        // 创建分类DTOs
        let categoryDTOs = ledger.categories.map { CategoryDTO(from: $0) }
        progressHandler?(0.5, "正在导出交易记录...")
        
        // 创建交易DTOs
        let transactionDTOs = ledger.transactions.map { TransactionDTO(from: $0) }
        progressHandler?(0.7, "正在导出预算...")
        
        // 创建预算DTOs
        let budgetDTOs = ledger.budgets.map { BudgetDTO(from: $0) }
        progressHandler?(0.8, "正在导出标签...")
        
        // 创建标签DTOs
        let tagDTOs = ledger.tags.map { TagDTO(from: $0) }
        progressHandler?(0.9, "正在生成文件...")
        
        // 创建导出数据
        let exportData = LedgerExportData(
            version: "1.0",
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            ledger: ledgerDTO,
            accounts: accountDTOs,
            categories: categoryDTOs,
            transactions: transactionDTOs,
            budgets: budgetDTOs,
            tags: tagDTOs
        )
        
        // 编码为JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(exportData)
        progressHandler?(1.0, "导出完成")
        
        return data
    }
    
    /// 生成导出文件名
    /// - Parameter ledger: 账本
    /// - Returns: 文件名（不含扩展名）
    func generateFileName(for ledger: Ledger) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        // 清理账本名称中的特殊字符
        let cleanName = ledger.name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        
        return "\(cleanName)_\(dateString)"
    }
    
    /// 获取导出文件的临时URL
    /// - Parameters:
    ///   - ledger: 账本
    ///   - data: 导出数据
    /// - Returns: 临时文件URL
    func createTemporaryFile(for ledger: Ledger, data: Data) throws -> URL {
        let fileName = generateFileName(for: ledger)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension("jizhang")
        
        try data.write(to: tempURL)
        return tempURL
    }
}

// MARK: - Export Statistics

extension LedgerExportService {
    /// 获取导出数据的统计信息
    struct ExportStatistics {
        let accountCount: Int
        let categoryCount: Int
        let transactionCount: Int
        let budgetCount: Int
        let tagCount: Int
        
        var summary: String {
            var parts: [String] = []
            if accountCount > 0 { parts.append("\(accountCount) 个账户") }
            if categoryCount > 0 { parts.append("\(categoryCount) 个分类") }
            if transactionCount > 0 { parts.append("\(transactionCount) 笔交易") }
            if budgetCount > 0 { parts.append("\(budgetCount) 个预算") }
            if tagCount > 0 { parts.append("\(tagCount) 个标签") }
            return parts.isEmpty ? "无数据" : parts.joined(separator: "、")
        }
    }
    
    /// 获取账本的导出统计信息
    func getStatistics(for ledger: Ledger) -> ExportStatistics {
        return ExportStatistics(
            accountCount: ledger.accounts.count,
            categoryCount: ledger.categories.count,
            transactionCount: ledger.transactions.count,
            budgetCount: ledger.budgets.count,
            tagCount: ledger.tags.count
        )
    }
}

// MARK: - Export Errors

enum LedgerExportError: LocalizedError {
    case encodingFailed(String)
    case fileCreationFailed(String)
    case ledgerNotFound
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let reason):
            return "数据编码失败: \(reason)"
        case .fileCreationFailed(let reason):
            return "文件创建失败: \(reason)"
        case .ledgerNotFound:
            return "未找到账本"
        }
    }
}
