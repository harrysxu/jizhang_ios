//
//  HomeView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    // MARK: - Query
    
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var ledgers: [Ledger]
    
    // MARK: - Computed Properties
    
    /// 当前账本的交易记录（已过滤）
    private var currentLedgerTransactions: [Transaction] {
        guard let currentLedger = appState.currentLedger else {
            return transactions
        }
        return transactions.filter { $0.ledger?.id == currentLedger.id }
    }
    
    private var totalAssets: Decimal {
        appState.currentLedger?.totalAssets ?? 0
    }
    
    private var todayExpense: Decimal {
        currentLedgerTransactions
            .filter { $0.type == .expense && $0.date.isToday }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var monthIncome: Decimal {
        currentLedgerTransactions
            .filter { $0.type == .income && $0.date.isThisMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var monthExpense: Decimal {
        currentLedgerTransactions
            .filter { $0.type == .expense && $0.date.isThisMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var recentTransactions: [Transaction] {
        Array(currentLedgerTransactions.prefix(20))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    // 净资产卡片 (毛玻璃效果)
                    NetAssetCard(
                        totalAssets: totalAssets,
                        monthIncome: monthIncome,
                        monthExpense: monthExpense
                    )
                    .padding(.top, Spacing.m)
                    
                    // 今日支出卡片
                    TodayExpenseCard(todayExpense: todayExpense)
                    
                    // 最近7日支出趋势图
                    SevenDayExpenseChart(
                        data: SevenDayExpenseChart.generateData(from: currentLedgerTransactions)
                    )
                    
                    // 流水列表
                    TransactionListSection(transactions: recentTransactions)
                }
                .padding(.bottom, 80) // 为底部TabBar留出空间
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    LedgerSwitcher(displayMode: .fullName)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .onAppear {
                // 仅在没有账本数据时初始化
                if ledgers.isEmpty {
                    createDefaultLedger()
                }
            }
            .onChange(of: appState.currentLedger) { oldValue, newValue in
                // 账本切换时，视图会自动重新计算所有计算属性
                // 无需手动刷新，因为我们使用的是响应式数据绑定
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createDefaultLedger() {
        let ledger = Ledger(name: "日常账本", isDefault: true)
        modelContext.insert(ledger)
        
        // 创建默认分类
        ledger.createDefaultCategories()
        
        // 创建默认账户
        ledger.createDefaultAccounts()
        
        do {
            try modelContext.save()
            // 创建完成后，立即设置为当前账本
            appState.currentLedger = ledger
            print("✅ 创建并设置默认账本: \(ledger.name)")
        } catch {
            print("⚠️ 保存默认账本失败: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [Ledger.self, Account.self, Category.self, Transaction.self, Budget.self, Tag.self])
        .environment(AppState())
}
