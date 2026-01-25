//
//  SmallWidgetView.swift
//  jizhangWidget
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import WidgetKit

/// Small Widget视图 - 今日支出快览
struct SmallWidgetView: View {
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
    
    /// 预算状态图标
    private var statusIcon: String {
        let percentage = data.budgetUsagePercentage
        if percentage < 0.8 {
            return "checkmark.circle.fill"
        } else if percentage < 1.0 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶部标题
            HStack {
                Text("今日支出")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
            
            Spacer()
            
            // 金额显示
            VStack(alignment: .leading, spacing: 4) {
                Text("¥\(formattedAmount(data.todayExpense))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text("预算 ¥\(formattedAmount(data.todayBudget))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 预算进度条
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(Int(data.budgetUsagePercentage * 100))%")
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                    
                    Spacer()
                    
                    if data.todayBudget > data.todayExpense {
                        Text("剩余 ¥\(formattedAmount(data.todayBudget - data.todayExpense))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("超支")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.quaternary)
                            .frame(height: 4)
                        
                        // 进度
                        RoundedRectangle(cornerRadius: 2)
                            .fill(statusColor)
                            .frame(
                                width: min(geometry.size.width * CGFloat(data.budgetUsagePercentage), geometry.size.width),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
            }
        }
        .padding()
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

// MARK: - Preview

#Preview(as: .systemSmall) {
    jizhangWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        data: WidgetData(
            todayExpense: 156.50,
            todayIncome: 0,
            monthExpense: 3245.50,
            monthIncome: 8900.00,
            todayBudget: 200.00,
            monthBudget: 6000.00,
            budgetUsagePercentage: 0.78,
            recentTransactions: [],
            lastUpdateTime: Date(),
            ledgerName: "我的账本"
        )
    )
    
    WidgetEntry(
        date: Date(),
        data: WidgetData(
            todayExpense: 256.00,
            todayIncome: 0,
            monthExpense: 3245.50,
            monthIncome: 8900.00,
            todayBudget: 200.00,
            monthBudget: 6000.00,
            budgetUsagePercentage: 1.28,
            recentTransactions: [],
            lastUpdateTime: Date(),
            ledgerName: "我的账本"
        )
    )
}
