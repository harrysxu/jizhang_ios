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
        NavigationStack {
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
            .navigationTitle("选择账本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showLedgerForm) {
                LedgerFormSheet(ledger: nil, viewModel: viewModel)
            }
            .sheet(isPresented: $showLedgerManagement) {
                LedgerManagementView()
            }
        }
    }
    
    private var activeLedgers: [Ledger] {
        ledgers.filter { !$0.isArchived }.sorted(by: { $0.sortOrder < $1.sortOrder })
    }
    
    private func ledgerButton(for ledger: Ledger) -> some View {
        Button {
            currentLedger = ledger
            onSelect?(ledger)
            dismiss()
        } label: {
            ledgerRow(for: ledger)
        }
        .buttonStyle(.plain)
    }
    
    private func ledgerRow(for ledger: Ledger) -> some View {
        HStack(spacing: 12) {
            // 账本图标
            ledgerIcon(for: ledger)
            
            // 账本信息
            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                // 统计信息
                HStack(spacing: 12) {
                    Label("\(ledger.activeAccountsCount)个账户", systemImage: "creditcard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Label("\(ledger.thisMonthTransactionCount)笔交易", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 选中标记
            if currentLedger?.id == ledger.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func ledgerIcon(for ledger: Ledger) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: ledger.colorHex).opacity(0.15))
                .frame(width: 44, height: 44)
            
            Image(systemName: ledger.iconName)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: ledger.colorHex))
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("取消") {
                dismiss()
            }
        }
    }
}

#Preview {
    @Previewable @State var currentLedger: Ledger? = Ledger(name: "日常账本")
    
    LedgerPickerSheet(currentLedger: $currentLedger)
        .modelContainer(for: Ledger.self)
}
