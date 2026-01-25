//
//  BudgetOverviewCard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct BudgetOverviewCard: View {
    let totalBudget: Decimal
    let totalUsed: Decimal
    let remainingDays: Int
    
    private var progress: Double {
        guard totalBudget > 0 else { return 0 }
        return Double(truncating: (totalUsed / totalBudget) as NSNumber)
    }
    
    private var remaining: Decimal {
        totalBudget - totalUsed
    }
    
    private var dailyAverage: Decimal {
        guard remainingDays > 0, remaining > 0 else { return 0 }
        return remaining / Decimal(remainingDays)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            headerSection
            usedAmountSection
            BudgetProgressBar(progress: progress, height: 12)
            bottomInfoSection
        }
        .padding(Spacing.m)
        .background(cardBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var headerSection: some View {
        HStack {
            Text("总预算")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(formatAmount(totalBudget))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }
    
    private var usedAmountSection: some View {
        HStack {
            Text("已用")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(formatAmount(totalUsed))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(progress >= 1.0 ? Color.expenseRed : .primary)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            Text("\(Int(progress * 100))%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
    }
    
    private var bottomInfoSection: some View {
        HStack(spacing: Spacing.l) {
            dailyAverageView
            Spacer()
            remainingDaysView
        }
    }
    
    private var dailyAverageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("日均可用")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(formatAmount(dailyAverage))
                .font(.headline)
                .foregroundStyle(Color.incomeGreen)
                .monospacedDigit()
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
    }
    
    private var remainingDaysView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("距月底")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(remainingDays) 天")
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: CornerRadius.medium)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
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
    VStack(spacing: Spacing.l) {
        BudgetOverviewCard(
            totalBudget: 5000,
            totalUsed: 3245,
            remainingDays: 10
        )
        
        BudgetOverviewCard(
            totalBudget: 5000,
            totalUsed: 5200,
            remainingDays: 5
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
