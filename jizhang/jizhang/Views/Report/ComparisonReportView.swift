//
//  ComparisonReportView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//

import SwiftUI
import Charts

/// 对比分析报表视图 - 支持月度环比和年度同比
struct ComparisonReportView: View {
    let expenseComparison: PeriodComparisonData
    let incomeComparison: PeriodComparisonData
    let categoryComparisons: [CategoryComparisonData]
    let comparisonType: ComparisonType
    let reportType: ReportType
    
    @State private var showAllCategories = false
    
    private let defaultDisplayCount = 5
    
    enum ComparisonType {
        case monthOverMonth  // 环比（本月 vs 上月）
        case yearOverYear    // 同比（今年 vs 去年同期）
        
        var currentLabel: String {
            switch self {
            case .monthOverMonth: return "本月"
            case .yearOverYear: return "今年"
            }
        }
        
        var previousLabel: String {
            switch self {
            case .monthOverMonth: return "上月"
            case .yearOverYear: return "去年同期"
            }
        }
        
        var title: String {
            switch self {
            case .monthOverMonth: return "月度对比"
            case .yearOverYear: return "年度同比"
            }
        }
    }
    
    private var currentComparison: PeriodComparisonData {
        reportType == .expense ? expenseComparison : incomeComparison
    }
    
    private var displayedCategories: [CategoryComparisonData] {
        let filtered = categoryComparisons.filter {
            reportType == .expense ? $0.currentAmount > 0 || $0.previousAmount > 0 : $0.currentAmount > 0 || $0.previousAmount > 0
        }
        if showAllCategories {
            return filtered
        }
        return Array(filtered.prefix(defaultDisplayCount))
    }
    
    private var hasMoreCategories: Bool {
        categoryComparisons.count > defaultDisplayCount
    }
    
    var body: some View {
        GlassCard(padding: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // 标题
                HStack {
                    Text(comparisonType.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // 变化趋势标签
                    trendBadge
                }
                
                // 主要对比卡片
                mainComparisonCard
                
                // 柱状对比图
                comparisonBarChart
                
                // 分类对比列表
                if !categoryComparisons.isEmpty {
                    categoryComparisonList
                }
            }
        }
        .padding(.horizontal, Spacing.l)
    }
    
    // MARK: - 趋势标签
    
    private var trendBadge: some View {
        let isIncrease = currentComparison.isIncrease
        let changeRate = abs(currentComparison.changeRate)
        
        return HStack(spacing: 4) {
            Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
            
            Text(String(format: "%.1f%%", changeRate))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(trendColor(isIncrease: isIncrease))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(trendColor(isIncrease: isIncrease).opacity(0.1))
        )
    }
    
    private func trendColor(isIncrease: Bool) -> Color {
        if reportType == .expense {
            // 支出：增加是不好的（红色），减少是好的（绿色）
            return isIncrease ? .red : .green
        } else {
            // 收入：增加是好的（绿色），减少是不好的（红色）
            return isIncrease ? .green : .red
        }
    }
    
    // MARK: - 主要对比卡片
    
    private var mainComparisonCard: some View {
        HStack(spacing: Spacing.m) {
            // 当前周期
            VStack(spacing: Spacing.xs) {
                Text(comparisonType.currentLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatAmount(currentComparison.currentAmount))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(reportType == .expense ? Color.expenseRed : Color.incomeGreen)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            
            // VS 分隔
            VStack {
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // 上一周期
            VStack(spacing: Spacing.xs) {
                Text(comparisonType.previousLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatAmount(currentComparison.previousAmount))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            
            // 差额
            VStack(spacing: Spacing.xs) {
                Text("差额")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 2) {
                    Text(currentComparison.isIncrease ? "+" : "")
                    Text(formatAmount(currentComparison.difference))
                }
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(trendColor(isIncrease: currentComparison.isIncrease))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - 对比柱状图
    
    private var comparisonBarChart: some View {
        Chart {
            BarMark(
                x: .value("周期", comparisonType.currentLabel),
                y: .value("金额", Double(truncating: currentComparison.currentAmount as NSNumber))
            )
            .foregroundStyle(reportType == .expense ? Color.expenseRed : Color.incomeGreen)
            .cornerRadius(6)
            
            BarMark(
                x: .value("周期", comparisonType.previousLabel),
                y: .value("金额", Double(truncating: currentComparison.previousAmount as NSNumber))
            )
            .foregroundStyle(Color.gray.opacity(0.5))
            .cornerRadius(6)
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
        .frame(height: 150)
    }
    
    // MARK: - 分类对比列表
    
    private var categoryComparisonList: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("分类对比")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            ForEach(displayedCategories) { item in
                categoryComparisonRow(item)
            }
            
            // 展开/收起按钮
            if hasMoreCategories {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAllCategories.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showAllCategories ? "收起" : "查看全部 \(categoryComparisons.count) 个分类")
                            .font(.caption)
                        
                        Image(systemName: showAllCategories ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func categoryComparisonRow(_ item: CategoryComparisonData) -> some View {
        HStack(spacing: Spacing.s) {
            // 分类颜色指示
            Circle()
                .fill(Color(hex: item.colorHex))
                .frame(width: 8, height: 8)
            
            // 分类名称
            Text(item.categoryName)
                .font(.subheadline)
                .lineLimit(1)
            
            Spacer()
            
            // 当前金额
            Text(formatCompactAmount(item.currentAmount))
                .font(.caption)
                .foregroundStyle(.primary)
                .monospacedDigit()
                .frame(minWidth: 60, alignment: .trailing)
            
            // 变化指示
            HStack(spacing: 2) {
                if item.difference != 0 {
                    Image(systemName: item.isIncrease ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    
                    Text(String(format: "%.0f%%", abs(item.changeRate)))
                        .font(.caption2)
                } else {
                    Text("-")
                        .font(.caption2)
                }
            }
            .foregroundStyle(item.difference == 0 ? .secondary : trendColor(isIncrease: item.isIncrease))
            .frame(minWidth: 50, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 格式化方法
    
    private func formatAmount(_ amount: Decimal) -> String {
        let absAmount = abs(amount)
        
        if absAmount >= 10000 {
            return "¥\((amount / 10000).formatted(.number.precision(.fractionLength(1))))万"
        } else {
            return "¥\(amount.formatted(.number.precision(.fractionLength(0))))"
        }
    }
    
    private func formatCompactAmount(_ amount: Decimal) -> String {
        if amount >= 10000 {
            return "¥\((amount / 10000).formatted(.number.precision(.fractionLength(1))))万"
        } else {
            return "¥\(amount.formatted(.number.precision(.fractionLength(0))))"
        }
    }
    
    private func formatYAxisValue(_ value: Double) -> String {
        if value >= 10000 {
            return "\(Int(value / 10000))万"
        } else if value >= 1000 {
            return "\(Int(value / 1000))千"
        } else {
            return "\(Int(value))"
        }
    }
}

#Preview {
    let expenseComparison = PeriodComparisonData(
        currentAmount: 5680,
        previousAmount: 4920,
        difference: 760,
        changeRate: 15.4
    )
    
    let incomeComparison = PeriodComparisonData(
        currentAmount: 12000,
        previousAmount: 10000,
        difference: 2000,
        changeRate: 20.0
    )
    
    let categoryComparisons = [
        CategoryComparisonData(categoryId: UUID(), categoryName: "餐饮", colorHex: "#FF6B6B", currentAmount: 1800, previousAmount: 1500, difference: 300, changeRate: 20),
        CategoryComparisonData(categoryId: UUID(), categoryName: "交通", colorHex: "#4ECDC4", currentAmount: 600, previousAmount: 800, difference: -200, changeRate: -25),
        CategoryComparisonData(categoryId: UUID(), categoryName: "购物", colorHex: "#95E1D3", currentAmount: 1200, previousAmount: 1000, difference: 200, changeRate: 20),
        CategoryComparisonData(categoryId: UUID(), categoryName: "娱乐", colorHex: "#AA96DA", currentAmount: 500, previousAmount: 400, difference: 100, changeRate: 25)
    ]
    
    return ScrollView {
        VStack(spacing: 20) {
            ComparisonReportView(
                expenseComparison: expenseComparison,
                incomeComparison: incomeComparison,
                categoryComparisons: categoryComparisons,
                comparisonType: .monthOverMonth,
                reportType: .expense
            )
            
            ComparisonReportView(
                expenseComparison: expenseComparison,
                incomeComparison: incomeComparison,
                categoryComparisons: categoryComparisons,
                comparisonType: .yearOverYear,
                reportType: .income
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
