//
//  CompactAssetCard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import SwiftUI

/// 精简的资产卡片 - 可展开查看详情
struct CompactAssetCard: View {
    let totalAssets: Decimal
    let monthIncome: Decimal
    let monthExpense: Decimal
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 精简视图
            compactView
                .padding(Spacing.l)
            
            // 展开详情
            if isExpanded {
                Divider()
                expandedView
                    .padding(Spacing.l)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
    
    private var compactView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("净资产")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formatAmount(totalAssets, isMainAmount: true))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 本月收支概要
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.expenseRed)
                    Text(formatAmount(monthExpense))
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.expenseRed)
                        .monospacedDigit()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                        .foregroundColor(.incomeGreen)
                    Text(formatAmount(monthIncome))
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.incomeGreen)
                        .monospacedDigit()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
            }
            
            // 展开/收起指示器
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
        }
    }
    
    private var expandedView: some View {
        VStack(spacing: Spacing.m) {
            // 本月结余
            HStack {
                Text("本月结余")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatAmount(monthIncome - monthExpense))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(monthIncome >= monthExpense ? .incomeGreen : .expenseRed)
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            
            Divider()
            
            // 查看详情按钮
            Button {
                // TODO: 跳转到资产详情页
            } label: {
                HStack {
                    Text("查看资产详情")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.primaryBlue)
            }
        }
    }
    
    // 格式化金额
    private func formatAmount(_ amount: Decimal, isMainAmount: Bool = false) -> String {
        let absAmount = abs(amount)
        
        if absAmount >= 100000000 {
            // 亿级别
            let precision = isMainAmount ? 2 : 1
            return "¥\((amount / 100000000).formatted(.number.precision(.fractionLength(0...precision))))亿"
        } else if absAmount >= 10000 {
            // 万级别
            let precision = isMainAmount ? 2 : 1
            return "¥\((amount / 10000).formatted(.number.precision(.fractionLength(0...precision))))万"
        } else if absAmount >= 1000 {
            // 千级别
            return "¥\(amount.formatted(.number.precision(.fractionLength(0...1))))"
        } else {
            // 小于1000，显示2位小数
            return "¥\(amount.formatted(.number.precision(.fractionLength(2))))"
        }
    }
}

// MARK: - Decimal Format Extension

extension Decimal {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSNumber) ?? "¥0.00"
    }
}

// MARK: - Preview

#Preview {
    VStack {
        CompactAssetCard(
            totalAssets: 123456.78,
            monthIncome: 15000.00,
            monthExpense: 8234.50
        )
        .padding()
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
