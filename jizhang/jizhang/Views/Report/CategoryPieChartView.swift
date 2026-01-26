//
//  CategoryPieChartView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import Charts

struct CategoryPieChartView: View {
    let data: [CategoryData]
    let reportType: ReportType
    
    @State private var selectedCategory: CategoryData?
    @State private var isExpanded: Bool = false
    
    /// 饼图显示的最大分类数量
    private let chartMaxCategories = 8
    /// 默认显示的分类数量
    private let defaultDisplayCount = 8
    
    private var totalAmount: Decimal {
        data.reduce(0) { $0 + $1.amount }
    }
    
    /// 饼图数据：最多显示前8个，其余合并为"其他"
    private var chartData: [CategoryData] {
        guard data.count > chartMaxCategories else { return data }
        
        let topCategories = Array(data.prefix(chartMaxCategories - 1))
        let otherCategories = Array(data.dropFirst(chartMaxCategories - 1))
        
        let otherAmount = otherCategories.reduce(Decimal(0)) { $0 + $1.amount }
        let otherPercentage = totalAmount > 0 ? Double(truncating: (otherAmount / totalAmount) as NSNumber) : 0
        
        let otherCategory = CategoryData(
            categoryId: UUID(),
            name: "其他",
            amount: otherAmount,
            color: "BDBDBD",
            percentage: otherPercentage
        )
        
        return topCategories + [otherCategory]
    }
    
    /// 列表显示的分类数据
    private var displayedCategories: [CategoryData] {
        if isExpanded {
            return data
        } else {
            return Array(data.prefix(defaultDisplayCount))
        }
    }
    
    /// 是否有更多分类可以展开
    private var hasMoreCategories: Bool {
        data.count > defaultDisplayCount
    }
    
    var body: some View {
        GlassCard(padding: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text("分类分析")
                    .font(.headline)
                
                if data.isEmpty {
                    emptyView
                } else {
                    VStack(spacing: Spacing.l) {
                        // 环形饼图 (参考UI样式)
                        Chart(chartData) { item in
                            SectorMark(
                                angle: .value("金额", item.amount),
                                innerRadius: .ratio(0.6),  // 环形图
                                angularInset: 2
                            )
                            .foregroundStyle(Color(hex: item.color))
                            .opacity(selectedCategory == nil || selectedCategory?.id == item.id ? 1.0 : 0.3)
                        }
                        .frame(height: 250)
                        .overlay(alignment: .center) {
                            // 中心显示 (参考UI样式)
                            VStack(spacing: 4) {
                                if let selected = selectedCategory {
                                    Text(selected.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(formatAmount(selected.amount))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                    
                                    Text("\(Int(selected.percentage * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(reportType.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(formatAmount(totalAmount))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                }
                            }
                        }
                        
                        // 分类列表 - 显示所有有数据的分类
                        VStack(spacing: Spacing.s) {
                            ForEach(displayedCategories) { item in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: item.color))
                                        .frame(width: 10, height: 10)
                                    
                                    Text(item.name)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(item.percentage * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                        .frame(minWidth: 35, alignment: .trailing)
                                    
                                    Text(formatAmount(item.amount))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .monospacedDigit()
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                        .frame(minWidth: 80, alignment: .trailing)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = selectedCategory?.id == item.id ? nil : item
                                    }
                                }
                            }
                            
                            // 展开/收起按钮
                            if hasMoreCategories {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isExpanded.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(isExpanded ? "收起" : "查看全部 \(data.count) 个分类")
                                            .font(.caption)
                                        
                                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
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
                }
            }
        }
        .padding(.horizontal, Spacing.l)
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
            // 千级别
            return "¥\(amount.formatted(.number.precision(.fractionLength(0))))"
        } else {
            // 小于1000，显示2位小数
            return "¥\(amount.formatted(.number.precision(.fractionLength(2))))"
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "chart.pie")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("暂无数据")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let mockData = [
        CategoryData(categoryId: UUID(), name: "餐饮", amount: 2100, color: "#FF6B6B", percentage: 0.35),
        CategoryData(categoryId: UUID(), name: "交通", amount: 1200, color: "#4ECDC4", percentage: 0.20),
        CategoryData(categoryId: UUID(), name: "购物", amount: 900, color: "#95E1D3", percentage: 0.15),
        CategoryData(categoryId: UUID(), name: "居住", amount: 800, color: "#F38181", percentage: 0.13),
        CategoryData(categoryId: UUID(), name: "娱乐", amount: 600, color: "#AA96DA", percentage: 0.10),
        CategoryData(categoryId: UUID(), name: "医疗", amount: 400, color: "#FCBAD3", percentage: 0.07)
    ]
    
    return CategoryPieChartView(data: mockData, reportType: .expense)
        .padding()
}
