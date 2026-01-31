//
//  AccountManagementView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 账户管理视图
struct AccountManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.hideTabBar) private var hideTabBar
    
    @Query private var allAccounts: [Account]
    
    @State private var showAddAccount = false
    @State private var accountToEdit: Account?
    @State private var accountToDelete: Account?
    @State private var showDeleteAlert = false
    @State private var showDeleteErrorAlert = false
    @State private var deleteErrorMessage = ""
    @State private var showSubscriptionSheet = false
    
    // MARK: - Computed Properties
    
    private var currentLedgerAccounts: [Account] {
        guard let ledger = appState.currentLedger else { return [] }
        return allAccounts
            .filter { $0.ledger?.id == ledger.id }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    private var assetAccounts: [Account] {
        currentLedgerAccounts.filter { $0.type.isAsset }
    }
    
    private var liabilityAccounts: [Account] {
        currentLedgerAccounts.filter { !$0.type.isAsset }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SubPageNavigationBar(title: "账户管理") {
                Button {
                    if appState.subscriptionManager.hasAccess(to: .accountManagement) {
                        showAddAccount = true
                    } else {
                        HapticManager.light()
                        showSubscriptionSheet = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                        if !appState.subscriptionManager.hasAccess(to: .accountManagement) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            
            List {
                if currentLedgerAccounts.isEmpty {
                    ContentUnavailableView(
                        "暂无账户",
                        systemImage: "creditcard.fill",
                        description: Text("点击右上角 + 按钮创建第一个账户")
                    )
                } else {
                    // 资产账户
                    if !assetAccounts.isEmpty {
                        Section {
                            ForEach(assetAccounts) { account in
                                AccountRowView(
                                    account: account,
                                    hasAccess: appState.subscriptionManager.hasAccess(to: .accountManagement),
                                    onEdit: { 
                                        if appState.subscriptionManager.hasAccess(to: .accountManagement) {
                                            accountToEdit = account
                                        } else {
                                            HapticManager.light()
                                            showSubscriptionSheet = true
                                        }
                                    },
                                    onDelete: {
                                        if appState.subscriptionManager.hasAccess(to: .accountManagement) {
                                            accountToDelete = account
                                            showDeleteAlert = true
                                        } else {
                                            HapticManager.light()
                                            showSubscriptionSheet = true
                                        }
                                    }
                                )
                            }
                        } header: {
                            HStack {
                                Text("资产账户")
                                Spacer()
                                Text(totalAssets.formatted(.currency(code: "CNY")))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    
                    // 负债账户
                    if !liabilityAccounts.isEmpty {
                        Section {
                            ForEach(liabilityAccounts) { account in
                                AccountRowView(
                                    account: account,
                                    hasAccess: appState.subscriptionManager.hasAccess(to: .accountManagement),
                                    onEdit: { 
                                        if appState.subscriptionManager.hasAccess(to: .accountManagement) {
                                            accountToEdit = account
                                        } else {
                                            HapticManager.light()
                                            showSubscriptionSheet = true
                                        }
                                    },
                                    onDelete: {
                                        if appState.subscriptionManager.hasAccess(to: .accountManagement) {
                                            accountToDelete = account
                                            showDeleteAlert = true
                                        } else {
                                            HapticManager.light()
                                            showSubscriptionSheet = true
                                        }
                                    }
                                )
                            }
                        } header: {
                            HStack {
                                Text("负债账户")
                                Spacer()
                                Text(totalLiabilities.formatted(.currency(code: "CNY")))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddAccount) {
            AccountFormSheet(account: nil)
        }
        .sheet(item: $accountToEdit) { account in
            AccountFormSheet(account: account)
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {
                accountToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let account = accountToDelete {
                    deleteAccount(account)
                }
                accountToDelete = nil
            }
        } message: {
            if let account = accountToDelete {
                Text("确定要删除账户「\(account.name)」吗？此操作无法撤销。")
            }
        }
        .alert("无法删除", isPresented: $showDeleteErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionView()
        }
        .onAppear {
            hideTabBar.wrappedValue = true
        }
        .onDisappear {
            hideTabBar.wrappedValue = false
        }
    }
    
    // MARK: - Computed Values
    
    private var totalAssets: Decimal {
        assetAccounts.reduce(0) { $0 + $1.balance }
    }
    
    private var totalLiabilities: Decimal {
        liabilityAccounts.reduce(0) { $0 + abs($1.balance) }
    }
    
    // MARK: - Methods
    
    private func deleteAccount(_ account: Account) {
        // 检查是否有关联交易
        let transactionCount = (account.outgoingTransactions ?? []).count + (account.incomingTransactions ?? []).count
        if transactionCount > 0 {
            deleteErrorMessage = "账户「\(account.name)」下有 \(transactionCount) 笔交易记录，无法删除。请先删除或转移相关交易。"
            showDeleteErrorAlert = true
            return
        }
        
        modelContext.delete(account)
        
        do {
            try modelContext.save()
        } catch {
            deleteErrorMessage = "删除失败: \(error.localizedDescription)"
            showDeleteErrorAlert = true
        }
    }
}

// MARK: - Account Row View

private struct AccountRowView: View {
    let account: Account
    let hasAccess: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.m) {
            // 图标
            Image(systemName: account.iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color(hex: account.colorHex))
                .frame(width: 40, height: 40)
            
            // 账户信息
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(account.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 余额
            Text(account.balance.formatAmount())
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(account.balance < 0 ? .expenseRed : .primary)
                .monospacedDigit()
            
            // 操作按钮（在最右侧）
            HStack(spacing: Spacing.s) {
                Button(action: onEdit) {
                    HStack(spacing: 2) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(hasAccess ? .primaryBlue : .gray)
                        if !hasAccess {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    HStack(spacing: 2) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(hasAccess ? .red : .gray)
                        if !hasAccess {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AccountManagementView()
    }
    .modelContainer(for: [Account.self, Ledger.self, Transaction.self])
    .environment(AppState())
}
