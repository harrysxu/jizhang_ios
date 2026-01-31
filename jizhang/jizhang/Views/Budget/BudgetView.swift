//
//  BudgetView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        BudgetContentView(modelContext: modelContext)
    }
}

private struct BudgetContentView: View {
    let modelContext: ModelContext
    @Environment(AppState.self) private var appState
    @Environment(\.hideTabBar) private var hideTabBar
    @StateObject private var viewModel: BudgetViewModel
    
    @Query(sort: \Budget.createdAt, order: .reverse) private var allBudgets: [Budget]
    @State private var showSubscriptionSheet = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = StateObject(wrappedValue: BudgetViewModel(modelContext: modelContext))
    }
    
    // 过滤当前账本的预算
    private var budgets: [Budget] {
        guard let currentLedger = appState.currentLedger else { return [] }
        return allBudgets.filter { $0.ledger?.id == currentLedger.id }
    }
    
    // Computed properties to simplify type checking
    private var totalBudget: Decimal {
        viewModel.calculateTotalBudget(budgets: budgets)
    }
    
    private var totalUsed: Decimal {
        viewModel.calculateTotalUsed(budgets: budgets)
    }
    
    private var remainingDays: Int {
        viewModel.remainingDaysInMonth()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义导航栏
                SubPageNavigationBar(title: "预算管理") {
                    Button {
                        if appState.subscriptionManager.hasAccess(to: .budgetManagement) {
                            viewModel.showCreateBudget()
                        } else {
                            HapticManager.light()
                            showSubscriptionSheet = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 18))
                            if !appState.subscriptionManager.hasAccess(to: .budgetManagement) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                
                ScrollView {
                    contentView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: budgetFormBinding) {
                budgetFormContent
            }
            .sheet(isPresented: budgetDetailBinding) {
                budgetDetailContent
            }
            .alert("错误", isPresented: errorBinding) {
                Button("确定", role: .cancel) { }
            } message: {
                errorMessageContent
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionView()
            }
            .onAppear {
                setupViewModel()
                hideTabBar.wrappedValue = true
            }
            .onDisappear {
                hideTabBar.wrappedValue = false
            }
        }
    }
    
    // MARK: - Subviews
    
    private var contentView: some View {
        VStack(spacing: Spacing.m) {
            if !budgets.isEmpty {
                budgetListContent
            } else {
                emptyStateView
            }
        }
        .padding(.bottom, Spacing.l)
    }
    
    private var budgetListContent: some View {
        Group {
            // 总预算概览
            BudgetOverviewCard(
                totalBudget: totalBudget,
                totalUsed: totalUsed,
                remainingDays: remainingDays
            )
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)
            
            // 分类预算标题
            HStack {
                Text("分类预算")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.m)
            
            // 预算卡片列表
            ForEach(budgets.sorted(by: { $0.progress > $1.progress })) { budget in
                BudgetCardView(budget: budget) {
                    if appState.subscriptionManager.hasAccess(to: .budgetManagement) {
                        viewModel.showDetails(budget)
                    } else {
                        HapticManager.light()
                        showSubscriptionSheet = true
                    }
                }
                .padding(.horizontal, Spacing.m)
            }
        }
    }
    
    private var budgetFormBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showBudgetForm },
            set: { if !$0 { viewModel.showBudgetForm = false } }
        )
    }
    
    private var budgetDetailBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showBudgetDetail },
            set: { if !$0 { viewModel.showBudgetDetail = false } }
        )
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showError },
            set: { if !$0 { viewModel.showError = false } }
        )
    }
    
    @ViewBuilder
    private var budgetFormContent: some View {
        BudgetFormSheet(budget: viewModel.selectedBudget, viewModel: viewModel)
    }
    
    @ViewBuilder
    private var budgetDetailContent: some View {
        if let budget = viewModel.selectedBudget {
            BudgetDetailView(budget: budget, viewModel: viewModel)
        }
    }
    
    @ViewBuilder
    private var errorMessageContent: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
        }
    }
    
    private func setupViewModel() {
        // 检查并执行预算结转
        viewModel.checkAndRolloverBudgets(budgets: budgets)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("还没有预算")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("为不同分类设置预算,更好地控制支出")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            PrimaryActionButton("创建预算", icon: "plus.circle.fill") {
                if appState.subscriptionManager.hasAccess(to: .budgetManagement) {
                    viewModel.showCreateBudget()
                } else {
                    HapticManager.light()
                    showSubscriptionSheet = true
                }
            }
            .padding(.top, Spacing.m)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: [Budget.self, Category.self, Ledger.self])
}
