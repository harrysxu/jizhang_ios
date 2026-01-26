//
//  ReportView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel: ReportViewModel
    
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]
    
    // 周期选择器状态
    @State private var selectedPeriod: ReportPeriod = .month
    @State private var selectedDate = Date()
    
    init() {
        // 临时初始化一个空的 ModelContext，实际会在 onAppear 中使用环境中的 modelContext
        let container = try! ModelContainer(for: Transaction.self, Account.self)
        _viewModel = StateObject(wrappedValue: ReportViewModel(modelContext: container.mainContext))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    // 周期选择器 (按周/按月/按年)
                    ReportPeriodPicker(selectedPeriod: $selectedPeriod, selectedDate: $selectedDate)
                        .onChange(of: selectedDate) { oldValue, newValue in
                            loadData()
                        }
                        .onChange(of: selectedPeriod) { oldValue, newValue in
                            loadData()
                        }
                        .padding(.top, Spacing.s)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // 汇总卡片
                        summaryCard
                        
                        // 报表类型选择器
                        Picker("报表类型", selection: Binding(
                            get: { viewModel.reportType },
                            set: { viewModel.reportType = $0; loadData() }
                        )) {
                            Text("支出").tag(ReportType.expense)
                            Text("收入").tag(ReportType.income)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, Spacing.m)
                        
                        // 收支趋势图
                        IncomeExpenseChartView(data: viewModel.dailyData, reportType: viewModel.reportType, period: selectedPeriod)
                            .padding(.horizontal, Spacing.m)
                        
                        // 分类占比图
                        CategoryPieChartView(data: viewModel.categoryData, reportType: viewModel.reportType)
                            .padding(.horizontal, Spacing.m)
                        
                        // Top排行榜
                        TopRankingView(data: viewModel.topRanking, reportType: viewModel.reportType)
                            .padding(.horizontal, Spacing.m)
                    }
                }
                .padding(.bottom, Spacing.l)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    LedgerSwitcher(displayMode: .fullName)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exportReportCSV()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                loadData()
            }
            .onChange(of: appState.currentLedger) { oldValue, newValue in
                // 账本切换时重新加载数据
                loadData()
            }
        }
    }
    
    private var summaryCard: some View {
        GlassCard(padding: Spacing.l) {
            HStack(spacing: 0) {
                // 收入
                VStack(spacing: Spacing.s) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                        Text("收入")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    
                    Text(formatSummaryAmount(viewModel.totalIncome))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.incomeGreen)
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 50)
                
                // 支出
                VStack(spacing: Spacing.s) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                        Text("支出")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    
                    Text(formatSummaryAmount(viewModel.totalExpense))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.expenseRed)
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 50)
                
                // 结余
                VStack(spacing: Spacing.s) {
                    Text("结余")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 2) {
                        Text(formatSummaryAmount(viewModel.netAmount))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(viewModel.netAmount >= 0 ? Color.incomeGreen : Color.expenseRed)
                            .monospacedDigit()
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        
                        Image(systemName: viewModel.netAmount >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(viewModel.netAmount >= 0 ? Color.incomeGreen : Color.expenseRed)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.l)
    }
    
    // 格式化汇总卡片金额
    private func formatSummaryAmount(_ amount: Decimal) -> String {
        amount.formatSummaryAmount()
    }
    
    // 计算当前选中周期的日期范围
    private var periodDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .week:
            // 周: 从周一到周日
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            return (weekStart, weekEnd)
            
        case .month:
            // 月: 从1号到月末
            let components = calendar.dateComponents([.year, .month], from: selectedDate)
            let monthStart = calendar.date(from: components)!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            return (monthStart, monthEnd)
            
        case .year:
            // 年: 从1月1日到12月31日
            let year = calendar.component(.year, from: selectedDate)
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            let yearStart = calendar.date(from: startComponents)!
            
            var endComponents = DateComponents()
            endComponents.year = year
            endComponents.month = 12
            endComponents.day = 31
            let yearEnd = calendar.date(from: endComponents)!
            
            return (yearStart, yearEnd)
        }
    }
    
    private func loadData() {
        // 获取周期日期范围
        let range = periodDateRange
        
        // 设置viewModel的日期范围为自定义模式
        viewModel.selectedRange = .custom
        viewModel.customStartDate = range.start
        viewModel.customEndDate = range.end
        
        // 根据当前账本过滤交易
        let filteredTransactions = if let currentLedger = appState.currentLedger {
            transactions.filter { $0.ledger?.id == currentLedger.id }
        } else {
            transactions
        }
        
        // 根据当前账本过滤账户
        let filteredAccounts = if let currentLedger = appState.currentLedger {
            accounts.filter { $0.ledger?.id == currentLedger.id }
        } else {
            accounts
        }
        
        viewModel.loadData(transactions: filteredTransactions, accounts: filteredAccounts)
    }
    
    /// 导出统计报表CSV
    private func exportReportCSV() {
        let range = periodDateRange
        
        // 生成文件名
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let startStr = dateFormatter.string(from: range.start)
        let endStr = dateFormatter.string(from: range.end)
        let ledgerName = appState.currentLedger?.name ?? "全部"
        let fileName = "统计报表_\(ledgerName)_\(startStr)-\(endStr).csv"
        
        if let url = CSVExporter.exportReportToFile(
            totalIncome: viewModel.totalIncome,
            totalExpense: viewModel.totalExpense,
            netAmount: viewModel.netAmount,
            categoryData: viewModel.categoryData,
            reportType: viewModel.reportType,
            startDate: range.start,
            endDate: range.end,
            fileName: fileName
        ) {
            ShareUtils.share(url: url)
        }
    }
}

#Preview {
    ReportView()
        .modelContainer(for: [Transaction.self, Account.self])
}
