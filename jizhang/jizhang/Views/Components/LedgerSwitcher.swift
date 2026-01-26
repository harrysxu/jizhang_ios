//
//  LedgerSwitcher.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import SwiftUI
import SwiftData

/// 账本切换器显示模式
enum LedgerSwitcherDisplayMode {
    case iconOnly      // 仅图标 (用于导航栏)
    case fullName      // 完整名称 (用于其他场景)
}

/// 账本切换器 - 用于导航栏显示和切换账本
struct LedgerSwitcher: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Ledger.sortOrder) private var ledgers: [Ledger]
    
    @State private var showLedgerPicker = false
    
    /// 显示模式
    let displayMode: LedgerSwitcherDisplayMode
    
    /// 初始化
    /// - Parameter displayMode: 显示模式，默认为fullName
    init(displayMode: LedgerSwitcherDisplayMode = .fullName) {
        self.displayMode = displayMode
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // 直接显示账本名称，不使用按钮包装
            Text(appState.currentLedger?.name ?? "选择账本")
                .font(.system(size: 16))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            // 箭头朝右
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: true, vertical: false)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.light()
            showLedgerPicker = true
        }
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

#Preview("Icon Only Mode") {
    VStack(spacing: 20) {
        LedgerSwitcher(displayMode: .iconOnly)
        Text("图标模式 - 用于导航栏")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .modelContainer(for: [Ledger.self])
    .environment(AppState())
}

#Preview("Full Name Mode") {
    VStack(spacing: 20) {
        LedgerSwitcher(displayMode: .fullName)
        Text("完整名称模式 - 用于其他场景")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .modelContainer(for: [Ledger.self])
    .environment(AppState())
}

