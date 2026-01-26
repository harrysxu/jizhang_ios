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
            GlassCard(padding: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    // 头部 (使用圆形图标)
                    HStack {
                        // 圆形分类图标 (参考UI样式)
                        ZStack {
                            Circle()
                                .fill(Color(hex: budget.category?.colorHex ?? "#007AFF"))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: budget.category?.iconName ?? "folder.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: Color(hex: budget.category?.colorHex ?? "#007AFF").opacity(0.3), radius: 4, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(budget.category?.name ?? "未分类")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Text("预算 \((budget.amount + budget.rolloverAmount).formatAmount())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // 金额信息
                    HStack(spacing: Spacing.l) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("已用")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(budget.usedAmount.formatAmount())
                                .font(.title3)
                                .fontWeight(.semibold)
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
                            
                            Text(abs(budget.remainingAmount).formatAmount())
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(budget.isOverBudget ? Color.expenseRed : .primary)
                                .monospacedDigit()
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // 进度条
                    VStack(spacing: Spacing.s) {
                        BudgetProgressBar(progress: budget.progress, height: 10)
                        
                        HStack {
                            Text("\(Int(budget.progress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(statusColor)
                            
                            Spacer()
                            
                            if budget.enableRollover && budget.rolloverAmount > 0 {
                                Text("含结转 \(budget.rolloverAmount.formatAmount())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .overlay(
                // 状态边框
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .strokeBorder(statusColor.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
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
