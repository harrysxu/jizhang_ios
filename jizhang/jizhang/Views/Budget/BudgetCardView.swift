//
//  BudgetCardView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct BudgetCardView: View {
    let budget: Budget
    var onTap: (() -> Void)? = nil
    
    private var statusColor: Color {
        switch budget.status {
        case .safe:
            return .incomeGreen
        case .caution, .warning:
            return .warningOrange
        case .exceeded:
            return .expenseRed
        }
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.m) {
                // 头部
                HStack {
                    // 分类图标
                    ZStack {
                        Circle()
                            .fill(Color(hex: budget.category?.colorHex ?? "#007AFF").opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: budget.category?.iconName ?? "folder.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: budget.category?.colorHex ?? "#007AFF"))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(budget.category?.name ?? "未分类")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Text("预算 \(formatAmount(budget.amount + budget.rolloverAmount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // 金额信息
                HStack(spacing: Spacing.m) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已用")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(formatAmount(budget.usedAmount))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(statusColor)
                            .monospacedDigit()
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(budget.isOverBudget ? "超支" : "剩余")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(formatAmount(abs(budget.remainingAmount)))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(budget.isOverBudget ? Color.expenseRed : .primary)
                            .monospacedDigit()
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // 进度条
                VStack(spacing: Spacing.xs) {
                    BudgetProgressBar(progress: budget.progress, height: 10)
                    
                    HStack {
                        Text("\(Int(budget.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(statusColor)
                        
                        Spacer()
                        
                        if budget.enableRollover && budget.rolloverAmount > 0 {
                            Text("含结转 \(formatAmount(budget.rolloverAmount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(statusColor.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // 格式化金额
    private func formatAmount(_ amount: Decimal) -> String {
        let absAmount = abs(amount)
        
        if absAmount >= 100000000 {
            // 亿级别
            return "¥\((amount / 100000000).formatted(.number.precision(.fractionLength(0...1))))亿"
        } else if absAmount >= 10000 {
            // 万级别
            return "¥\((amount / 10000).formatted(.number.precision(.fractionLength(0...1))))万"
        } else if absAmount >= 1000 {
            // 千级别，显示1位小数
            return "¥\(amount.formatted(.number.precision(.fractionLength(0...1))))"
        } else {
            // 小于1000，显示2位小数
            return "¥\(amount.formatted(.number.precision(.fractionLength(2))))"
        }
    }
}

#Preview {
    let mockLedger = Ledger(name: "测试账本")
    
    let mockCategory = Category(
        ledger: mockLedger,
        name: "餐饮",
        type: .expense,
        iconName: "fork.knife",
        colorHex: "#FF6B6B"
    )
    
    let mockBudget = Budget(
        ledger: mockLedger,
        category: mockCategory,
        amount: 2000,
        period: .monthly,
        startDate: Date(),
        enableRollover: false
    )
    
    VStack(spacing: Spacing.m) {
        BudgetCardView(budget: mockBudget)
        
        BudgetCardView(budget: mockBudget)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
