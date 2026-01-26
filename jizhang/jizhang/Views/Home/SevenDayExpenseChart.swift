//
//  SevenDayExpenseChart.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI
import Charts

// MARK: - Seven Day Expense Chart

/// 最近7日支出趋势图 (参考UI样式)
struct SevenDayExpenseChart: View {
    
    // MARK: - Properties
    
    let data: [DayExpense]
    
    // MARK: - Day Expense Model
    
    struct DayExpense: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Decimal
        
        var dayName: String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "E"  // 周一、周二...
            return formatter.string(from: date)
        }
        
        var shortDayName: String {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return "今天"
            } else if calendar.isDateInYesterday(date) {
                return "昨天"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.dateFormat = "E"  // 周一、周二...
                return formatter.string(from: date).replacingOccurrences(of: "星期", with: "周")
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            // 标题
            HStack {
                Text("最近7日支出")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let total = totalAmount {
                    Text("总计: ¥\(total.formatted(.number.precision(.fractionLength(2))))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 图表
            if !data.isEmpty {
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("日期", item.shortDayName),
                            y: .value("金额", Double(truncating: item.amount as NSDecimalNumber))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.expenseRed.opacity(0.8), Color.expenseRed],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel {
                                Text(formatYAxisValue(doubleValue))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let stringValue = value.as(String.self) {
                                Text(stringValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 120)
            } else {
                // 空状态
                VStack(spacing: Spacing.s) {
                    Image(systemName: "chart.bar.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text("暂无支出数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            }
        }
        .padding(Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, Spacing.m)
    }
    
    // MARK: - Computed Properties
    
    private var totalAmount: Decimal? {
        guard !data.isEmpty else { return nil }
        return data.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Helper Methods
    
    /// 格式化Y轴数值
    private func formatYAxisValue(_ value: Double) -> String {
        if value >= 10000 {
            return "\(Int(value / 10000))万"
        } else if value >= 1000 {
            return "\(Int(value / 1000))千"
        } else if value == 0 {
            return "0"
        } else {
            return "\(Int(value))"
        }
    }
}

// MARK: - Helper Extension

extension SevenDayExpenseChart {
    /// 从交易列表生成7日数据
    static func generateData(from transactions: [Transaction]) -> [DayExpense] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 生成最近7天的日期
        var dayData: [DayExpense] = []
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            
            // 计算该天的支出总额
            let dayExpense = transactions
                .filter { transaction in
                    transaction.type == .expense &&
                    calendar.isDate(transaction.date, inSameDayAs: date)
                }
                .reduce(Decimal(0)) { $0 + $1.amount }
            
            dayData.append(DayExpense(date: date, amount: dayExpense))
        }
        
        return dayData
    }
}

// MARK: - Preview

#Preview("With Data") {
    let calendar = Calendar.current
    let today = Date()
    
    let sampleData = (0..<7).reversed().map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        let amount = Decimal(Int.random(in: 50...300))
        return SevenDayExpenseChart.DayExpense(date: date, amount: amount)
    }
    
    return ScrollView {
        VStack {
            SevenDayExpenseChart(data: sampleData)
            Spacer()
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    )
}

#Preview("Empty State") {
    ScrollView {
        VStack {
            SevenDayExpenseChart(data: [])
            Spacer()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
