//
//  ReportView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 报表Tab类型
enum ReportTab: String, CaseIterable {
    case overview = "总览"
    case comparison = "对比"
    case trend = "趋势"
    case account = "账户"
}

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel: ReportViewModel
    
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]
    
    // 周期选择器状态
    @State private var selectedPeriod: ReportPeriod = .month
    @State private var selectedDate = Date()
    
    // 报表Tab选择
    @State private var selectedTab: ReportTab = .overview
    
    // 对比类型选择
    @State private var comparisonType: ComparisonReportView.ComparisonType = .monthOverMonth
    
    // 订阅相关
    @State private var showSubscriptionSheet = false
    
    init() {
        // 临时初始化一个空的 ModelContext，实际会在 onAppear 中使用环境中的 modelContext
        let container = try! ModelContainer(for: Transaction.self, Account.self)
        _viewModel = StateObject(wrappedValue: ReportViewModel(modelContext: container.mainContext))
    }
    
    /// 检查Tab是否需要高级权限
    private func isPremiumTab(_ tab: ReportTab) -> Bool {
        switch tab {
        case .overview:
            return false
        case .comparison:
            return true
        case .trend:
            return true
        case .account:
            return true
        }
    }
    
    /// 获取Tab对应的高级功能
    private func premiumFeature(for tab: ReportTab) -> PremiumFeature? {
        switch tab {
        case .overview:
            return nil
        case .comparison:
            return .comparisonReport
        case .trend:
            return .trendReport
        case .account:
            return .accountStatistics
        }
    }
    
    /// 检查是否有权限访问指定Tab
    private func hasAccessToTab(_ tab: ReportTab) -> Bool {
        guard let feature = premiumFeature(for: tab) else { return true }
        return appState.subscriptionManager.hasAccess(to: feature)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义导航栏 - 无胶囊背景
                CustomNavigationBar(title: nil) {
                    // 导出按钮 - 高级功能
                    Button {
                        if appState.subscriptionManager.hasAccess(to: .exportData) {
                            exportReportCSV()
                        } else {
                            HapticManager.light()
                            showSubscriptionSheet = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            if !appState.subscriptionManager.hasAccess(to: .exportData) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                
                // 报表Tab选择器
                reportTabPicker
                
                ScrollView {
                    VStack(spacing: Spacing.m) {
                        // 周期选择器 (按周/按月/按年) - 仅在总览和对比Tab显示
                        if selectedTab == .overview || selectedTab == .comparison || selectedTab == .account {
                            ReportPeriodPicker(selectedPeriod: $selectedPeriod, selectedDate: $selectedDate)
                                .onChange(of: selectedDate) { oldValue, newValue in
                                    loadData()
                                }
                                .onChange(of: selectedPeriod) { oldValue, newValue in
                                    loadData()
                                }
                                .padding(.top, Spacing.s)
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 50)
                        } else {
                            // 根据选中的Tab显示不同内容
                            switch selectedTab {
                            case .overview:
                                overviewContent
                            case .comparison:
                                comparisonContent
                            case .trend:
                                trendContent
                            case .account:
                                accountContent
                            }
                        }
                    }
                    .padding(.bottom, Layout.tabBarBottomPadding)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadData()
            }
            .onChange(of: appState.currentLedger) { oldValue, newValue in
                // 账本切换时重新加载数据
                loadData()
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionView()
            }
        }
    }
    
    // MARK: - Tab选择器
    
    private var reportTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(ReportTab.allCases, id: \.self) { tab in
                    let needsPremium = isPremiumTab(tab) && !hasAccessToTab(tab)
                    
                    Button {
                        if needsPremium {
                            // 无权限，显示订阅页面
                            HapticManager.light()
                            showSubscriptionSheet = true
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = tab
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                            
                            // 显示高级功能徽章
                            if needsPremium {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                            }
                        }
                        .foregroundStyle(selectedTab == tab ? .white : .primary)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.s)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.blue : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 总览内容
    
    private var overviewContent: some View {
        VStack(spacing: Spacing.m) {
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
    
    // MARK: - 对比分析内容
    
    private var comparisonContent: some View {
        VStack(spacing: Spacing.m) {
            // 对比类型选择
            Picker("对比类型", selection: $comparisonType) {
                Text("月度对比").tag(ComparisonReportView.ComparisonType.monthOverMonth)
                Text("年度同比").tag(ComparisonReportView.ComparisonType.yearOverYear)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.m)
            
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
            
            // 对比报表
            if let momExpense = viewModel.monthOverMonthExpense,
               let momIncome = viewModel.monthOverMonthIncome,
               let yoyExpense = viewModel.yearOverYearExpense,
               let yoyIncome = viewModel.yearOverYearIncome {
                
                ComparisonReportView(
                    expenseComparison: comparisonType == .monthOverMonth ? momExpense : yoyExpense,
                    incomeComparison: comparisonType == .monthOverMonth ? momIncome : yoyIncome,
                    categoryComparisons: comparisonType == .monthOverMonth ? viewModel.monthCategoryComparisons : viewModel.yearCategoryComparisons,
                    comparisonType: comparisonType,
                    reportType: viewModel.reportType
                )
            } else {
                emptyComparisonView
            }
        }
    }
    
    private var emptyComparisonView: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("暂无对比数据")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("需要至少两个周期的数据才能进行对比分析")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
    
    // MARK: - 趋势内容
    
    private var trendContent: some View {
        VStack(spacing: Spacing.m) {
            // 净资产趋势图
            NetAssetTrendView(
                data: viewModel.monthlyAssetTrend,
                selectedRange: viewModel.assetTrendRange,
                onRangeChange: { newRange in
                    viewModel.updateAssetTrendRange(
                        newRange,
                        accounts: filteredAccounts,
                        transactions: filteredTransactions
                    )
                }
            )
            .padding(.top, Spacing.m)
        }
    }
    
    // MARK: - 账户统计内容
    
    private var accountContent: some View {
        VStack(spacing: Spacing.m) {
            // 账户统计
            AccountStatisticsView(data: viewModel.accountStatistics)
        }
    }
    
    // MARK: - 过滤后的数据
    
    private var filteredTransactions: [Transaction] {
        if let currentLedger = appState.currentLedger {
            return transactions.filter { $0.ledger?.id == currentLedger.id }
        }
        return transactions
    }
    
    private var filteredAccounts: [Account] {
        if let currentLedger = appState.currentLedger {
            return accounts.filter { $0.ledger?.id == currentLedger.id }
        }
        return accounts
    }
    
    // MARK: - 汇总卡片
    
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
