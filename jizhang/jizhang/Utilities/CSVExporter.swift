//
//  CSVExporter.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation

struct CSVExporter {
    
    // MARK: - Export Transactions
    
    /// 导出交易数据为CSV格式字符串
    static func export(transactions: [Transaction]) -> String {
        // 添加 BOM 以支持 Excel 正确识别 UTF-8
        var csv = "\u{FEFF}日期,类型,分类,账户,金额,备注\r\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: transaction.date)
            let type = typeString(for: transaction.type)
            let category = transaction.category?.name ?? "未分类"
            let account = getAccountName(for: transaction)
            let amount = amountString(transaction.amount)
            let note = escapeCSV(transaction.note ?? "")
            
            csv += "\(escapeCSV(date)),\(escapeCSV(type)),\(escapeCSV(category)),\(escapeCSV(account)),\(amount),\(note)\r\n"
        }
        
        return csv
    }
    
    /// 导出交易数据为CSV文件，返回文件URL
    static func exportToFile(transactions: [Transaction], fileName: String? = nil) -> URL? {
        let csvContent = export(transactions: transactions)
        
        // 生成文件名
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let finalFileName = fileName ?? "流水导出_\(timestamp).csv"
        
        // 获取临时目录
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(finalFileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("CSV文件写入失败: \(error)")
            return nil
        }
    }
    
    // MARK: - Export Report Summary
    
    /// 导出统计报表数据
    static func exportReport(
        totalIncome: Decimal,
        totalExpense: Decimal,
        netAmount: Decimal,
        categoryData: [CategoryData],
        reportType: ReportType,
        startDate: Date,
        endDate: Date
    ) -> String {
        var csv = "\u{FEFF}"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 报表期间
        csv += "统计报表\r\n"
        csv += "报表期间,\(escapeCSV(dateFormatter.string(from: startDate) + " 至 " + dateFormatter.string(from: endDate)))\r\n\r\n"
        
        // 汇总数据
        csv += "汇总数据\r\n"
        csv += "收入,\(amountString(totalIncome))\r\n"
        csv += "支出,\(amountString(totalExpense))\r\n"
        csv += "结余,\(amountString(netAmount))\r\n\r\n"
        
        // 分类明细
        csv += "\(reportType == .income ? "收入" : "支出")分类明细\r\n"
        csv += "分类,金额,占比\r\n"
        
        for item in categoryData {
            let percentage = String(format: "%.1f%%", item.percentage * 100)
            csv += "\(escapeCSV(item.name)),\(amountString(item.amount)),\(percentage)\r\n"
        }
        
        return csv
    }
    
    /// 导出统计报表为文件
    static func exportReportToFile(
        totalIncome: Decimal,
        totalExpense: Decimal,
        netAmount: Decimal,
        categoryData: [CategoryData],
        reportType: ReportType,
        startDate: Date,
        endDate: Date,
        fileName: String? = nil
    ) -> URL? {
        let csvContent = exportReport(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            netAmount: netAmount,
            categoryData: categoryData,
            reportType: reportType,
            startDate: startDate,
            endDate: endDate
        )
        
        // 生成文件名
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let finalFileName = fileName ?? "统计报表_\(timestamp).csv"
        
        // 获取临时目录
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(finalFileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("CSV文件写入失败: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
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
    
    private static func getAccountName(for transaction: Transaction) -> String {
        switch transaction.type {
        case .expense:
            return transaction.fromAccount?.name ?? "未知账户"
        case .income:
            return (transaction.toAccount ?? transaction.fromAccount)?.name ?? "未知账户"
        case .transfer:
            let from = transaction.fromAccount?.name ?? "未知"
            let to = transaction.toAccount?.name ?? "未知"
            return "\(from) → \(to)"
        case .adjustment:
            return (transaction.toAccount ?? transaction.fromAccount)?.name ?? "未知账户"
        }
    }
    
    private static func escapeCSV(_ string: String) -> String {
        let protected = protectFromFormulaInjection(string)
        if protected.contains(",") || protected.contains("\"") ||
            protected.contains("\n") || protected.contains("\r") {
            let escaped = protected.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return protected
    }

    private static func protectFromFormulaInjection(_ string: String) -> String {
        guard let first = string.drop(while: { $0 == " " }).first,
              "=+-@\t\r".contains(first) else {
            return string
        }
        return "'" + string
    }

    private static func amountString(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
}
