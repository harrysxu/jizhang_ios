//
//  ReportSummaryGradientCard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//  报表页流水统计渐变卡片 - 随手记风格
//

import SwiftUI

/// 报表页流水统计汇总卡片 (随手记风格)
struct ReportSummaryGradientCard: View {
    // MARK: - Environment
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    
    let income: Decimal
    let expense: Decimal
    let balance: Decimal
    
    // MARK: - Body
    
    var body: some View {
        GradientCard(
            lightGradient: SuishoujiColors.reportGradientLight,
            darkGradient: SuishoujiColors.reportGradientDark,
            height: 120,
            cornerRadius: 16,
            showDecorativeCircles: false
        ) {
            ZStack(alignment: .leading) {
                // 占位插画 (右下角小圆形)
                PlaceholderIllustration(
                    color: .white,
                    size: 100,
                    alignment: .bottomTrailing
                )
                
                // 内容
                VStack(alignment: .leading, spacing: 16) {
                    Text("账本流水统计")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 0) {
                        // 收入
                        VStack(alignment: .leading, spacing: 6) {
                            Text("收入")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(formatAmount(income))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 支出
                        VStack(alignment: .leading, spacing: 6) {
                            Text("支出")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(formatAmount(expense))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 结余
                        VStack(alignment: .leading, spacing: 6) {
                            Text("结余")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(spacing: 4) {
                                Text(formatAmount(balance))
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                                
                                Image(systemName: balance >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatAmount(_ amount: Decimal) -> String {
        let absAmount = abs(amount)
        
        if absAmount >= 100000000 {
            let value = (amount / 100000000).formatted(.number.precision(.fractionLength(0...1)))
            return "\(value)亿"
        } else if absAmount >= 10000 {
            let value = (amount / 10000).formatted(.number.precision(.fractionLength(0...1)))
            return "\(value)万"
        } else {
            return amount.formatted(.number.precision(.fractionLength(2)))
        }
    }
}

// MARK: - Preview

#Preview("报表汇总卡片") {
    VStack(spacing: 20) {
        ReportSummaryGradientCard(
            income: 8900.00,
            expense: 12345.67,
            balance: -3445.67
        )
        
        ReportSummaryGradientCard(
            income: 89000.00,
            expense: 56789.12,
            balance: 32210.88
        )
        
        Spacer()
    }
    .padding()
    .background(SuishoujiColors.pageBackgroundLight)
}

#Preview("报表汇总卡片 - 暗色模式") {
    VStack(spacing: 20) {
        ReportSummaryGradientCard(
            income: 8900.00,
            expense: 12345.67,
            balance: -3445.67
        )
        
        Spacer()
    }
    .padding()
    .background(SuishoujiColors.pageBackgroundDark)
    .preferredColorScheme(.dark)
}
