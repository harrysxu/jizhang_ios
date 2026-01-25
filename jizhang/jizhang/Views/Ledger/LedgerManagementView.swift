//
//  LedgerManagementView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

struct LedgerManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        LedgerManagementContentView(modelContext: modelContext)
    }
}

private struct LedgerManagementContentView: View {
    let modelContext: ModelContext
    @StateObject private var viewModel: LedgerViewModel
    
    @Query(sort: \Ledger.sortOrder) private var ledgers: [Ledger]
    
    @State private var showDeleteAlert = false
    @State private var ledgerToDelete: Ledger?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = StateObject(wrappedValue: LedgerViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        List {
            // 活跃账本
            Section("活跃账本") {
                if activeLedgers.isEmpty {
                    Text("还没有账本")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeLedgers) { ledger in
                        ledgerRow(ledger)
                    }
                }
            }
            
            // 归档账本
            if !archivedLedgers.isEmpty {
                Section("归档账本") {
                    ForEach(archivedLedgers) { ledger in
                        ledgerRow(ledger)
                    }
                }
            }
        }
        .navigationTitle("账本管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showCreateLedger()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showLedgerForm },
            set: { if !$0 { viewModel.showLedgerForm = false } }
        )) {
            if let ledger = viewModel.selectedLedger {
                LedgerFormSheet(ledger: ledger, viewModel: viewModel)
            } else {
                LedgerFormSheet(ledger: nil, viewModel: viewModel)
            }
        }
        .alert("删除账本", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let ledger = ledgerToDelete {
                    deleteLedger(ledger)
                }
            }
        } message: {
            if let ledger = ledgerToDelete {
                Text("确定要删除\"\(ledger.name)\"吗?此操作无法撤销。")
            }
        }
    }
    
    private var activeLedgers: [Ledger] {
        ledgers.filter { !$0.isArchived }
    }
    
    private var archivedLedgers: [Ledger] {
        ledgers.filter { $0.isArchived }
    }
    
    private func ledgerRow(_ ledger: Ledger) -> some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color(hex: ledger.colorHex).opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: ledger.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: ledger.colorHex))
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(ledger.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if ledger.isDefault {
                        Text("默认")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primaryBlue)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("\(ledger.activeAccountsCount) 个账户")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(ledger.thisMonthTransactionCount) 笔交易")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if ledger.isArchived {
                Text("已归档")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // 菜单按钮
            Menu {
                // 编辑
                Button {
                    viewModel.showEditLedger(ledger)
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                
                // 设为默认（仅非默认账本显示）
                if !ledger.isDefault {
                    Button {
                        setAsDefault(ledger)
                    } label: {
                        Label("设为默认", systemImage: "star.fill")
                    }
                }
                
                Divider()
                
                // 归档/取消归档
                if ledger.isArchived {
                    Button {
                        unarchiveLedger(ledger)
                    } label: {
                        Label("取消归档", systemImage: "arrow.uturn.backward")
                    }
                } else {
                    Button {
                        archiveLedger(ledger)
                    } label: {
                        Label("归档", systemImage: "archivebox")
                    }
                }
                
                Divider()
                
                // 删除
                Button(role: .destructive) {
                    ledgerToDelete = ledger
                    showDeleteAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .frame(width: 44, height: 44)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.showEditLedger(ledger)
        }
    }
    
    private func deleteLedger(_ ledger: Ledger) {
        do {
            try viewModel.deleteLedger(ledger)
        } catch {
            // 显示错误
            print("删除账本失败: \(error)")
        }
    }
    
    private func archiveLedger(_ ledger: Ledger) {
        do {
            try viewModel.archiveLedger(ledger)
        } catch {
            print("归档账本失败: \(error)")
        }
    }
    
    private func unarchiveLedger(_ ledger: Ledger) {
        do {
            try viewModel.unarchiveLedger(ledger)
        } catch {
            print("取消归档失败: \(error)")
        }
    }
    
    private func setAsDefault(_ ledger: Ledger) {
        do {
            try viewModel.setDefaultLedger(ledger)
        } catch {
            print("设置默认账本失败: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        LedgerManagementView()
            .modelContainer(for: Ledger.self)
    }
}
