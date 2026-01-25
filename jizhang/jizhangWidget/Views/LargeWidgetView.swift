//
//  LargeWidgetView.swift
//  jizhangWidget
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import WidgetKit
import AppIntents

/// Large Widget视图 - 本月概览+快捷操作
struct LargeWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部: 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("简记账")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(data.ledgerName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("本月")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // 本月收支汇总
            HStack(spacing: 16) {
                // 支出
                VStack(alignment: .leading, spacing: 4) {
                    Text("¥\(formattedAmount(data.monthExpense))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("支出")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 收入
                VStack(alignment: .leading, spacing: 4) {
                    Text("¥\(formattedAmount(data.monthIncome))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("收入")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 结余
                VStack(alignment: .leading, spacing: 4) {
                    let balance = data.monthIncome - data.monthExpense
                    Text("¥\(formattedAmount(abs(balance)))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(balance >= 0 ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    HStack(spacing: 2) {
                        Text("结余")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        if balance > 0 {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        } else if balance < 0 {
                            Image(systemName: "arrow.down.right")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            
            Divider()
            
            // 最近流水
            VStack(alignment: .leading, spacing: 6) {
                Text("最近流水")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if data.recentTransactions.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title3)
                                .foregroundStyle(.tertiary)
                            
                            Text("暂无交易记录")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 12)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(data.recentTransactions.prefix(5)) { transaction in
                            LargeTransactionRowView(transaction: transaction)
                        }
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            // 底部: 快速记账按钮 (iOS 17+ 交互式Widget)
            if #available(iOS 17.0, *) {
                Button(intent: AddTransactionIntent()) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        
                        Text("记一笔")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            } else {
                // iOS 17以下显示提示文字
                Link(destination: URL(string: "jizhang://add-transaction")!) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        
                        Text("打开App记账")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
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

// MARK: - Large Transaction Row

struct LargeTransactionRowView: View {
    let transaction: WidgetTransaction
    
    private var amountColor: Color {
        transaction.type == "expense" ? .red : .green
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: transaction.date)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // 图标
            Image(systemName: transaction.categoryIcon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            // 分类和备注
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.categoryName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(timeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 金额
            Text(transaction.displayAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(amountColor)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    jizhangWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        data: WidgetData(
            todayExpense: 256.00,
            todayIncome: 50.00,
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
                    note: "公司食堂"
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
                    note: "超市采购"
                ),
                WidgetTransaction(
                    id: UUID(),
                    amount: 50.00,
                    categoryName: "兼职",
                    categoryIcon: "dollarsign.circle",
                    date: Date().addingTimeInterval(-10800),
                    type: "income",
                    note: nil
                ),
                WidgetTransaction(
                    id: UUID(),
                    amount: 28.00,
                    categoryName: "餐饮",
                    categoryIcon: "fork.knife",
                    date: Date().addingTimeInterval(-14400),
                    type: "expense",
                    note: "晚餐"
                )
            ],
            lastUpdateTime: Date(),
            ledgerName: "我的账本"
        )
    )
}
