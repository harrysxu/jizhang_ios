//
//  AmountInputField.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//

import SwiftUI

/// 金额输入组件 - 使用系统数字键盘
struct AmountInputField: View {
    @Binding var amount: Decimal
    @FocusState.Binding var isFocused: Bool
    
    let fontSize: CGFloat
    let currencyCode: String
    
    @State private var textValue: String = ""
    
    init(
        amount: Binding<Decimal>,
        isFocused: FocusState<Bool>.Binding,
        fontSize: CGFloat = 56,
        currencyCode: String = "CNY"
    ) {
        self._amount = amount
        self._isFocused = isFocused
        self.fontSize = fontSize
        self.currencyCode = currencyCode
    }
    
    private var currencySymbol: String {
        switch currencyCode {
        case "CNY": return "¥"
        case "USD": return "$"
        case "EUR": return "€"
        case "JPY": return "¥"
        case "GBP": return "£"
        default: return currencyCode
        }
    }
    
    private var currencyName: String {
        switch currencyCode {
        case "CNY": return "人民币"
        case "USD": return "美元"
        case "EUR": return "欧元"
        case "JPY": return "日元"
        case "GBP": return "英镑"
        default: return currencyCode
        }
    }
    
    var body: some View {
        VStack(spacing: Spacing.s) {
            // 提示文字
            Text("请输入金额（\(currencyName) \(currencySymbol)）")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 金额输入框
            TextField("0", text: $textValue)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .minimumScaleFactor(0.5)
                .onChange(of: textValue) { oldValue, newValue in
                    handleTextChange(newValue)
                }
                .onAppear {
                    // 初始化文本值
                    if amount > 0 {
                        textValue = formatForEditing(amount)
                    }
                }
                .onChange(of: amount) { oldValue, newValue in
                    // 当外部修改 amount 时同步更新文本
                    if !isFocused {
                        textValue = newValue > 0 ? formatForEditing(newValue) : ""
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        // 过滤非法字符，只保留数字和小数点
        var filtered = newValue.filter { $0.isNumber || $0 == "." }
        
        // 确保只有一个小数点
        let decimalCount = filtered.filter { $0 == "." }.count
        if decimalCount > 1 {
            // 保留第一个小数点，移除后续的
            var foundFirst = false
            filtered = String(filtered.compactMap { char -> Character? in
                if char == "." {
                    if foundFirst {
                        return nil
                    }
                    foundFirst = true
                }
                return char
            })
        }
        
        // 限制小数位数为2位
        if let dotIndex = filtered.firstIndex(of: ".") {
            let decimals = filtered[filtered.index(after: dotIndex)...]
            if decimals.count > 2 {
                filtered = String(filtered.prefix(filtered.distance(from: filtered.startIndex, to: dotIndex) + 3))
            }
        }
        
        // 限制整数部分长度（最多7位整数）
        if let dotIndex = filtered.firstIndex(of: ".") {
            let integerPart = filtered[..<dotIndex]
            if integerPart.count > 7 {
                let start = filtered.index(filtered.startIndex, offsetBy: 7)
                filtered = String(filtered[..<start]) + String(filtered[dotIndex...])
            }
        } else if filtered.count > 7 {
            filtered = String(filtered.prefix(7))
        }
        
        // 更新文本（如果被过滤了）
        if filtered != newValue {
            textValue = filtered
        }
        
        // 转换为 Decimal
        if filtered.isEmpty {
            amount = 0
        } else if let decimal = Decimal(string: filtered) {
            amount = decimal
        }
    }
    
    private func formatForEditing(_ value: Decimal) -> String {
        let nsNumber = value as NSDecimalNumber
        let doubleValue = nsNumber.doubleValue
        
        // 如果是整数，不显示小数点
        if doubleValue == floor(doubleValue) {
            return String(Int(doubleValue))
        }
        
        // 否则显示实际的小数
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        
        return formatter.string(from: nsNumber) ?? "0"
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var amount: Decimal = 0
        @FocusState private var isFocused: Bool
        
        var body: some View {
            VStack(spacing: 20) {
                AmountInputField(
                    amount: $amount,
                    isFocused: $isFocused
                )
                .padding()
                
                Text("当前金额: \(amount as NSDecimalNumber)")
                
                Button("聚焦") {
                    isFocused = true
                }
            }
        }
    }
    
    return PreviewWrapper()
}
