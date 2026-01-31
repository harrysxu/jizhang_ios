//
//  MediumWidgetView.swift
//  jizhangWidget
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import WidgetKit

/// Medium Widget视图 - 今日支出+最近流水
struct MediumWidgetView: View {
    let data: WidgetData
    
    /// 预算状态颜色
    private var statusColor: Color {
        let percentage = data.budgetUsagePercentage
        if percentage < 0.8 {
            return .green
        } else if percentage < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧: 今日支出汇总
            VStack(alignment: .leading, spacing: 8) {
                // 标题
                Text("今日支出")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 金额
                VStack(alignment: .leading, spacing: 4) {
                    Text("¥\(formattedAmount(data.todayExpense))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text("/ ¥\(formattedAmount(data.todayBudget))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 预算进度
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(Int(data.budgetUsagePercentage * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(statusColor)
                        
                        Spacer()
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.quaternary)
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(statusColor)
                                .frame(
                                    width: min(geometry.size.width * CGFloat(data.budgetUsagePercentage), geometry.size.width),
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // 右侧: 最近3笔交易
            VStack(alignment: .leading, spacing: 8) {
                Text("最近流水")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if data.recentTransactions.isEmpty {
                    VStack {
                        Spacer()
                        Text("暂无交易")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(data.recentTransactions.prefix(3)) { transaction in
                            TransactionRowView(transaction: transaction)
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    // MARK: - Helper Methods
    
    /// 格式化金额
    private func formattedAmount(_ amount: Decimal) -> String {
        let nsNumber = amount as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: nsNumber) ?? "0"
    }
}

// MARK: - Transaction Row

struct TransactionRowView: View {
    let transaction: WidgetTransaction
    
    private var amountColor: Color {
        transaction.type == "expense" ? .red : .green
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: transaction.categoryIcon)
                .font(.caption2)
                .foregroundStyle(.blue)
                .frame(width: 14)
            
            Text(transaction.categoryName)
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer(minLength: 2)
            
            Text(transaction.displayAmount)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(amountColor)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    jizhangWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        data: WidgetData(
            todayExpense: 256.00,
            todayIncome: 0,
            monthExpense: 3245.50,
            monthIncome: 8900.00,
            todayBudget: 200.00,
            monthBudget: 6000.00,
            budgetUsagePercentage: 0.54,
            recentTransactions: [
                WidgetTransaction(
                    id: UUID(),
                    amount: 45.00,
                    categoryName: "午餐",
                    categoryIcon: "fork.knife",
                    date: Date(),
                    type: "expense",
                    note: nil
                ),
                WidgetTransaction(
                    id: UUID(),
                    amount: 12.50,
                    categoryName: "交通",
                    categoryIcon: "bus",
                    date: Date().addingTimeInterval(-3600),
                    type: "expense",
                    note: nil
                ),
                WidgetTransaction(
                    id: UUID(),
                    amount: 85.00,
                    categoryName: "购物",
                    categoryIcon: "cart",
                    date: Date().addingTimeInterval(-7200),
                    type: "expense",
                    note: nil
                )
            ],
            lastUpdateTime: Date(),
            ledgerName: "我的账本"
        )
    )
}
