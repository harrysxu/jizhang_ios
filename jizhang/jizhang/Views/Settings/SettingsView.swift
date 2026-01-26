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
    
    var body: some View {
        NavigationStack {
            List {
                // 账本管理（全局）
                Section("账本") {
                    NavigationLink {
                        LedgerManagementView()
                    } label: {
                        SettingsRow(
                            iconName: "notebook",
                            iconColor: .blue,
                            title: "账本管理"
                        )
                    }
                }
                
                // 当前账本设置
                Section("当前账本设置") {
                    NavigationLink {
                        AccountManagementView()
                    } label: {
                        SettingsRow(
                            iconName: "creditCard",
                            iconColor: .green,
                            title: "账户管理"
                        )
                    }
                    
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        SettingsRow(
                            iconName: "folder",
                            iconColor: .orange,
                            title: "分类管理"
                        )
                    }
                    
                    NavigationLink {
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
                    
                    // 重置账本
                    NavigationLink {
                        ResetLedgersView()
                    } label: {
                        SettingsRow(
                            iconName: "arrowCounterClockwise",
                            iconColor: .orange,
                            title: "重置账本"
                        )
                    }
                    
                    // 删除账本
                    NavigationLink {
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
            .navigationTitle("设置")
        }
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
