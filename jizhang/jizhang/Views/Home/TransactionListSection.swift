//
//  TransactionListSection.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct TransactionListSection: View {
    // MARK: - Properties
    
    let transactions: [Transaction]
    
    // MARK: - Computed Properties
    
    /// 按日期分组的交易
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        
        return grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            if transactions.isEmpty {
                EmptyTransactionView()
            } else {
                ForEach(groupedTransactions, id: \.date) { group in
                    VStack(spacing: 0) {
                        // 日期头部
                        SectionHeader(date: group.date, transactions: group.transactions)
                        
                        // 交易列表
                        ForEach(group.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                                .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let date: Date
    let transactions: [Transaction]
    
    private var dayTotal: Decimal {
        transactions.reduce(0) { total, transaction in
            switch transaction.type {
            case .expense:
                return total - transaction.amount
            case .income:
                return total + transaction.amount
            case .transfer, .adjustment:
                return total
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(date.smartDescription)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Group {
                if dayTotal > 0 {
                    Text("+\(dayTotal.toCurrencyString())")
                        .foregroundStyle(Color.incomeGreen)
                } else if dayTotal < 0 {
                    Text(dayTotal.toCurrencyString())
                        .foregroundStyle(Color.expenseRed)
                } else {
                    Text("¥0.00")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .monospacedDigit()
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - TransactionRow

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: Spacing.m) {
            // 圆形分类图标 (参考UI样式)
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
            }
            .shadow(color: iconBackgroundColor.opacity(0.3), radius: 4, y: 2)
            
            // 交易信息
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 4) {
                    if let accountName = transaction.primaryAccount?.name {
                        Text(accountName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let note = transaction.note, !note.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // 金额
            Text(transaction.displayAmount)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(amountColor)
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
    
    // MARK: - Private Properties
    
    private var displayTitle: String {
        switch transaction.type {
        case .expense, .income:
            return transaction.category?.name ?? "未分类"
        case .transfer:
            if let from = transaction.fromAccount, let to = transaction.toAccount {
                return "\(from.name) → \(to.name)"
            }
            return "转账"
        case .adjustment:
            return "余额调整"
        }
    }
    
    private var categoryIcon: String {
        switch transaction.type {
        case .expense, .income:
            return transaction.category?.iconName ?? "questionmark.circle"
        case .transfer:
            return "arrow.left.arrow.right"
        case .adjustment:
            return "slider.horizontal.3"
        }
    }
    
    private var iconBackgroundColor: Color {
        if let category = transaction.category {
            return Color(hex: category.colorHex)
        }
        
        switch transaction.type {
        case .expense:
            return Color.expenseRed
        case .income:
            return Color.incomeGreen
        case .transfer:
            return Color.primaryBlue
        case .adjustment:
            return Color.gray
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense:
            return Color.expenseRed
        case .income:
            return Color.incomeGreen
        case .transfer, .adjustment:
            return .primary
        }
    }
}

// MARK: - EmptyTransactionView

struct EmptyTransactionView: View {
    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("暂无流水记录")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("点击右下角 + 按钮开始记账")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        TransactionListSection(transactions: [])
    }
}
