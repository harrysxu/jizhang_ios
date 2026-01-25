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
            VStack(alignment: .leading, spacing: 8) {
                Text("今日支出")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                
                Text(formatAmount(todayExpense))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(SuishoujiColors.expenseRed)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 可视化指示器
            Circle()
                .fill(SuishoujiColors.expenseRed.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(SuishoujiColors.expenseRed)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
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
