//
//  AccountStatisticsView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//

import SwiftUI
import Charts

/// 账户统计报表视图 - 按账户展示收支情况
struct AccountStatisticsView: View {
    let data: [AccountStatisticsData]
    
    @State private var selectedAccount: AccountStatisticsData?
    @State private var showAllAccounts = false
    
    private let defaultDisplayCount = 5
    
    private var totalBalance: Decimal {
        data.reduce(Decimal(0)) { $0 + $1.balance }
    }
    
    private var totalIncome: Decimal {
        data.reduce(Decimal(0)) { $0 + $1.income }
    }
    
    private var totalExpense: Decimal {
        data.reduce(Decimal(0)) { $0 + $1.expense }
    }
    
    private var displayedAccounts: [AccountStatisticsData] {
        if showAllAccounts {
            return data
        }
        return Array(data.prefix(defaultDisplayCount))
    }
    
    private var hasMoreAccounts: Bool {
        data.count > defaultDisplayCount
    }
    
    // 按账户类型分组
    private var assetAccounts: [AccountStatisticsData] {
        data.filter { $0.accountType.isAsset }
    }
    
    private var liabilityAccounts: [AccountStatisticsData] {
        data.filter { !$0.accountType.isAsset }
    }
    
    var body: some View {
        GlassCard(padding: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // 标题
                Text("账户统计")
                    .font(.headline)
                
                // 总览卡片
                overviewCard
                
                // 账户分布饼图
                if !data.isEmpty {
                    accountDistributionChart
                }
                
                // 账户列表
                if !data.isEmpty {
                    accountListSection
                }
            }
        }
        .padding(.horizontal, Spacing.l)
    }
    
    // MARK: - 总览卡片
    
    private var overviewCard: some View {
        HStack(spacing: 0) {
            // 总资产
            VStack(spacing: Spacing.xs) {
                Text("资产账户")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatAmount(assetAccounts.reduce(0) { $0 + $1.balance }))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.incomeGreen)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 50)
            
            // 负债
            VStack(spacing: Spacing.xs) {
                Text("负债账户")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatAmount(liabilityAccounts.reduce(0) { $0 + $1.balance }))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.expenseRed)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 50)
            
            // 净值
            VStack(spacing: Spacing.xs) {
                Text("净资产")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatAmount(totalBalance))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(totalBalance >= 0 ? Color.incomeGreen : Color.expenseRed)
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
    
    // MARK: - 账户分布饼图
    
    private var accountDistributionChart: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("余额分布")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.l) {
                // 饼图
                Chart(data.filter { $0.balance > 0 }) { item in
                    SectorMark(
                        angle: .value("余额", Double(truncating: item.balance as NSNumber)),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                    .opacity(selectedAccount == nil || selectedAccount?.id == item.id ? 1.0 : 0.3)
                }
                .frame(width: 120, height: 120)
                .overlay(alignment: .center) {
                    if let selected = selectedAccount {
                        VStack(spacing: 2) {
                            Text(selected.accountName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            
                            Text(formatCompactAmount(selected.balance))
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                // 图例
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(data.filter { $0.balance > 0 }.prefix(5)) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: item.colorHex))
                                .frame(width: 8, height: 8)
                            
                            Text(item.accountName)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(formatCompactAmount(item.balance))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedAccount = selectedAccount?.id == item.id ? nil : item
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 账户列表
    
    private var accountListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("账户明细")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 0) {
                ForEach(Array(displayedAccounts.enumerated()), id: \.element.id) { index, account in
                    accountRow(account)
                    
                    if index < displayedAccounts.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color(.secondarySystemBackground))
            )
            
            // 展开/收起按钮
            if hasMoreAccounts {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAllAccounts.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showAllAccounts ? "收起" : "查看全部 \(data.count) 个账户")
                            .font(.caption)
                        
                        Image(systemName: showAllAccounts ? "chevron.up" : "chevron.down")
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
    
    private func accountRow(_ account: AccountStatisticsData) -> some View {
        HStack(spacing: Spacing.m) {
            // 账户图标
            ZStack {
                Circle()
                    .fill(Color(hex: account.colorHex).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: accountIconName(for: account.accountType))
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: account.colorHex))
            }
            
            // 账户信息
            VStack(alignment: .leading, spacing: 2) {
                Text(account.accountName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(account.transactionCount) 笔交易")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 收支和余额
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(account.balance))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(account.balance >= 0 ? .primary : Color.expenseRed)
                
                HStack(spacing: Spacing.xs) {
                    if account.income > 0 {
                        Text("+\(formatCompactAmount(account.income))")
                            .font(.caption2)
                            .foregroundStyle(Color.incomeGreen)
                    }
                    
                    if account.expense > 0 {
                        Text("-\(formatCompactAmount(account.expense))")
                            .font(.caption2)
                            .foregroundStyle(Color.expenseRed)
                    }
                }
            }
        }
        .padding(Spacing.m)
    }
    
    private func accountIconName(for type: AccountType) -> String {
        switch type {
        case .cash:
            return "banknote"
        case .checking:
            return "creditcard"
        case .creditCard:
            return "creditcard.fill"
        case .eWallet:
            return "iphone"
        }
    }
    
    // MARK: - 格式化方法
    
    private func formatAmount(_ amount: Decimal) -> String {
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
            return "\((amount / 10000).formatted(.number.precision(.fractionLength(1))))万"
        } else {
            return "\(amount.formatted(.number.precision(.fractionLength(0))))"
        }
    }
}

#Preview {
    let mockData = [
        AccountStatisticsData(
            accountId: UUID(),
            accountName: "招商银行储蓄卡",
            accountType: .checking,
            iconName: "creditcard",
            colorHex: "#FF6B6B",
            balance: 25600,
            income: 15000,
            expense: 8500,
            netFlow: 6500,
            transactionCount: 45
        ),
        AccountStatisticsData(
            accountId: UUID(),
            accountName: "支付宝",
            accountType: .eWallet,
            iconName: "iphone",
            colorHex: "#4ECDC4",
            balance: 3200,
            income: 2000,
            expense: 4500,
            netFlow: -2500,
            transactionCount: 78
        ),
        AccountStatisticsData(
            accountId: UUID(),
            accountName: "现金",
            accountType: .cash,
            iconName: "banknote",
            colorHex: "#95E1D3",
            balance: 1580,
            income: 500,
            expense: 2300,
            netFlow: -1800,
            transactionCount: 32
        ),
        AccountStatisticsData(
            accountId: UUID(),
            accountName: "招行信用卡",
            accountType: .creditCard,
            iconName: "creditcard.fill",
            colorHex: "#AA96DA",
            balance: -5200,
            income: 0,
            expense: 5200,
            netFlow: -5200,
            transactionCount: 28
        )
    ]
    
    ScrollView {
        AccountStatisticsView(data: mockData)
            .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
