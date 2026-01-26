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
            return FontSize.amountMedium // 30pt
        } else if length > 12 {
            return FontSize.amountSmall // 20pt  
        } else {
            return FontSize.amountXLarge // 52pt ⭐
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        GlassCard(cornerRadius: CornerRadius.xlarge, padding: Spacing.xxl) {
            VStack(spacing: Spacing.l) {
                // 标题栏
                HStack {
                    Text("净资产")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isAmountHidden.toggle()
                        }
                        // 触觉反馈
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: isAmountHidden ? "eye.slash.fill" : "eye.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 大金额显示
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("¥")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    if isAmountHidden {
                        Text("****")
                            .font(.system(size: FontSize.amountXLarge, weight: .bold, design: .rounded))
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
                HStack(spacing: Spacing.xxxl) {
                    MonthlyAmountView(
                        title: "支出",
                        amount: monthExpense,
                        color: Color.expenseRed,
                        icon: "arrow.down",
                        isHidden: isAmountHidden
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    MonthlyAmountView(
                        title: "收入",
                        amount: monthIncome,
                        color: Color.incomeGreen,
                        icon: "arrow.up",
                        isHidden: isAmountHidden
                    )
                }
            }
        }
        .padding(.horizontal, Spacing.l)
    }
}

// MARK: - MonthlyAmountView

struct MonthlyAmountView: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String
    let isHidden: Bool
    
    var body: some View {
        VStack(spacing: Spacing.s) {
            // 标题和图标
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            // 金额
            if isHidden {
                Text("****")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
            } else {
                Text(amount.formatAmount())
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
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
