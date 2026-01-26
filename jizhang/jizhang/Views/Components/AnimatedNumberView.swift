//
//  AnimatedNumberView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI

// MARK: - Animated Number View

/// 数字滚动动画组件 (参考UI样式)
struct AnimatedNumberView: View {
    
    // MARK: - Properties
    
    let value: Decimal
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let blur: Bool
    
    @State private var displayValue: Decimal = 0
    
    // MARK: - Initialization
    
    init(
        value: Decimal,
        fontSize: CGFloat = 52,
        fontWeight: Font.Weight = .bold,
        blur: Bool = false
    ) {
        self.value = value
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.blur = blur
    }
    
    // MARK: - Body
    
    var body: some View {
        Text(formatAmount(displayValue))
            .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
            .monospacedDigit()
            .blur(radius: blur ? 8 : 0)
            .onChange(of: value) { oldValue, newValue in
                animateValue(from: oldValue, to: newValue)
            }
            .onAppear {
                displayValue = value
            }
    }
    
    // MARK: - Private Methods
    
    private func animateValue(from: Decimal, to: Decimal) {
        let duration: Double = 0.5
        let steps = 30
        let increment = (to - from) / Decimal(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (duration / Double(steps)) * Double(i)) {
                displayValue = from + increment * Decimal(i)
            }
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
}

// MARK: - Animated Currency Text

/// 带货币符号的数字动画组件
struct AnimatedCurrencyText: View {
    let value: Decimal
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let color: Color
    let showSign: Bool
    
    @State private var displayValue: Decimal = 0
    
    init(
        value: Decimal,
        fontSize: CGFloat = 52,
        fontWeight: Font.Weight = .bold,
        color: Color = .primary,
        showSign: Bool = false
    ) {
        self.value = value
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.showSign = showSign
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showSign && value > 0 {
                Text("+")
                    .font(.system(size: fontSize * 0.8, weight: fontWeight))
                    .foregroundStyle(color)
            }
            
            Text("¥")
                .font(.system(size: fontSize * 0.5, weight: .regular))
                .foregroundStyle(.secondary)
            
            Text(formatAmount(displayValue))
                .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                displayValue = newValue
            }
        }
        .onAppear {
            displayValue = value
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        
        return formatter.string(from: abs(amount) as NSDecimalNumber) ?? "0.00"
    }
}

// MARK: - Simple Animated Number

/// 简单数字动画 (无货币符号)
struct SimpleAnimatedNumber: View {
    let value: Double
    let format: String
    
    @State private var displayValue: Double = 0
    
    init(value: Double, format: String = "%.0f") {
        self.value = value
        self.format = format
    }
    
    var body: some View {
        Text(String(format: format, displayValue))
            .monospacedDigit()
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.spring(response: 0.5)) {
                    displayValue = newValue
                }
            }
            .onAppear {
                displayValue = value
            }
    }
}

// MARK: - Preview

#Preview("Animated Number View") {
    VStack(spacing: 40) {
        VStack(spacing: 8) {
            Text("基础数字动画")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            AnimatedNumberView(
                value: 123456.78,
                fontSize: 52,
                fontWeight: .bold
            )
        }
        
        VStack(spacing: 8) {
            Text("带货币符号")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            AnimatedCurrencyText(
                value: 9876.54,
                fontSize: 40,
                fontWeight: .semibold,
                color: .incomeGreen,
                showSign: true
            )
        }
        
        VStack(spacing: 8) {
            Text("简单数字")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            SimpleAnimatedNumber(
                value: 89.5,
                format: "%.1f%%"
            )
            .font(.title)
            .fontWeight(.bold)
        }
    }
    .padding()
}

#Preview("Interactive Demo") {
    struct DemoView: View {
        @State private var amount: Decimal = 1000
        
        var body: some View {
            VStack(spacing: 40) {
                AnimatedCurrencyText(
                    value: amount,
                    fontSize: 48,
                    fontWeight: .bold,
                    color: .primaryBlue
                )
                
                HStack(spacing: 20) {
                    Button("增加 ¥100") {
                        amount += 100
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("减少 ¥100") {
                        amount -= 100
                    }
                    .buttonStyle(.bordered)
                    
                    Button("重置") {
                        amount = 1000
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
    
    return DemoView()
}
