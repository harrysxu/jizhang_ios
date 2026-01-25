//
//  jizhangApp.swift
//  jizhang
//
//  Created by 徐晓龙 on 2026/1/24.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct jizhangApp: App {
    // MARK: - Properties
    
    /// 全局应用状态(包含ModelContainer和CloudKit服务)
    @State private var appState = AppState()
    
    /// 是否显示记账Sheet
    @State private var showAddTransactionSheet = false
    
    /// 监听App生命周期
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            TabBarView()
                .environment(appState)
                .sheet(isPresented: $showAddTransactionSheet) {
                    // 从Widget跳转过来的记账页面
                    AddTransactionSheet()
                        .environment(appState)
                }
                .onOpenURL { url in
                    handleURL(url)
                }
                .onAppear {
                    // 启动时加载默认账本
                    loadDefaultLedgerIfNeeded()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // App回到前台时验证账本状态
                    if newPhase == .active {
                        Task { @MainActor in
                            validateAndLoadLedger()
                        }
                    }
                }
        }
        .modelContainer(appState.modelContainer)
    }
    
    // MARK: - URL Handling
    
    /// 处理URL Scheme
    private func handleURL(_ url: URL) {
        guard url.scheme == "jizhang" else { return }
        
        switch url.host {
        case "add-transaction":
            // 打开记账页面
            showAddTransactionSheet = true
            
        case "home":
            // 跳转到首页 (默认行为，无需处理)
            break
            
        default:
            break
        }
    }
    
    // MARK: - Ledger Management
    
    /// 首次启动时加载默认账本
    @MainActor
    private func loadDefaultLedgerIfNeeded() {
        // 等待一个RunLoop，确保数据库已经完全初始化
        Task {
            // 如果没有当前账本，则加载默认账本
            if appState.currentLedger == nil {
                appState.currentLedger = appState.loadDefaultLedger()
                print("✅ 加载默认账本: \(appState.currentLedger?.name ?? "无")")
            }
        }
    }
    
    /// 验证并加载账本（App回到前台时调用）
    @MainActor
    private func validateAndLoadLedger() {
        // 检查当前账本是否仍然有效
        if let currentLedger = appState.currentLedger {
            // 验证账本是否被归档或删除
            let context = appState.modelContainer.mainContext
            let ledgerId = currentLedger.id  // 先提取ID，避免在Predicate中捕获对象
            let descriptor = FetchDescriptor<Ledger>(
                predicate: #Predicate<Ledger> { 
                    $0.id == ledgerId
                }
            )
            
            if let ledger = try? context.fetch(descriptor).first {
                // 如果账本被归档，切换到其他可用账本
                if ledger.isArchived {
                    appState.currentLedger = appState.loadDefaultLedger()
                }
                // 如果账本仍然有效，保持当前选择
            } else {
                // 账本已被删除，加载默认账本
                appState.currentLedger = appState.loadDefaultLedger()
            }
        } else {
            // 没有当前账本，加载默认账本
            appState.currentLedger = appState.loadDefaultLedger()
        }
    }
}

// MARK: - Global Widget Refresh Helper

/// 刷新所有Widget的全局方法
func refreshAllWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
}
