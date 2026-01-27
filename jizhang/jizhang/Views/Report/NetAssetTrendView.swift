//
//  NetAssetTrendView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//

import SwiftUI
import Charts

/// 净资产趋势图视图 - 显示6个月或1年的资产变化
struct NetAssetTrendView: View {
    let data: [MonthlyAssetData]
    let selectedRange: TrendRange
    let onRangeChange: (TrendRange) -> Void
    
    @State private var selectedDataPoint: MonthlyAssetData?
    
    enum TrendRange: String, CaseIterable {
        case sixMonths = "6个月"
        case oneYear = "1年"
        
        var months: Int {
            switch self {
            case .sixMonths: return 6
            case .oneYear: return 12
            }
        }
    }
    
    private var currentAsset: Decimal {
        data.last?.totalAsset ?? 0
    }
    
    private var firstAsset: Decimal {
        data.first?.totalAsset ?? 0
    }
    
    private var totalChange: Decimal {
        currentAsset - firstAsset
    }
    
    private var changeRate: Double {
        guard firstAsset != 0 else { return 0 }
        return Double(truncating: (totalChange / firstAsset) as NSNumber) * 100
    }
    
    private var isPositiveGrowth: Bool {
        totalChange >= 0
    }
    
    var body: some View {
        GlassCard(padding: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // 标题栏
                headerView
                
                // 当前净资产
                currentAssetView
                
                // 折线图
                if !data.isEmpty {
                    trendChart
                } else {
                    emptyView
                }
                
                // 变化统计
                if !data.isEmpty {
                    changeStatisticsView
                }
            }
        }
        .padding(.horizontal, Spacing.l)
    }
    
    // MARK: - 标题栏
    
    private var headerView: some View {
        HStack {
            Text("净资产趋势")
                .font(.headline)
            
            Spacer()
            
            // 时间范围选择器
            Picker("时间范围", selection: Binding(
                get: { selectedRange },
                set: { onRangeChange($0) }
            )) {
                ForEach(TrendRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
        }
    }
    
    // MARK: - 当前净资产
    
    private var currentAssetView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("当前净资产")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: Spacing.s) {
                Text(formatAssetAmount(currentAsset))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(currentAsset >= 0 ? Color.incomeGreen : Color.expenseRed)
                
                // 增长指示
                if !data.isEmpty && data.count > 1 {
                    HStack(spacing: 2) {
                        Image(systemName: isPositiveGrowth ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        
                        Text(String(format: "%.1f%%", abs(changeRate)))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(isPositiveGrowth ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isPositiveGrowth ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
            }
        }
    }
    
    // MARK: - 趋势折线图
    
    private var trendChart: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("月份", item.monthLabel),
                    y: .value("资产", Double(truncating: item.totalAsset as NSNumber))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("月份", item.monthLabel),
                    y: .value("资产", Double(truncating: item.totalAsset as NSNumber))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("月份", item.monthLabel),
                    y: .value("资产", Double(truncating: item.totalAsset as NSNumber))
                )
                .foregroundStyle(Color.blue)
                .symbolSize(selectedDataPoint?.id == item.id ? 100 : 40)
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
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.2))
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let x = value.location.x - geometry[plotFrame].origin.x
                                
                                if let index = findClosestDataPoint(at: x, in: geometry[plotFrame].width) {
                                    selectedDataPoint = data[index]
                                }
                            }
                            .onEnded { _ in
                                selectedDataPoint = nil
                            }
                    )
            }
        }
        .frame(height: 200)
        .overlay(alignment: .top) {
            if let selected = selectedDataPoint {
                selectedDataPointTooltip(selected)
            }
        }
    }
    
    private func findClosestDataPoint(at x: CGFloat, in width: CGFloat) -> Int? {
        guard !data.isEmpty else { return nil }
        let stepWidth = width / CGFloat(data.count - 1)
        let index = Int(round(x / stepWidth))
        return max(0, min(data.count - 1, index))
    }
    
    private func selectedDataPointTooltip(_ item: MonthlyAssetData) -> some View {
        VStack(spacing: 2) {
            Text(item.monthLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(formatAssetAmount(item.totalAsset))
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
    }
    
    // MARK: - 变化统计
    
    private var changeStatisticsView: some View {
        HStack(spacing: Spacing.m) {
            statisticItem(
                title: "起始资产",
                value: formatCompactAmount(firstAsset),
                subtitle: data.first?.monthLabel ?? ""
            )
            
            Divider()
                .frame(height: 40)
            
            statisticItem(
                title: "累计变化",
                value: (totalChange >= 0 ? "+" : "") + formatCompactAmount(totalChange),
                subtitle: String(format: "%.1f%%", changeRate),
                valueColor: isPositiveGrowth ? .green : .red
            )
            
            Divider()
                .frame(height: 40)
            
            statisticItem(
                title: "月均变化",
                value: formatCompactAmount(data.count > 1 ? totalChange / Decimal(data.count - 1) : 0),
                subtitle: "每月"
            )
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func statisticItem(
        title: String,
        value: String,
        subtitle: String,
        valueColor: Color = .primary
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 空状态
    
    private var emptyView: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("暂无资产数据")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 格式化方法
    
    private func formatAssetAmount(_ amount: Decimal) -> String {
        let absAmount = abs(amount)
        
        if absAmount >= 100000000 {
            return "¥\((amount / 100000000).formatted(.number.precision(.fractionLength(1))))亿"
        } else if absAmount >= 10000 {
            return "¥\((amount / 10000).formatted(.number.precision(.fractionLength(1))))万"
        } else {
            return "¥\(amount.formatted(.number.precision(.fractionLength(0))))"
        }
    }
    
    private func formatCompactAmount(_ amount: Decimal) -> String {
        let absAmount = abs(amount)
        
        if absAmount >= 10000 {
            return "¥\((amount / 10000).formatted(.number.precision(.fractionLength(1))))万"
        } else {
            return "¥\(amount.formatted(.number.precision(.fractionLength(0))))"
        }
    }
    
    private func formatYAxisValue(_ value: Double) -> String {
        let absValue = abs(value)
        if absValue >= 10000 {
            return "\(Int(value / 10000))万"
        } else if absValue >= 1000 {
            return "\(Int(value / 1000))千"
        } else {
            return "\(Int(value))"
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    
    let sampleData = (0..<6).reversed().map { monthOffset -> MonthlyAssetData in
        let date = calendar.date(byAdding: .month, value: -monthOffset, to: now)!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        let label = formatter.string(from: monthStart)
        
        let baseAsset = Decimal(50000)
        let growth = Decimal(monthOffset * 2000 + Int.random(in: -1000...1000))
        
        return MonthlyAssetData(
            date: monthStart,
            totalAsset: baseAsset + growth,
            monthLabel: label
        )
    }
    
    return ScrollView {
        NetAssetTrendView(
            data: sampleData,
            selectedRange: .sixMonths,
            onRangeChange: { _ in }
        )
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
