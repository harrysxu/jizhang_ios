//
//  IncomeExpenseChartView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import Charts

struct IncomeExpenseChartView: View {
    let data: [DailyData]
    let reportType: ReportType
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("\(reportType.displayName)趋势")
                .font(.headline)
                .padding(.horizontal, Spacing.m)
            
            if data.isEmpty {
                emptyView
            } else {
                Chart {
                    ForEach(data) { item in
                        if reportType == .expense {
                            // 支出柱
                            BarMark(
                                x: .value("日期", item.date, unit: .day),
                                y: .value("金额", item.expense)
                            )
                            .foregroundStyle(Color.expenseRed)
                        } else {
                            // 收入柱
                            BarMark(
                                x: .value("日期", item.date, unit: .day),
                                y: .value("金额", item.income)
                            )
                            .foregroundStyle(Color.incomeGreen)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, data.count / 7))) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(.dateTime.day()))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let decimal = value.as(Decimal.self) {
                                Text(formatAmount(decimal))
                                    .font(.caption2)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .padding(.horizontal, Spacing.m)
            }
        }
        .padding(.vertical, Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.systemBackground))
        )
    }
    
    private var emptyView: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("暂无数据")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
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
            // k级别
            return "¥\((amount / 1000).formatted(.number.precision(.fractionLength(0...1))))k"
        } else {
            return "¥\(amount.formatted(.number.precision(.fractionLength(0))))"
        }
    }
}

#Preview {
    let mockData = [
        DailyData(date: Date().addingTimeInterval(-86400 * 6), income: 5000, expense: 300),
        DailyData(date: Date().addingTimeInterval(-86400 * 5), income: 0, expense: 450),
        DailyData(date: Date().addingTimeInterval(-86400 * 4), income: 2000, expense: 280),
        DailyData(date: Date().addingTimeInterval(-86400 * 3), income: 0, expense: 320),
        DailyData(date: Date().addingTimeInterval(-86400 * 2), income: 0, expense: 180),
        DailyData(date: Date().addingTimeInterval(-86400 * 1), income: 1000, expense: 520),
        DailyData(date: Date(), income: 0, expense: 230)
    ]
    
    return IncomeExpenseChartView(data: mockData, reportType: .expense)
        .padding()
}
