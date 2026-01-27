//
//  Account.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

// MARK: - AccountType Enum

/// 账户类型
enum AccountType: String, Codable, CaseIterable {
    case cash = "cash"                      // 现金
    case checking = "checking"              // 借记卡/储蓄卡
    case creditCard = "credit_card"         // 信用卡
    case eWallet = "e_wallet"              // 电子钱包
    
    var displayName: String {
        switch self {
        case .cash: return "现金"
        case .checking: return "储蓄卡"
        case .creditCard: return "信用卡"
        case .eWallet: return "电子钱包"
        }
    }
    
    var defaultIcon: String {
        switch self {
        case .cash: return "banknote.fill"
        case .checking: return "creditcard.fill"
        case .creditCard: return "creditcard.circle.fill"
        case .eWallet: return "iphone"
        }
    }
    
    /// 是否为资产账户
    var isAsset: Bool {
        switch self {
        case .cash, .checking, .eWallet:
            return true
        case .creditCard:
            return false
        }
    }
    
    /// 是否支持信用额度
    var supportsCreditLimit: Bool {
        self == .creditCard
    }
}

// MARK: - Account Model

@Model
final class Account {
    // MARK: - Properties
    
    /// 唯一标识符 (CloudKit不支持unique约束，但UUID本身保证唯一性)
    var id: UUID
    
    /// 账户名称
    var name: String
    
    /// 账户类型
    var type: AccountType
    
    /// 当前余额
    var balance: Decimal
    
    /// 信用额度(仅信用卡)
    var creditLimit: Decimal?
    
    /// 账单日(仅信用卡, 1-31)
    var statementDay: Int?
    
    /// 还款日(仅信用卡, 1-31)
    var dueDay: Int?
    
    /// 卡号后四位(可选)
    var cardNumberLast4: String?
    
    /// 主题颜色
    var colorHex: String
    
    /// 图标名称
    var iconName: String
    
    /// 是否排除在总资产统计外
    var excludeFromTotal: Bool
    
    /// 是否归档
    var isArchived: Bool
    
    /// 创建时间
    var createdAt: Date
    
    /// 排序顺序
    var sortOrder: Int
    
    /// 备注
    var note: String?
    
    // MARK: - Relationships
    
    /// 所属账本
    var ledger: Ledger?
    
    /// 作为来源账户的交易 (CloudKit要求关系必须为可选)
    @Relationship(inverse: \Transaction.fromAccount)
    var outgoingTransactions: [Transaction]?
    
    /// 作为目标账户的交易 (CloudKit要求关系必须为可选)
    @Relationship(inverse: \Transaction.toAccount)
    var incomingTransactions: [Transaction]?
    
    // MARK: - Initialization
    
    init(
        ledger: Ledger,
        name: String,
        type: AccountType,
        balance: Decimal = 0,
        iconName: String? = nil,
        colorHex: String = "#007AFF",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.balance = balance
        self.iconName = iconName ?? type.defaultIcon
        self.colorHex = colorHex
        self.excludeFromTotal = false
        self.isArchived = false
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.ledger = ledger
        self.outgoingTransactions = nil
        self.incomingTransactions = nil
    }
}

// MARK: - Computed Properties

extension Account {
    /// 可用余额(信用卡为剩余额度)
    var availableBalance: Decimal {
        if type == .creditCard, let limit = creditLimit {
            return limit + balance // balance为负数
        }
        return balance
    }
    
}

// MARK: - Business Logic

extension Account {
    /// 调整余额(用于对账)
    func adjustBalance(to newBalance: Decimal, note: String = "余额调整") -> Transaction {
        let difference = newBalance - balance
        
        let transaction = Transaction(
            ledger: ledger!,
            amount: abs(difference),
            date: Date(),
            type: .adjustment,
            toAccount: self,
            note: note
        )
        
        self.balance = newBalance
        return transaction
    }
    
}
