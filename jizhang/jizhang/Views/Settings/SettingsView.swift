//
//  SettingsView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
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
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("账本管理")
                        }
                    }
                }
                
                // 当前账本设置
                Section("当前账本设置") {
                    NavigationLink {
                        AccountManagementView()
                    } label: {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.green)
                                .frame(width: 30)
                            Text("账户管理")
                        }
                    }
                    
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            Text("分类管理")
                        }
                    }
                    
                    NavigationLink {
                        BudgetView()
                    } label: {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text("预算管理")
                        }
                    }
                }
                
                // 数据
                Section("数据") {
                    NavigationLink {
                        CloudSyncStatusDetailView(cloudKitService: appState.cloudKitService)
                    } label: {
                        HStack {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("iCloud同步")
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
                        HStack {
                            Image(systemName: "flask.fill")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text("填充测试数据")
                        }
                    }
                    #endif
                    
                    // 重置账本
                    NavigationLink {
                        ResetLedgersView()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            Text("重置账本")
                        }
                    }
                    
                    // 删除账本
                    NavigationLink {
                        DeleteLedgersView()
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 30)
                            Text("删除账本")
                        }
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppState())
}
