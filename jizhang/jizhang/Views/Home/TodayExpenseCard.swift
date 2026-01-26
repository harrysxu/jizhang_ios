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
    
    // 示例预算值(后续可从实际预算数据获取)
    private let dailyBudget: Decimal = 200
    
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
                
                // 预算进度条
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
                        Text("\(Int(budgetProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(budgetStatus.color)
                        
                        Spacer()
                        
                        if budgetProgress < 1.0 {
                            Text("剩余 \((dailyBudget - todayExpense).formatAmount())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("超支 \((todayExpense - dailyBudget).formatAmount())")
                                .font(.caption)
                                .foregroundStyle(Color.expenseRed)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.l)
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

#Preview {
    VStack {
        TodayExpenseCard(todayExpense: 256.50)
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
