//
//  Decimal+Extensions.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation

extension Decimal {
    /// 格式化为货币字符串
    /// - Parameters:
    ///   - currencyCode: 货币代码(默认CNY)
    ///   - showSymbol: 是否显示货币符号
    /// - Returns: 格式化后的字符串
    func toCurrencyString(currencyCode: String = "CNY", showSymbol: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        
        let amountString = formatter.string(from: self as NSDecimalNumber) ?? "0.00"
        
        if showSymbol {
            let symbol = currencySymbol(for: currencyCode)
            return "\(symbol)\(amountString)"
        }
        
        return amountString
    }
    
    /// 格式化为紧凑货币字符串(如: 1.2万, 3.5k)
    func toCompactCurrencyString(currencyCode: String = "CNY") -> String {
        let absValue = abs(self)
        let symbol = currencySymbol(for: currencyCode)
        let sign = self < 0 ? "-" : ""
        
        if absValue >= 10000 {
            let wan = absValue / 10000
            return "\(sign)\(symbol)\(String(format: "%.1f", Double(truncating: wan as NSNumber)))万"
        } else if absValue >= 1000 {
            let k = absValue / 1000
            return "\(sign)\(symbol)\(String(format: "%.1f", Double(truncating: k as NSNumber)))k"
        } else {
            return toCurrencyString(currencyCode: currencyCode)
        }
    }
    
    /// 获取货币符号
    private func currencySymbol(for code: String) -> String {
        switch code {
        case "CNY": return "¥"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "HKD": return "HK$"
        default: return "¥"
        }
    }
}
