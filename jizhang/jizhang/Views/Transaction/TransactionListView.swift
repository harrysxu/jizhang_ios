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
    @State private var selectedMonth = Date()  // 选中的月份
    @State private var showExportOptions = false
    @State private var showDateRangePicker = false
    @State private var exportStartDate = Date()
    @State private var exportEndDate = Date()
    
    // MARK: - Computed Properties
    
    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        let startOfMonth = calendar.date(from: components)!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        return (startOfMonth, endOfMonth)
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
                
                // 搜索账户名称（转出账户）
                if let account = transaction.fromAccount,
                   account.name.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // 搜索转入账户名称（用于转账）
                if let toAccount = transaction.toAccount,
                   toAccount.name.localizedCaseInsensitiveContains(searchText) {
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
                // 月份选择器 (参考UI样式: 2026-01格式)
                MonthYearPicker(selectedDate: $selectedMonth)
                    .padding(.vertical, Spacing.s)
                
                // 类型筛选（全部、支出、收入、转账）
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
                        
                        QuickFilterButton(
                            title: "转账",
                            isSelected: selectedType == .transfer
                        ) {
                            selectedType = .transfer
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
                        description: Text(searchText.isEmpty ? "点击 + 添加第一笔记录" : "尝试调整筛选条件")
                    )
                } else {
    List {
        ForEach(groupedTransactions, id: \.date) { group in
            Section {
                ForEach(group.transactions) { transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        HStack(spacing: Spacing.m) {
                            // 圆形图标 (参考UI样式)
                            if let category = transaction.category {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: category.colorHex))
                                        .frame(width: 44, height: 44)
                                    
                                    PhosphorIcon.icon(named: category.iconName, weight: .fill)
                                        .frame(width: 24, height: 24)
                                        .foregroundStyle(.white)
                                }
                                .shadow(color: Color(hex: category.colorHex).opacity(0.3), radius: 4, y: 2)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 44, height: 44)
                                    
                                    PhosphorIcon.icon(named: transaction.type.phosphorIcon, weight: .fill)
                                        .frame(width: 24, height: 24)
                                        .foregroundStyle(.white)
                                }
                                .shadow(color: Color.gray.opacity(0.3), radius: 4, y: 2)
                            }
                            
                            // 信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transaction.category?.name ?? transaction.type.displayName)
                                    .font(.body)
                                
                                HStack(spacing: 4) {
                                    if let account = transaction.fromAccount {
                                        Text(account.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if transaction.type == .transfer, let toAccount = transaction.toAccount {
                                        Text("→")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(toAccount.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("•")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(formatTime(transaction.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // 金额
                            Text(formatAmount(transaction))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
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
                ToolbarItem(placement: .principal) {
                    LedgerSwitcher(displayMode: .fullName)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExportOptions = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExportOptions) {
                exportOptionsSheet
            }
            .sheet(isPresented: $showDateRangePicker) {
                dateRangePickerSheet
            }
        }
    }
    
    // MARK: - Export Options Sheet
    
    private var exportOptionsSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showExportOptions = false
                        exportCurrentFiltered()
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("导出当前筛选数据")
                                    .foregroundStyle(.primary)
                                Text("共 \(filteredTransactions.count) 条记录")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        showExportOptions = false
                        // 初始化日期范围为当月
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year, .month], from: Date())
                        exportStartDate = calendar.date(from: components)!
                        exportEndDate = Date()
                        showDateRangePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("选择时间范围导出")
                                    .foregroundStyle(.primary)
                                Text("自定义起止日期")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("导出选项")
                }
            }
            .navigationTitle("导出流水")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showExportOptions = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Date Range Picker Sheet
    
    private var dateRangePickerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("开始日期", selection: $exportStartDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    DatePicker("结束日期", selection: $exportEndDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                } header: {
                    Text("选择时间范围")
                }
                
                Section {
                    let count = countTransactionsInRange()
                    HStack {
                        Text("符合条件的记录")
                        Spacer()
                        Text("\(count) 条")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showDateRangePicker = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("导出") {
                        showDateRangePicker = false
                        exportByDateRange()
                    }
                    .disabled(countTransactionsInRange() == 0)
                }
            }
        }
        .presentationDetents([.medium])
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
        case .expense: return .red
        case .income: return .green
        case .transfer: return .blue
        case .adjustment: return .orange
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
    
    /// 导出当前筛选的数据
    private func exportCurrentFiltered() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let monthStr = dateFormatter.string(from: selectedMonth)
        let ledgerName = appState.currentLedger?.name ?? "全部"
        
        var typeSuffix = ""
        if let type = selectedType {
            typeSuffix = "_\(type.displayName)"
        }
        
        let fileName = "流水明细_\(ledgerName)_\(monthStr)\(typeSuffix).csv"
        
        if let url = CSVExporter.exportToFile(transactions: filteredTransactions, fileName: fileName) {
            ShareUtils.share(url: url)
        }
    }
    
    /// 导出指定时间范围的数据
    private func exportByDateRange() {
        // 获取时间范围内的交易（只按账本和时间过滤，不按类型和搜索过滤）
        var transactions = allTransactions
        
        // 按账本过滤
        if let currentLedger = appState.currentLedger {
            transactions = transactions.filter { $0.ledger?.id == currentLedger.id }
        }
        
        // 按时间范围过滤
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: exportStartDate)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: exportEndDate)!
        transactions = transactions.filter { $0.date >= startOfDay && $0.date <= endOfDay }
        
        // 生成文件名
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let startStr = dateFormatter.string(from: exportStartDate)
        let endStr = dateFormatter.string(from: exportEndDate)
        let ledgerName = appState.currentLedger?.name ?? "全部"
        
        let fileName = "流水明细_\(ledgerName)_\(startStr)-\(endStr).csv"
        
        if let url = CSVExporter.exportToFile(transactions: transactions, fileName: fileName) {
            ShareUtils.share(url: url)
        }
    }
    
    /// 计算指定时间范围内的交易数量
    private func countTransactionsInRange() -> Int {
        var transactions = allTransactions
        
        // 按账本过滤
        if let currentLedger = appState.currentLedger {
            transactions = transactions.filter { $0.ledger?.id == currentLedger.id }
        }
        
        // 按时间范围过滤
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: exportStartDate)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: exportEndDate)!
        transactions = transactions.filter { $0.date >= startOfDay && $0.date <= endOfDay }
        
        return transactions.count
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
