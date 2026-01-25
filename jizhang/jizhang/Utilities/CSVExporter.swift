//
//  CSVExporter.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation

struct CSVExporter {
    /// 导出交易数据为CSV格式
    static func export(transactions: [Transaction]) -> String {
        var csv = "日期,类型,分类,账户,金额,备注\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: transaction.date)
            let type = typeString(for: transaction.type)
            let category = transaction.category?.name ?? "未分类"
            let account = transaction.primaryAccount?.name ?? "未知账户"
            let amount = transaction.amount.formatted(.number.precision(.fractionLength(2)))
            let note = escapeCSV(transaction.note ?? "")
            
            csv += "\(date),\(type),\(category),\(account),\(amount),\(note)\n"
        }
        
        return csv
    }
    
    private static func typeString(for type: TransactionType) -> String {
        switch type {
        case .expense:
            return "支出"
        case .income:
            return "收入"
        case .transfer:
            return "转账"
        case .adjustment:
            return "调整"
        }
    }
    
    private static func escapeCSV(_ string: String) -> String {
        // 如果包含逗号、引号或换行,需要用引号包裹并转义引号
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }
}
