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
    
    @State private var showExportSheet = false
    @State private var csvContent = ""
    
    init() {
        // 临时初始化一个空的 ModelContext，实际会在 onAppear 中使用环境中的 modelContext
        let container = try! ModelContainer(for: Transaction.self, Account.self)
        _viewModel = StateObject(wrappedValue: ReportViewModel(modelContext: container.mainContext))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    // 时间范围选择器
                    TimeRangePicker(
                        selectedRange: Binding(
                            get: { viewModel.selectedRange },
                            set: { viewModel.selectedRange = $0; loadData() }
                        ),
                        customStartDate: Binding(
                            get: { viewModel.customStartDate },
                            set: { viewModel.customStartDate = $0 }
                        ),
                        customEndDate: Binding(
                            get: { viewModel.customEndDate },
                            set: { viewModel.customEndDate = $0 }
                        )
                    )
                    .padding(.top, Spacing.s)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // 汇总卡片 - 随手记风格渐变卡片
                        ReportSummaryGradientCard(
                            income: viewModel.totalIncome,
                            expense: viewModel.totalExpense,
                            balance: viewModel.netAmount
                        )
                        
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
                        IncomeExpenseChartView(data: viewModel.dailyData, reportType: viewModel.reportType)
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    LedgerSwitcher()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            exportCSV()
                        } label: {
                            Label("导出CSV", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ActivityViewController(activityItems: [csvContent])
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
    
    private func loadData() {
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
    
    private func exportCSV() {
        // 筛选时间范围内的交易
        let range = viewModel.dateRange
        var filteredTransactions = transactions.filter { transaction in
            transaction.date >= range.start && transaction.date <= range.end
        }
        
        // 按当前账本过滤
        if let currentLedger = appState.currentLedger {
            filteredTransactions = filteredTransactions.filter { $0.ledger?.id == currentLedger.id }
        }
        
        csvContent = viewModel.exportCSV(transactions: filteredTransactions)
        showExportSheet = true
    }
}

// MARK: - ActivityViewController

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    ReportView()
        .modelContainer(for: [Transaction.self, Account.self])
}
