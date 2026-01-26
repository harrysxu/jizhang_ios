//
//  AccountPickerSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 账户选择器Sheet
struct AccountPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Binding var selectedAccount: Account?
    
    /// 需要排除的账户（用于转账时排除转出账户）
    var excludeAccount: Account? = nil
    
    @Query private var allAccounts: [Account]
    
    // MARK: - Computed Properties
    
    private var currentLedgerAccounts: [Account] {
        guard let ledger = appState.currentLedger else { return [] }
        return allAccounts
            .filter { $0.ledger?.id == ledger.id }
            .filter { excludeAccount == nil || $0.id != excludeAccount?.id }
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
        NavigationStack {
            List {
                if currentLedgerAccounts.isEmpty {
                    ContentUnavailableView(
                        "暂无账户",
                        systemImage: "creditcard.fill",
                        description: Text("请先在设置中创建账户")
                    )
                } else {
                    // 资产账户
                    if !assetAccounts.isEmpty {
                        Section("资产账户") {
                            ForEach(assetAccounts) { account in
                                AccountRowView(
                                    account: account,
                                    isSelected: selectedAccount?.id == account.id
                                ) {
                                    selectedAccount = account
                                    dismiss()
                                }
                            }
                        }
                    }
                    
                    // 负债账户
                    if !liabilityAccounts.isEmpty {
                        Section("负债账户") {
                            ForEach(liabilityAccounts) { account in
                                AccountRowView(
                                    account: account,
                                    isSelected: selectedAccount?.id == account.id
                                ) {
                                    selectedAccount = account
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Account Row View

private struct AccountRowView: View {
    let account: Account
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                // 图标
                Image(systemName: account.type.defaultIcon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 32)
                
                // 账户信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.body)
                    
                    if account.type == .creditCard {
                        // 信用卡显示可用额度
                        let currencyCode = account.ledger?.currencyCode ?? "CNY"
                        Text("可用: \(account.availableBalance.formatted(.currency(code: currencyCode)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        // 其他账户显示类型
                        Text(account.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 余额
                VStack(alignment: .trailing, spacing: 4) {
                    let currencyCode = account.ledger?.currencyCode ?? "CNY"
                    Text(account.balance.formatted(.currency(code: currencyCode)))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(account.balance < 0 ? .red : .primary)
                    
                    // 选中标记
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.blue)
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
    AccountPickerSheet(selectedAccount: .constant(nil))
        .modelContainer(for: [Account.self, Ledger.self])
        .environment(AppState())
}
