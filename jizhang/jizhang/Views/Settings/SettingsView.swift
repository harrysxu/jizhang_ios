//
//  SettingsView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//
//  设置页面
//

import SwiftUI
import SwiftData

/// 设置页面
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    
    @State private var showSubscriptionSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义导航栏 - 无胶囊背景，无标题
                CustomNavigationBar(title: nil) {
                    EmptyView()
                }
                
                List {
                    // 订阅状态
                    Section {
                        subscriptionStatusRow
                    }
                    
                    // 当前账本设置
                    Section("当前账本设置") {
                        // 账户管理 - 高级功能
                        PremiumNavigationLink(feature: .accountManagement) {
                            AccountManagementView()
                        } label: {
                            SettingsRow(
                                iconName: "creditCard",
                                iconColor: .green,
                                title: "账户管理"
                            )
                        }
                        
                        // 分类管理 - 高级功能
                        PremiumNavigationLink(feature: .categoryManagement) {
                            CategoryManagementView()
                        } label: {
                            SettingsRow(
                                iconName: "folder",
                                iconColor: .orange,
                                title: "分类管理"
                            )
                        }
                        
                        // 预算管理 - 高级功能
                        PremiumNavigationLink(feature: .budgetManagement) {
                            BudgetView()
                        } label: {
                            SettingsRow(
                                iconName: "piggyBank",
                                iconColor: .purple,
                                title: "预算管理"
                            )
                        }
                    }
                    
                    // 数据
                    Section("数据") {
                        NavigationLink {
                            CloudSyncStatusDetailView(cloudKitService: appState.cloudKitService)
                        } label: {
                            HStack {
                                SettingsRow(
                                    iconName: "cloud",
                                    iconColor: .blue,
                                    title: "iCloud同步"
                                )
                                Spacer()
                                CloudSyncStatusView(cloudKitService: appState.cloudKitService, showText: false)
                            }
                        }
                    }
                    
                    // 数据管理
                    Section("数据管理") {
                        // 测试数据填充（仅在DEBUG模式显示）
                        #if DEBUG
                        NavigationLink {
                            TestDataGeneratorView()
                        } label: {
                            SettingsRow(
                                iconName: "flask",
                                iconColor: .purple,
                                title: "填充测试数据"
                            )
                        }
                        #endif
                        
                        // 导出账本 - 高级功能
                        PremiumNavigationLink(feature: .exportLedger) {
                            LedgerExportView()
                        } label: {
                            SettingsRow(
                                iconName: "upload",
                                iconColor: .blue,
                                title: "导出账本"
                            )
                        }
                        
                        // 导入账本 - 高级功能
                        PremiumNavigationLink(feature: .importLedger) {
                            LedgerImportView()
                        } label: {
                            SettingsRow(
                                iconName: "download",
                                iconColor: .green,
                                title: "导入账本"
                            )
                        }
                        
                        // 重置账本 - 高级功能
                        PremiumNavigationLink(feature: .resetLedger) {
                            ResetLedgersView()
                        } label: {
                            SettingsRow(
                                iconName: "arrowCounterClockwise",
                                iconColor: .orange,
                                title: "重置账本"
                            )
                        }
                        
                        // 删除账本 - 高级功能
                        PremiumNavigationLink(feature: .deleteLedger) {
                            DeleteLedgersView()
                        } label: {
                            SettingsRow(
                                iconName: "trash",
                                iconColor: .red,
                                title: "删除账本"
                            )
                        }
                    }
                }
                .contentMargins(.bottom, Layout.tabBarBottomPadding, for: .scrollContent)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionView()
            }
        }
    }
    
    // MARK: - Subscription Status Row
    
    private var subscriptionStatusRow: some View {
        Button {
            showSubscriptionSheet = true
        } label: {
            HStack(spacing: Spacing.m) {
                // 图标
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        appState.subscriptionManager.subscriptionStatus.isPremium
                        ? LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.gray, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 30)
                
                // 状态文字
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.subscriptionManager.subscriptionStatus.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if appState.subscriptionManager.subscriptionStatus.isPremium {
                        if case .premium(let expiresAt) = appState.subscriptionManager.subscriptionStatus,
                           let expiry = expiresAt {
                            Text("有效期至 \(expiry.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if case .lifetime = appState.subscriptionManager.subscriptionStatus {
                            Text("终身有效")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("点击升级解锁全部功能")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // 右侧指示
                if !appState.subscriptionManager.subscriptionStatus.isPremium {
                    Text("升级")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack {
            PhosphorIcon.icon(named: iconName, weight: .fill)
                .frame(width: 22, height: 22)
                .foregroundStyle(iconColor)
                .frame(width: 30)
            
            Text(title)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppState())
}
