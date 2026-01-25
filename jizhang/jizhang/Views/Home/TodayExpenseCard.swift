//
//  TodayExpenseCard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct TodayExpenseCard: View {
    // MARK: - Properties
    
    let todayExpense: Decimal
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("今日支出")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(formatAmount(todayExpense))
                    .font(.system(size: FontSize.title2, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.expenseRed)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 可以添加预算进度显示
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, Spacing.m)
    }
    
    // 格式化金额
    private func formatAmount(_ amount: Decimal) -> String {
        let absAmount = abs(amount)
        
        if absAmount >= 100000000 {
            // 亿级别
            return "¥\((amount / 100000000).formatted(.number.precision(.fractionLength(0...2))))亿"
        } else if absAmount >= 10000 {
            // 万级别
            return "¥\((amount / 10000).formatted(.number.precision(.fractionLength(0...2))))万"
        } else {
            // 小于1万，显示完整金额
            return "¥\(amount.formatted(.number.precision(.fractionLength(2))))"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TodayExpenseCard(todayExpense: 256.50)
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
