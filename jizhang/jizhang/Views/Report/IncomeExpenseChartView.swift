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
    let period: ReportPeriod
    
    var body: some View {
        GlassCard(padding: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text("\(reportType.displayName)趋势")
                    .font(.headline)
                
                if data.isEmpty {
                    emptyView
                } else {
                    if period == .year {
                        // 按年：使用月度聚合数据
                        yearlyChart
                    } else {
                        // 按周/按月：使用每日数据
                        dailyChart
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.l)
    }
    
    // MARK: - 按年图表（月度聚合）
    
    private var yearlyChart: some View {
        Chart {
            ForEach(monthlyAggregatedData, id: \.month) { item in
                BarMark(
                    x: .value("月份", item.month),
                    y: .value("金额", item.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: reportType == .expense 
                            ? [Color.expenseRed, Color.expenseRed.opacity(0.7)]
                            : [Color.incomeGreen, Color.incomeGreen.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: Array(1...12)) { value in
                AxisValueLabel {
                    if let month = value.as(Int.self) {
                        Text("\(month)月")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    .foregroundStyle(Color.gray.opacity(0.2))
                
                AxisValueLabel {
                    if let decimal = value.as(Decimal.self) {
                        Text(formatAmount(decimal))
                            .font(.caption2)
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartXScale(domain: 1...12)
        .chartLegend(.hidden)
        .frame(height: 220)
    }
    
    // MARK: - 按周/月图表（每日数据）
    
    private var dailyChart: some View {
        Chart {
            ForEach(data) { item in
                if reportType == .expense {
                    // 支出柱 (带渐变)
                    BarMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("金额", item.expense)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.expenseRed, Color.expenseRed.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                } else {
                    // 收入柱 (带渐变)
                    BarMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("金额", item.income)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.incomeGreen, Color.incomeGreen.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
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
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    .foregroundStyle(Color.gray.opacity(0.2))
                
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
    }
    
    // MARK: - 月度聚合数据
    
    private var monthlyAggregatedData: [(month: Int, amount: Decimal)] {
        let calendar = Calendar.current
        var monthlyTotals: [Int: Decimal] = [:]
        
        // 初始化12个月
        for month in 1...12 {
            monthlyTotals[month] = 0
        }
        
        // 聚合数据
        for item in data {
            let month = calendar.component(.month, from: item.date)
            let amount = reportType == .expense ? item.expense : item.income
            monthlyTotals[month, default: 0] += amount
        }
        
        // 转换为数组并排序
        return monthlyTotals.map { (month: $0.key, amount: $0.value) }
            .sorted { $0.month < $1.month }
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

#Preview("按月") {
    let mockData = [
        DailyData(date: Date().addingTimeInterval(-86400 * 6), income: 5000, expense: 300),
        DailyData(date: Date().addingTimeInterval(-86400 * 5), income: 0, expense: 450),
        DailyData(date: Date().addingTimeInterval(-86400 * 4), income: 2000, expense: 280),
        DailyData(date: Date().addingTimeInterval(-86400 * 3), income: 0, expense: 320),
        DailyData(date: Date().addingTimeInterval(-86400 * 2), income: 0, expense: 180),
        DailyData(date: Date().addingTimeInterval(-86400 * 1), income: 1000, expense: 520),
        DailyData(date: Date(), income: 0, expense: 230)
    ]
    
    return IncomeExpenseChartView(data: mockData, reportType: .expense, period: .month)
        .padding()
}

#Preview("按年") {
    // 模拟一年的月度数据
    let calendar = Calendar.current
    let year = calendar.component(.year, from: Date())
    var mockData: [DailyData] = []
    
    for month in 1...12 {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 15
        if let date = calendar.date(from: components) {
            mockData.append(DailyData(
                date: date,
                income: Decimal(Int.random(in: 10000...30000)),
                expense: Decimal(Int.random(in: 5000...20000))
            ))
        }
    }
    
    return IncomeExpenseChartView(data: mockData, reportType: .income, period: .year)
        .padding()
}
