//
//  TopRankingView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct TopRankingView: View {
    let data: [TopRankingItem]
    let reportType: ReportType
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            titleView
            
            if data.isEmpty {
                emptyView
            } else {
                rankingList
            }
        }
        .padding(.vertical, Spacing.m)
        .background(backgroundView)
    }
    
    private var titleView: some View {
        Text("\(reportType.displayName)Top 5")
            .font(.headline)
            .padding(.horizontal, Spacing.m)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: CornerRadius.medium)
            .fill(Color(.systemBackground))
    }
    
    private var rankingList: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                rankingRow(index: index, item: item)
                
                if index < data.count - 1 {
                    Divider()
                        .padding(.leading, Spacing.m + 28 + Spacing.m)
                }
            }
        }
    }
    
    private func rankingRow(index: Int, item: TopRankingItem) -> some View {
        HStack(spacing: Spacing.m) {
            // 排名
            rankingBadge(for: index)
            
            // 分类图标
            categoryIcon(for: item)
            
            // 分类名称
            VStack(alignment: .leading, spacing: 2) {
                Text(item.categoryName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(item.count) 笔")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 8)
            
            // 金额
            Text(formatAmount(item.amount))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(reportType == .expense ? Color.expenseRed : Color.incomeGreen)
                .monospacedDigit()
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
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
    
    private func rankingBadge(for index: Int) -> some View {
        ZStack {
            Circle()
                .fill(rankingColor(for: index))
                .frame(width: 28, height: 28)
            
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
    
    private func categoryIcon(for item: TopRankingItem) -> some View {
        Image(systemName: item.iconName)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(Color(hex: item.colorHex))
            .frame(width: 36, height: 36)
    }
    
    private var emptyView: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "list.number")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("暂无数据")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
    
    private func rankingColor(for index: Int) -> Color {
        switch index {
        case 0:
            return Color(hex: "#FFD700") // 金色
        case 1:
            return Color(hex: "#C0C0C0") // 银色
        case 2:
            return Color(hex: "#CD7F32") // 铜色
        default:
            return Color.gray
        }
    }
}

#Preview {
    let mockData = [
        TopRankingItem(categoryName: "午餐", iconName: "fork.knife", colorHex: "#FF6B6B", amount: 1234, count: 15),
        TopRankingItem(categoryName: "地铁", iconName: "car.fill", colorHex: "#4ECDC4", amount: 678, count: 28),
        TopRankingItem(categoryName: "咖啡", iconName: "cup.and.saucer.fill", colorHex: "#95E1D3", amount: 567, count: 12),
        TopRankingItem(categoryName: "电影", iconName: "film", colorHex: "#AA96DA", amount: 456, count: 4),
        TopRankingItem(categoryName: "书籍", iconName: "book.fill", colorHex: "#FCBAD3", amount: 345, count: 3)
    ]
    
    return TopRankingView(data: mockData, reportType: .expense)
        .padding()
}
