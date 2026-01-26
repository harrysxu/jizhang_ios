//
//  CalculatorKeyboard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

// MARK: - Calculator Button Type

enum CalculatorButton: Hashable {
    case number(Int)
    case decimal
    case delete
    case clear
    case add
    case subtract
    case equals
    
    var title: String {
        switch self {
        case .number(let n): return "\(n)"
        case .decimal: return "."
        case .delete: return "⌫"
        case .clear: return "C"
        case .add: return "+"
        case .subtract: return "-"
        case .equals: return "="
        }
    }
    
    var icon: String? {
        switch self {
        case .delete: return "delete.left"
        default: return nil
        }
    }
}

// MARK: - Calculator Keyboard View

struct CalculatorKeyboard: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var amount: Decimal
    let onConfirm: () -> Void // 确认回调
    let isValid: Bool // 是否可确认
    
    @State private var hasDecimalPoint = false
    @State private var decimalPlaces = 0
    @State private var previousAmount: Decimal = 0
    @State private var currentOperation: CalculatorButton?
    
    private let buttons: [[CalculatorButton]] = [
        [.number(7), .number(8), .number(9), .delete],
        [.number(4), .number(5), .number(6), .add],
        [.number(1), .number(2), .number(3), .subtract],
        [.decimal, .number(0), .clear, .equals]
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 金额显示
                AmountDisplay(amount: $amount)
                    .padding(.vertical, Spacing.l)
                
                Divider()
                
                // 计算器按钮区域
                VStack(spacing: Spacing.s) {
                    ForEach(0..<buttons.count, id: \.self) { rowIndex in
                        HStack(spacing: Spacing.s) {
                            ForEach(buttons[rowIndex], id: \.self) { button in
                                CalculatorButtonView(
                                    button: button,
                                    amount: $amount,
                                    hasDecimalPoint: $hasDecimalPoint,
                                    decimalPlaces: $decimalPlaces,
                                    previousAmount: $previousAmount,
                                    currentOperation: $currentOperation
                                )
                            }
                        }
                    }
                    
                    // 确认按钮 (参考UI标准: 红色保存按钮)
                    Button(action: {
                        HapticManager.saveSuccess()
                        onConfirm()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("完成")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(isValid ? Color.expenseRed : Color.gray.opacity(0.5))
                        )
                    }
                    .disabled(!isValid)
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(Spacing.m)
            }
            .navigationTitle("输入金额")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onChange(of: amount) { oldValue, newValue in
                updateDecimalState()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func updateDecimalState() {
        let amountString = "\(amount)"
        if amountString.contains(".") {
            hasDecimalPoint = true
            if let decimalIndex = amountString.firstIndex(of: ".") {
                decimalPlaces = amountString.distance(from: amountString.index(after: decimalIndex), to: amountString.endIndex)
            }
        } else {
            hasDecimalPoint = false
            decimalPlaces = 0
        }
    }
}

// MARK: - Calculator Button View

struct CalculatorButtonView: View {
    let button: CalculatorButton
    @Binding var amount: Decimal
    @Binding var hasDecimalPoint: Bool
    @Binding var decimalPlaces: Int
    @Binding var previousAmount: Decimal
    @Binding var currentOperation: CalculatorButton?
    
    var body: some View {
        Button {
            triggerHaptic()
            handleTap()
        } label: {
            Group {
                if let icon = button.icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                } else {
                    Text(button.title)
                        .font(.system(size: 26, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(buttonBackground)
            )
            .foregroundColor(buttonForeground)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var buttonBackground: Color {
        switch button {
        case .add, .subtract, .equals:
            return Color.blue.opacity(0.1)
        case .clear:
            return Color.orange.opacity(0.1)
        default:
            return Color(.systemGray6)
        }
    }
    
    private var buttonForeground: Color {
        switch button {
        case .add, .subtract, .equals:
            return .blue
        case .clear:
            return .orange
        default:
            return .primary
        }
    }
    
    private func handleTap() {
        switch button {
        case .number(let n):
            appendNumber(n)
        case .decimal:
            appendDecimal()
        case .delete:
            deleteLastDigit()
        case .clear:
            clearAmount()
        case .add:
            handleOperation(.add)
        case .subtract:
            handleOperation(.subtract)
        case .equals:
            calculateResult()
        }
    }
    
    private func handleOperation(_ operation: CalculatorButton) {
        // 如果已有操作，先计算结果
        if currentOperation != nil {
            calculateResult()
        }
        
        // 保存当前金额和操作
        previousAmount = amount
        currentOperation = operation
        
        // 重置金额输入状态，准备输入下一个数字
        amount = 0
        hasDecimalPoint = false
        decimalPlaces = 0
    }
    
    private func calculateResult() {
        guard let operation = currentOperation else { return }
        
        let result: Decimal
        switch operation {
        case .add:
            result = previousAmount + amount
        case .subtract:
            result = previousAmount - amount
        default:
            result = amount
        }
        
        // 限制在合理范围内
        if result >= 0 && result <= 9999999 {
            amount = result
        }
        
        // 重置操作状态
        previousAmount = 0
        currentOperation = nil
        hasDecimalPoint = false
        decimalPlaces = 0
    }
    
    private func appendNumber(_ n: Int) {
        if hasDecimalPoint {
            // 小数模式:最多2位小数
            if decimalPlaces < 2 {
                let divisor = NSDecimalNumber(decimal: 10).raising(toPower: decimalPlaces + 1).decimalValue
                let newAmount = amount + Decimal(n) / divisor
                if newAmount < 9999999 {
                    amount = newAmount
                    decimalPlaces += 1
                }
            }
        } else {
            // 整数模式
            let newAmount = amount * 10 + Decimal(n)
            if newAmount < 9999999 {
                amount = newAmount
            }
        }
    }
    
    private func appendDecimal() {
        if !hasDecimalPoint && amount < 9999999 {
            hasDecimalPoint = true
            decimalPlaces = 0
        }
    }
    
    private func deleteLastDigit() {
        if hasDecimalPoint && decimalPlaces > 0 {
            // 删除小数位
            let multiplier = NSDecimalNumber(decimal: 10).raising(toPower: decimalPlaces).decimalValue
            let truncated = NSDecimalNumber(decimal: amount * multiplier)
                .rounding(accordingToBehavior: NSDecimalNumberHandler(
                    roundingMode: .down,
                    scale: 0,
                    raiseOnExactness: false,
                    raiseOnOverflow: false,
                    raiseOnUnderflow: false,
                    raiseOnDivideByZero: false
                ))
            amount = truncated.decimalValue / multiplier
            decimalPlaces -= 1
            
            if decimalPlaces == 0 {
                hasDecimalPoint = false
            }
        } else if hasDecimalPoint && decimalPlaces == 0 {
            // 删除小数点
            hasDecimalPoint = false
        } else {
            // 删除整数位
            amount = NSDecimalNumber(decimal: amount / 10)
                .rounding(accordingToBehavior: NSDecimalNumberHandler(
                    roundingMode: .down,
                    scale: 0,
                    raiseOnExactness: false,
                    raiseOnOverflow: false,
                    raiseOnUnderflow: false,
                    raiseOnDivideByZero: false
                ))
                .decimalValue
        }
    }
    
    private func clearAmount() {
        amount = 0
        hasDecimalPoint = false
        decimalPlaces = 0
        previousAmount = 0
        currentOperation = nil
    }
    
    private func triggerHaptic() {
        // 使用HapticManager提供不同操作的反馈
        switch button {
        case .equals:
            HapticManager.medium()
        case .clear:
            HapticManager.heavy()
        default:
            HapticManager.light()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        AmountDisplay(amount: .constant(123.45))
        
        CalculatorKeyboard(
            amount: .constant(0),
            onConfirm: {},
            isValid: true
        )
    }
}
