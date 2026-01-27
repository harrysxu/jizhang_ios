//
//  LedgerPickerSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

struct LedgerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    
    @Binding var currentLedger: Ledger?
    var onSelect: ((Ledger) -> Void)?
    
    @State private var showLedgerManagement = false
    @State private var showLedgerForm = false
    
    private var viewModel: LedgerViewModel {
        LedgerViewModel(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SimpleCancelNavigationBar(title: "选择账本")
            
            List {
                // 账本列表
                Section {
                    ForEach(activeLedgers) { ledger in
                        ledgerButton(for: ledger)
                    }
                } header: {
                    Text("我的账本")
                }
                
                // 操作按钮
                Section {
                    Button {
                        showLedgerForm = true
                    } label: {
                        Label("新建账本", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Button {
                        showLedgerManagement = true
                    } label: {
                        Label("管理账本", systemImage: "gear")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showLedgerForm) {
            LedgerFormSheet(ledger: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showLedgerManagement) {
            LedgerManagementView()
        }
    }
    
    private var activeLedgers: [Ledger] {
        ledgers.filter { !$0.isArchived }.sorted(by: { $0.sortOrder < $1.sortOrder })
    }
    
    private func ledgerButton(for ledger: Ledger) -> some View {
        Button {
            HapticManager.selection()
            currentLedger = ledger
            onSelect?(ledger)
            
            // 延迟关闭,让用户看到选中效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        } label: {
            ledgerRow(for: ledger)
        }
        .buttonStyle(.plain)
    }
    
    private func ledgerRow(for ledger: Ledger) -> some View {
        HStack(spacing: 16) {
            // 账本图标（圆形背景）
            ledgerIcon(for: ledger)
            
            // 账本信息
            VStack(alignment: .leading, spacing: 6) {
                Text(ledger.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                // 统计信息
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 11))
                        Text("\(ledger.activeAccountsCount)个账户")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 11))
                        Text("\(ledger.thisMonthTransactionCount)笔交易")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 选中标记
            if currentLedger?.id == ledger.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func ledgerIcon(for ledger: Ledger) -> some View {
        ZStack {
            // 圆形背景色块 (参考UI样式)
            Circle()
                .fill(Color(hex: ledger.colorHex))
                .frame(width: 48, height: 48)
            
            // 白色图标
            Image(systemName: ledger.iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
        }
        .shadow(color: Color(hex: ledger.colorHex).opacity(0.3), radius: 4, y: 2)
    }
}

#Preview {
    @Previewable @State var currentLedger: Ledger? = Ledger(name: "日常账本")
    
    LedgerPickerSheet(currentLedger: $currentLedger)
        .modelContainer(for: Ledger.self)
}
