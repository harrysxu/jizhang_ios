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
    @State private var showLedgerPicker = false
    
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
                
                // 当前账本管理
                Section {
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
                } header: {
                    HStack {
                        Text("当前账本")
                            .font(.subheadline)
                            .textCase(nil)
                        
                        Spacer()
                        
                        Button(action: {
                            showLedgerPicker = true
                        }) {
                            HStack(spacing: 4) {
                                if let ledger = appState.currentLedger {
                                    Image(systemName: ledger.iconName)
                                        .font(.caption2)
                                        .foregroundStyle(Color(hex: ledger.colorHex))
                                }
                                
                                Text(appState.currentLedger?.name ?? "未选择")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: appState.currentLedger?.colorHex ?? "#007AFF").opacity(0.1))
                            )
                        }
                    }
                    .padding(.vertical, 4)
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
                    
                    Button {
                        // TODO: 数据导出
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("数据导出")
                            Spacer()
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // 其他
                Section("其他") {
                    Button {
                        // TODO: 关于页面
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            Text("关于")
                            Spacer()
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showLedgerPicker) {
                LedgerPickerSheet(
                    currentLedger: Binding(
                        get: { appState.currentLedger },
                        set: { newLedger in
                            if let ledger = newLedger {
                                appState.currentLedger = ledger
                                appState.saveCurrentLedgerID()
                            }
                        }
                    )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppState())
}
