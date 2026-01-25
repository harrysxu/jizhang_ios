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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("分类占比(\(reportType.displayName))")
                .font(.headline)
                .padding(.horizontal, Spacing.m)
            
            if data.isEmpty {
                emptyView
            } else {
                VStack(spacing: Spacing.m) {
                    // 饼图
                    Chart(data.prefix(8)) { item in
                        SectorMark(
                            angle: .value("金额", item.amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color(hex: item.color))
                        .opacity(0.8)
                    }
                    .frame(height: 200)
                    .padding(.horizontal, Spacing.m)
                    
                    // 分类列表
                    VStack(spacing: Spacing.s) {
                        ForEach(data.prefix(8)) { item in
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
                        }
                        
                        if data.count > 8 {
                            Text("还有 \(data.count - 8) 个分类...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, Spacing.xs)
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                }
            }
        }
        .padding(.vertical, Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.systemBackground))
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
