//
//  SideMenuView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI
import SwiftData

// MARK: - Side Menu View

/// 侧滑菜单 (参考UI样式)
struct SideMenuView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query private var ledgers: [Ledger]
    
    // MARK: - State
    
    @State private var showSettings = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 用户信息区域
                    userInfoSection
                        .padding(.top, Spacing.l)
                        .padding(.horizontal, Spacing.l)
                    
                    Divider()
                        .padding(.vertical, Spacing.l)
                    
                    // 我的账本
                    ledgerSection
                    
                    Divider()
                        .padding(.vertical, Spacing.l)
                    
                    // 功能入口
                    functionSection
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("菜单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - User Info Section
    
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            // 头像
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.primaryBlue, Color.primaryBlue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                )
            
            // 用户名
            Text("用户")
                .font(.title2)
                .fontWeight(.semibold)
            
            // VIP标识
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                
                Text("已使用 1 天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Ledger Section
    
    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            HStack {
                Text("我的账本")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NavigationLink(destination: LedgerManagementView()) {
                    HStack(spacing: 4) {
                        Text("管理")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.s)
            
            // 账本列表
            ForEach(ledgers.filter { !$0.isArchived }) { ledger in
                LedgerRow(
                    ledger: ledger,
                    isSelected: appState.currentLedger?.id == ledger.id
                ) {
                    appState.currentLedger = ledger
                }
            }
        }
    }
    
    // MARK: - Function Section
    
    private var functionSection: some View {
        VStack(spacing: 0) {
            // 功能项
            FunctionRow(
                icon: "gearshape.fill",
                title: "设置",
                iconColor: .gray
            ) {
                showSettings = true
            }
        }
    }
}

// MARK: - Ledger Row

private struct LedgerRow: View {
    let ledger: Ledger
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            HStack(spacing: Spacing.m) {
                // 圆形账本图标 (参考UI样式)
                ZStack {
                    Circle()
                        .fill(Color(hex: ledger.colorHex))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: ledger.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: Color(hex: ledger.colorHex).opacity(0.3), radius: 4, y: 2)
                
                // 账本信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(ledger.name)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(.primary)
                    
                    if ledger.isDefault {
                        Text("默认账本")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.primaryBlue)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(isSelected ? Color.primaryBlue.opacity(0.05) : Color.clear)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Function Row

private struct FunctionRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                // 图标
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    )
                
                // 标题
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SideMenuView()
        .modelContainer(for: [Ledger.self, Account.self, Category.self])
        .environment(AppState())
}
