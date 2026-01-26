//
//  AmountDisplay.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

/// 金额显示组件
struct AmountDisplay: View {
    @Binding var amount: Decimal
    let fontSize: CGFloat
    let isLargeDisplay: Bool
    let showCurrency: Bool
    
    init(
        amount: Binding<Decimal>,
        fontSize: CGFloat = 56,
        isLargeDisplay: Bool = true,
        showCurrency: Bool = true
    ) {
        self._amount = amount
        self.fontSize = fontSize
        self.isLargeDisplay = isLargeDisplay
        self.showCurrency = showCurrency
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showCurrency {
                Text("¥")
                    .font(.system(size: fontSize * 0.5, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Text(formattedAmount)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit() // 关键:等宽数字防止跳动
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var formattedAmount: String {
        if amount == 0 {
            return "0"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = isLargeDisplay ? 2 : 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }
}

#Preview {
    VStack {
        AmountDisplay(amount: .constant(0))
        AmountDisplay(amount: .constant(123.45))
        AmountDisplay(amount: .constant(12345.67))
    }
}
