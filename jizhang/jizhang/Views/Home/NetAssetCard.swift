//
//  NetAssetCard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct NetAssetCard: View {
    // MARK: - Properties
    
    let totalAssets: Decimal
    let monthIncome: Decimal
    let monthExpense: Decimal
    
    @State private var isAmountHidden = false
    
    // MARK: - Computed Properties
    
    /// 根据金额长度自适应字体大小
    private var adaptiveFontSize: CGFloat {
        let amountString = totalAssets.toCurrencyString(showSymbol: false)
        let length = amountString.count
        
        if length > 15 {
            return FontSize.amountMedium // 32pt
        } else if length > 12 {
            return FontSize.amountSmall // 24pt  
        } else {
            return FontSize.amountLarge // 48pt
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Spacing.m) {
            // 标题栏
            HStack {
                Text("净资产")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
                        isAmountHidden.toggle()
                    }
                }) {
                    Image(systemName: isAmountHidden ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            // 金额显示
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("¥")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if isAmountHidden {
                    Text("****")
                        .font(.system(size: adaptiveFontSize, weight: .bold, design: .rounded))
                } else {
                    Text(totalAssets.toCurrencyString(showSymbol: false))
                        .font(.system(size: adaptiveFontSize, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 本月收支
            HStack(spacing: Spacing.l) {
                MonthlyAmountView(
                    title: "本月支出",
                    amount: monthExpense,
                    color: Color.expenseRed,
                    isHidden: isAmountHidden
                )
                
                MonthlyAmountView(
                    title: "本月收入",
                    amount: monthIncome,
                    color: Color.incomeGreen,
                    isHidden: isAmountHidden
                )
            }
        }
        .padding(Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, Spacing.m)
    }
}

// MARK: - MonthlyAmountView

struct MonthlyAmountView: View {
    let title: String
    let amount: Decimal
    let color: Color
    let isHidden: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if isHidden {
                Text("****")
                    .font(.system(size: FontSize.title3, weight: .semibold, design: .rounded))
            } else {
                Text(formatAmount(amount))
                    .font(.system(size: FontSize.title3, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        NetAssetCard(
            totalAssets: 123456.78,
            monthIncome: 8900,
            monthExpense: 12345
        )
        
        Spacer()
    }
    .padding()
}
