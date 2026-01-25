//
//  LedgerSwitcher.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import SwiftUI
import SwiftData

/// 账本切换器 - 用于导航栏显示和切换账本
struct LedgerSwitcher: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Ledger.sortOrder) private var ledgers: [Ledger]
    
    @State private var showLedgerPicker = false
    
    var body: some View {
        Button(action: {
            showLedgerPicker = true
        }) {
            HStack(spacing: 6) {
                // 账本名称
                Text(appState.currentLedger?.name ?? "选择账本")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                
                // 下拉箭头
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
            }
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

#Preview {
    LedgerSwitcher()
        .modelContainer(for: [Ledger.self])
        .environment(AppState())
}

