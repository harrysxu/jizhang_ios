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
    
    /// 每日预算总额（从所有活跃预算计算得出）
    let dailyBudget: Decimal
    
    /// 是否有设置预算
    private var hasBudget: Bool {
        dailyBudget > 0
    }
    
    private var budgetProgress: Double {
        guard dailyBudget > 0 else { return 0 }
        return Double(truncating: (todayExpense / dailyBudget) as NSNumber)
    }
    
    private var budgetStatus: BudgetProgressColor {
        if budgetProgress >= 1.0 {
            return .over
        } else if budgetProgress >= 0.9 {
            return .warning
        } else {
            return .safe
        }
    }
    
    /// 剩余/超支金额（正数为剩余，负数为超支）
    private var remainingAmount: Decimal {
        dailyBudget - todayExpense
    }
    
    // MARK: - Body
    
    var body: some View {
        GlassCard(padding: Spacing.l) {
            VStack(spacing: Spacing.m) {
                // 标题和金额
                HStack {
                    Text("今日支出")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(todayExpense.formatAmount())
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.expenseRed)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                
                // 预算进度条（仅在有预算时显示）
                if hasBudget {
                    budgetProgressView
                } else {
                    noBudgetView
                }
            }
        }
        .padding(.horizontal, Spacing.l)
    }
    
    // MARK: - Subviews
    
    /// 预算进度视图
    private var budgetProgressView: some View {
        VStack(spacing: Spacing.xs) {
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    // 进度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [budgetStatus.color, budgetStatus.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(min(budgetProgress, 1.0)))
                        .animation(.spring(response: 0.5), value: budgetProgress)
                }
            }
            .frame(height: 8)
            
            // 进度信息
            HStack {
                Text("\(Int(min(budgetProgress, 9.99) * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(budgetStatus.color)
                
                Spacer()
                
                if remainingAmount >= 0 {
                    Text("剩余 \(remainingAmount.formatAmount())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("超支 \(abs(remainingAmount).formatAmount())")
                        .font(.caption)
                        .foregroundStyle(Color.expenseRed)
                }
            }
        }
    }
    
    /// 无预算提示视图
    private var noBudgetView: some View {
        HStack {
            Text("暂未设置预算")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Budget Progress Color

private enum BudgetProgressColor {
    case safe
    case warning
    case over
    
    var color: Color {
        switch self {
        case .safe: return .incomeGreen
        case .warning: return .warningOrange
        case .over: return .expenseRed
        }
    }
}

// MARK: - Preview

#Preview("有预算") {
    VStack {
        TodayExpenseCard(todayExpense: 150, dailyBudget: 200)
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("超支") {
    VStack {
        TodayExpenseCard(todayExpense: 256.50, dailyBudget: 200)
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("无预算") {
    VStack {
        TodayExpenseCard(todayExpense: 100, dailyBudget: 0)
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
