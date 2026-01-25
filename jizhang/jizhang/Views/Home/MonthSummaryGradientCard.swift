//
//  MonthSummaryGradientCard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//  首页本月收支渐变卡片 - 随手记风格
//

import SwiftUI

/// 首页本月收支汇总卡片 (随手记风格)
struct MonthSummaryGradientCard: View {
    // MARK: - Environment
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    
    let totalExpense: Decimal
    let income: Decimal
    let expense: Decimal
    
    @State private var isAmountVisible = true
    
    // MARK: - Body
    
    var body: some View {
        GradientCard(
            lightGradient: SuishoujiColors.homeGradientLight,
            darkGradient: SuishoujiColors.homeGradientDark,
            height: 200,
            cornerRadius: 20,
            showDecorativeCircles: true
        ) {
            ZStack(alignment: .topLeading) {
                // 占位插画 (右下角浅色圆形)
                PlaceholderIllustration(
                    color: .white,
                    size: 160,
                    alignment: .bottomTrailing
                )
                
                // 主要内容
                VStack(alignment: .leading, spacing: 16) {
                    // 顶部标题栏
                    HStack {
                        Text("本月收支")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // 眼睛图标
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isAmountVisible.toggle()
                                }
                            }) {
                                Image(systemName: isAmountVisible ? "eye" : "eye.slash")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            
                            // 趋势图标
                            Button(action: {}) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // 总支出
                    VStack(alignment: .leading, spacing: 4) {
                        Text("总支出")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        if isAmountVisible {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(formatLargeAmount(totalExpense))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                            }
                        } else {
                            Text("****")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // 底部收入和结余
                    HStack(spacing: 0) {
                        // 总收入
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                
                                Text("总收入")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            if isAmountVisible {
                                Text(formatAmount(income))
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            } else {
                                Text("****")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 竖线分隔
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1, height: 40)
                        
                        // 结余
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                
                                Text("结余")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            if isAmountVisible {
                                Text(formatAmount(income - expense))
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            } else {
                                Text("****")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(24)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatLargeAmount(_ amount: Decimal) -> String {
        let absAmount = abs(amount)
        
        if absAmount >= 10000 {
            let value = (amount / 10000).formatted(.number.precision(.fractionLength(0...2)))
            return value
        } else {
            return amount.formatted(.number.precision(.fractionLength(2)))
        }
    }
    
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

#Preview("本月收支卡片") {
    VStack {
        MonthSummaryGradientCard(
            totalExpense: 12345.67,
            income: 8900.00,
            expense: 12345.67
        )
        
        Spacer()
    }
    .padding()
    .background(SuishoujiColors.pageBackgroundLight)
}

#Preview("本月收支卡片 - 暗色模式") {
    VStack {
        MonthSummaryGradientCard(
            totalExpense: 12345.67,
            income: 8900.00,
            expense: 12345.67
        )
        
        Spacer()
    }
    .padding()
    .background(SuishoujiColors.pageBackgroundDark)
    .preferredColorScheme(.dark)
}

#Preview("大金额测试") {
    VStack {
        MonthSummaryGradientCard(
            totalExpense: 1234567.89,
            income: 890000.00,
            expense: 1234567.89
        )
        
        MonthSummaryGradientCard(
            totalExpense: 123456789.12,
            income: 98765432.10,
            expense: 123456789.12
        )
        
        Spacer()
    }
    .padding()
    .background(SuishoujiColors.pageBackgroundLight)
}
