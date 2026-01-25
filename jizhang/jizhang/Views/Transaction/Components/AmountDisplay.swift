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
    
    var body: some View {
        HStack(spacing: 4) {
            Text("¥")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.gray)
            
            Text(formattedAmount)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
    
    private var formattedAmount: String {
        if amount == 0 {
            return "0"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
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
