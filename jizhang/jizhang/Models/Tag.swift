//
//  Tag.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftData

@Model
final class Tag {
    // MARK: - Properties
    
    /// 唯一标识符 (CloudKit不支持unique约束，但UUID本身保证唯一性)
    var id: UUID = UUID()
    
    /// 标签名称
    var name: String = ""
    
    /// 颜色
    var colorHex: String = "#007AFF"
    
    /// 排序顺序
    var sortOrder: Int = 0
    
    /// 创建时间
    var createdAt: Date = Date()
    
    // MARK: - Relationships
    
    /// 所属账本
    var ledger: Ledger?
    
    /// 关联的交易 (CloudKit要求关系必须为可选，且必须有反向关系)
    var transactions: [Transaction]?
    
    // MARK: - Initialization
    
    init(
        ledger: Ledger,
        name: String,
        colorHex: String = "#007AFF",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.ledger = ledger
        self.transactions = nil
    }
}

