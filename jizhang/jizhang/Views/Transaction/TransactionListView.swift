//
//  TransactionListView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 完整的流水列表视图
struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    
    @State private var searchText = ""
    @State private var selectedType: TransactionType? = nil
    @State private var selectedTimeRange: TimeRange = .thisMonth
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    
    // MARK: - Computed Properties
    
    private var dateRange: (start: Date, end: Date) {
        if selectedTimeRange == .custom {
            return (customStartDate, customEndDate)
        } else {
            return selectedTimeRange.dateRange
        }
    }
    
    private var filteredTransactions: [Transaction] {
        var result = allTransactions
        
        // 按账本过滤
        if let currentLedger = appState.currentLedger {
            result = result.filter { $0.ledger?.id == currentLedger.id }
        }
        
        // 按时间范围筛选
        let range = dateRange
        result = result.filter { $0.date >= range.start && $0.date <= range.end }
        
        // 按类型筛选
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        
        // 搜索
        if !searchText.isEmpty {
            result = result.filter { transaction in
                // 搜索分类名称
                if let category = transaction.category,
                   category.name.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // 搜索备注
                if let note = transaction.note,
                   note.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // 搜索账户名称
                if let account = transaction.fromAccount,
                   account.name.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                return false
            }
        }
        
        return result
    }
    
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        .map { (date: $0.key, transactions: $0.value) }
        .sorted { $0.date > $1.date }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 时间范围选择器
                TimeRangePicker(
                    selectedRange: $selectedTimeRange,
                    customStartDate: $customStartDate,
                    customEndDate: $customEndDate
                )
                .padding(.top, Spacing.s)
                
                // 类型筛选（全部、支出、收入）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s) {
                        QuickFilterButton(
                            title: "全部",
                            isSelected: selectedType == nil
                        ) {
                            selectedType = nil
                        }
                        
                        QuickFilterButton(
                            title: "支出",
                            isSelected: selectedType == .expense
                        ) {
                            selectedType = .expense
                        }
                        
                        QuickFilterButton(
                            title: "收入",
                            isSelected: selectedType == .income
                        ) {
                            selectedType = .income
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                }
                .padding(.vertical, Spacing.s)
                
                Divider()
                
                // 流水列表
                if filteredTransactions.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "暂无流水记录" : "未找到匹配的流水",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text(searchText.isEmpty ? "点击右下角添加第一笔记录" : "尝试调整筛选条件")
                    )
                } else {
    List {
        ForEach(groupedTransactions, id: \.date) { group in
            Section {
                ForEach(group.transactions) { transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        HStack(spacing: 12) {
                            // 图标 - 使用新的CategoryIconView
                            if let category = transaction.category {
                                CategoryIconView(
                                    iconName: category.iconName,
                                    colorHex: category.colorHex,
                                    size: 44
                                )
                            } else {
                                CategoryIconView(
                                    iconName: transaction.type.icon,
                                    colorHex: "#8E8E93",
                                    size: 44
                                )
                            }
                            
                            // 信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transaction.category?.name ?? transaction.type.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 6) {
                                    if let account = transaction.fromAccount {
                                        Text(account.name)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if transaction.type == .transfer, let toAccount = transaction.toAccount {
                                        Text("→")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                        
                                        Text(toAccount.name)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("•")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                        
                                        Text("本人")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                        
                                        Text("•")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                        
                                        Text(formatTime(transaction.date))
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // 金额 - 使用随手记柔和颜色
                            Text(formatAmount(transaction))
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(amountColor(for: transaction))
                                .monospacedDigit()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .onDelete { indexSet in
                    deleteTransactions(at: indexSet, from: group.transactions)
                }
            } header: {
                TransactionSectionHeader(
                    date: group.date,
                    totalExpense: calculateExpense(group.transactions)
                )
            }
        }
    }
    .listStyle(.plain)
}
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索流水...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    LedgerSwitcher()
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatAmount(_ transaction: Transaction) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = transaction.fromAccount?.ledger?.currencyCode ?? "CNY"
        
        let sign = transaction.type == .expense ? "-" : (transaction.type == .income ? "+" : "")
        let amount = formatter.string(from: transaction.amount as NSDecimalNumber) ?? "¥0"
        
        return sign + amount
    }
    
    private func amountColor(for transaction: Transaction) -> Color {
        switch transaction.type {
        case .expense: return SuishoujiColors.expenseRed
        case .income: return SuishoujiColors.incomeGreen
        case .transfer: return SuishoujiColors.brandBlue
        case .adjustment: return SuishoujiColors.warningOrange
        }
    }
    
    private func calculateExpense(_ transactions: [Transaction]) -> Decimal {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func deleteTransactions(at offsets: IndexSet, from transactions: [Transaction]) {
        for index in offsets {
            let transaction = transactions[index]
            
            // 恢复账户余额
            switch transaction.type {
            case .expense:
                if let account = transaction.fromAccount {
                    account.balance += transaction.amount
                }
            case .income:
                if let account = transaction.fromAccount {
                    account.balance -= transaction.amount
                }
            case .transfer:
                if let fromAccount = transaction.fromAccount {
                    fromAccount.balance += transaction.amount
                }
                if let toAccount = transaction.toAccount {
                    toAccount.balance -= transaction.amount
                }
            case .adjustment:
                if let account = transaction.fromAccount {
                    account.balance -= transaction.amount
                }
            }
            
            modelContext.delete(transaction)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Quick Filter Button

private struct QuickFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transaction Section Header

private struct TransactionSectionHeader: View {
    let date: Date
    let totalExpense: Decimal
    
    private var dateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: date)
        }
    }
    
    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            Text(dateText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(weekdayText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if totalExpense > 0 {
                Text("支出: \(totalExpense.formatted(.currency(code: "CNY")))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    TransactionListView()
        .modelContainer(for: [Transaction.self, Account.self, Category.self, Ledger.self, Tag.self])
}
