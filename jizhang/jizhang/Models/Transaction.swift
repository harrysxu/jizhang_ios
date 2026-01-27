//
//  Transaction.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

// MARK: - TransactionType Enum

/// 交易类型
enum TransactionType: String, Codable {
    case expense = "expense"        // 支出
    case income = "income"          // 收入
    case transfer = "transfer"      // 转账
    case adjustment = "adjustment"  // 余额调整
    
    var displayName: String {
        switch self {
        case .expense: return "支出"
        case .income: return "收入"
        case .transfer: return "转账"
        case .adjustment: return "调整"
        }
    }
    
    var icon: String {
        switch self {
        case .expense: return "arrow.down.circle.fill"
        case .income: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .adjustment: return "slider.horizontal.3"
        }
    }
    
    /// Phosphor 图标名称
    var phosphorIcon: String {
        switch self {
        case .expense: return "arrowCircleDown"
        case .income: return "arrowCircleUp"
        case .transfer: return "arrowsLeftRight"
        case .adjustment: return "slidersHorizontal"
        }
    }
}

// MARK: - Transaction Model

@Model
final class Transaction {
    // MARK: - Properties
    
    @Attribute(.unique) var id: UUID
    
    /// 金额
    var amount: Decimal
    
    /// 交易日期
    var date: Date
    
    /// 交易类型
    var type: TransactionType
    
    /// 备注
    var note: String?
    
    /// 商家/收款人
    var payee: String?
    
    /// 图片URL
    var imageURL: String?
    
    /// 创建时间
    var createdAt: Date
    
    /// 修改时间
    var modifiedAt: Date
    
    // MARK: - Relationships
    
    /// 所属账本
    var ledger: Ledger?
    
    /// 来源账户(支出/转账)
    var fromAccount: Account?
    
    /// 目标账户(收入/转账)
    var toAccount: Account?
    
    /// 分类
    var category: Category?
    
    /// 标签
    var tags: [Tag]
    
    // MARK: - Initialization
    
    init(
        ledger: Ledger,
        amount: Decimal,
        date: Date = Date(),
        type: TransactionType,
        fromAccount: Account? = nil,
        toAccount: Account? = nil,
        category: Category? = nil,
        note: String? = nil,
        payee: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.type = type
        self.note = note
        self.payee = payee
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.ledger = ledger
        self.fromAccount = fromAccount
        self.toAccount = toAccount
        self.category = category
        self.tags = []
    }
}

// MARK: - Computed Properties

extension Transaction {
    /// 显示用的金额(带符号)
    var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let amountString = formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
        
        switch type {
        case .expense:
            return "-\(amountString)"
        case .income:
            return "+\(amountString)"
        case .transfer, .adjustment:
            return amountString
        }
    }
    
    /// 主要账户(用于显示)
    var primaryAccount: Account? {
        switch type {
        case .expense:
            return fromAccount
        case .income:
            return toAccount
        case .transfer:
            return fromAccount
        case .adjustment:
            return toAccount
        }
    }
}

// MARK: - Business Logic

extension Transaction {
    /// 更新账户余额
    func updateAccountBalance() {
        switch type {
        case .expense:
            // 支出: 扣减fromAccount
            if let account = fromAccount {
                account.balance -= amount
            }
            
        case .income:
            // 收入: 增加toAccount
            if let account = toAccount {
                account.balance += amount
            }
            
        case .transfer:
            // 转账: 扣减fromAccount, 增加toAccount
            if let from = fromAccount {
                from.balance -= amount
            }
            if let to = toAccount {
                to.balance += amount
            }
            
        case .adjustment:
            // 调整: 直接设置toAccount余额
            // 此逻辑在Account.adjustBalance中处理
            break
        }
        
        modifiedAt = Date()
    }
    
    /// 撤销账户余额变更
    func revertAccountBalance() {
        switch type {
        case .expense:
            if let account = fromAccount {
                account.balance += amount
            }
            
        case .income:
            if let account = toAccount {
                account.balance -= amount
            }
            
        case .transfer:
            if let from = fromAccount {
                from.balance += amount
            }
            if let to = toAccount {
                to.balance -= amount
            }
            
        case .adjustment:
            break
        }
    }
}
