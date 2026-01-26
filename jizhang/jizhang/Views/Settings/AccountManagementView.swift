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
                            AccountRowButton(account: account) {
                                accountToEdit = account
                            }
                        }
                        .onDelete { indexSet in
                            deleteAccounts(at: indexSet, from: assetAccounts)
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
                            AccountRowButton(account: account) {
                                accountToEdit = account
                            }
                        }
                        .onDelete { indexSet in
                            deleteAccounts(at: indexSet, from: liabilityAccounts)
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
        .navigationTitle("账户管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LedgerSwitcher(displayMode: .fullName)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddAccount = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddAccount) {
            AccountFormSheet(account: nil)
        }
        .sheet(item: $accountToEdit) { account in
            AccountFormSheet(account: account)
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
    
    private func deleteAccounts(at offsets: IndexSet, from accounts: [Account]) {
        for index in offsets {
            let account = accounts[index]
            
            // 检查是否有关联交易
            if !account.outgoingTransactions.isEmpty || !account.incomingTransactions.isEmpty {
                // TODO: 显示警告,无法删除有交易的账户
                continue
            }
            
            modelContext.delete(account)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Account Row Button

private struct AccountRowButton: View {
    let account: Account
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                // 图标 (无圆形背景，直接展示图案)
                Image(systemName: account.iconName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color(hex: account.colorHex))
                    .frame(width: 44, height: 44)
                
                // 账户信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(account.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if account.type == .creditCard {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("可用 \(account.availableBalance.formatAmount())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 余额
                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.balance.formatAmount())
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(account.balance < 0 ? .expenseRed : .primary)
                        .monospacedDigit()
                    
                    if account.type == .creditCard, let limit = account.creditLimit {
                        Text("额度 \(limit.formatAmount())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
