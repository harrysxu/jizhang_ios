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
            HStack(spacing: 4) {
                // 账本图标 (如果有)
                if let ledger = appState.currentLedger {
                    Image(systemName: ledger.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: ledger.colorHex))
                }
                
                // 账本名称
                Text(appState.currentLedger?.name ?? "选择账本")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                // 下拉箭头
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: appState.currentLedger?.colorHex ?? "#007AFF").opacity(0.08))
            )
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

