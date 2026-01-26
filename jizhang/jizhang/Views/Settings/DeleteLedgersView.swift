//
//  DeleteLedgersView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI
import SwiftData

/// 删除账本视图 - 支持多选和三次确认
struct DeleteLedgersView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.hideTabBar) private var hideTabBar
    
    @Query(sort: \Ledger.sortOrder) private var ledgers: [Ledger]
    
    // MARK: - State
    
    @State private var selectedLedgerIDs: Set<UUID> = []
    @State private var showFirstConfirmation = false
    @State private var showSecondConfirmation = false
    @State private var showFinalConfirmation = false
    @State private var confirmationInput = ""
    
    @State private var isDeleting = false
    @State private var progress: Double = 0
    @State private var progressMessage = ""
    
    @State private var showCompletionAlert = false
    @State private var showErrorAlert = false
    @State private var showLastLedgerAlert = false
    @State private var errorMessage = ""
    @State private var deletedCount = 0
    
    private let requiredConfirmationText = "DELETE"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 警告横幅
                warningBanner
                
                // 账本列表（使用自定义列表而非 List）
                ledgerListContent
            }
        }
        .safeAreaInset(edge: .bottom) {
            // 底部删除按钮 - 固定在底部
            deleteButtonBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("删除账本")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    dismiss()
                }
                .disabled(isDeleting)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if !selectedLedgerIDs.isEmpty {
                    Button("取消选择") {
                        selectedLedgerIDs.removeAll()
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .disabled(isDeleting)
        .onAppear {
            hideTabBar.wrappedValue = true
        }
        .onDisappear {
            hideTabBar.wrappedValue = false
        }
        .overlay {
            if isDeleting {
                progressOverlay
            }
        }
        // 第一次确认
        .alert("确认删除", isPresented: $showFirstConfirmation) {
            Button("取消", role: .cancel) { }
            Button("继续", role: .destructive) {
                showSecondConfirmation = true
            }
        } message: {
            Text("您确定要删除 \(selectedLedgerIDs.count) 个账本吗？\n此操作无法撤销！")
        }
        // 第二次确认
        .alert("最终警告", isPresented: $showSecondConfirmation) {
            Button("取消", role: .cancel) { }
            Button("我已了解，继续删除", role: .destructive) {
                showFinalConfirmation = true
            }
        } message: {
            Text("这将永久删除以下数据：\n• 所有账户信息\n• 所有交易记录\n• 所有预算设置\n• 所有分类和标签\n\n删除后数据无法恢复！")
        }
        // 第三次确认 - 输入确认
        .sheet(isPresented: $showFinalConfirmation) {
            finalConfirmationSheet
        }
        // 完成提示
        .alert("删除完成", isPresented: $showCompletionAlert) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text("已成功删除 \(deletedCount) 个账本")
        }
        // 错误提示
        .alert("删除失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        // 最后一个账本提示
        .alert("无法删除", isPresented: $showLastLedgerAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("必须保留至少一个账本。如需清空数据，请使用「重置账本」功能。")
        }
    }
    
    // MARK: - Warning Banner
    
    private var warningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("危险操作")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("此操作将永久删除所选账本及其所有数据，无法恢复！")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.red)
    }
    
    // MARK: - Ledger List Content
    
    private var ledgerListContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if availableLedgers.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("没有可删除的账本")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                // Section Header
                Text("选择要删除的账本")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                // Ledger Cards
                VStack(spacing: 0) {
                    ForEach(availableLedgers) { ledger in
                        ledgerRow(ledger)
                        
                        if ledger.id != availableLedgers.last?.id {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                // Section Footer
                Text("已选择 \(selectedLedgerIDs.count) 个账本")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
        }
    }
    
    private func ledgerRow(_ ledger: Ledger) -> some View {
        let isSelected = selectedLedgerIDs.contains(ledger.id)
        let statistics = DataManagementService(modelContext: modelContext).getLedgerStatistics(ledger)
        
        return Button {
            HapticManager.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedLedgerIDs.remove(ledger.id)
                } else {
                    selectedLedgerIDs.insert(ledger.id)
                }
            }
        } label: {
            HStack(spacing: 16) {
                // 选择指示器
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .red : .secondary)
                
                // 账本图标
                ZStack {
                    Circle()
                        .fill(Color(hex: ledger.colorHex))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: ledger.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                
                // 账本信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ledger.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if ledger.isDefault {
                            Text("默认")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(statistics.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("创建于 \(ledger.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.red.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Delete Button Bar
    
    private var deleteButtonBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            // 提示信息：只剩一个账本时显示
            if availableLedgers.count == 1 {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("必须保留至少一个账本，如需清空数据请使用重置功能")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
            }
            
            Button {
                // 检查是否会删除所有账本
                if wouldDeleteAllLedgers {
                    HapticManager.warning()
                    showLastLedgerAlert = true
                } else {
                    HapticManager.warning()
                    showFirstConfirmation = true
                }
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("删除选中的账本 (\(selectedLedgerIDs.count))")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canDelete ? Color.red : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(!canDelete)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Final Confirmation Sheet
    
    private var finalConfirmationSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 警告图标
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                    .padding(.top, 20)
                
                // 说明文字
                VStack(spacing: 8) {
                    Text("最终确认")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("请输入 \"\(requiredConfirmationText)\" 以确认删除")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 输入框
                TextField("输入确认文字", text: $confirmationInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 40)
                
                // 提示
                if !confirmationInput.isEmpty && confirmationInput != requiredConfirmationText {
                    Text("输入不正确，请输入 \"\(requiredConfirmationText)\"")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                // 删除按钮
                Button {
                    showFinalConfirmation = false
                    Task {
                        await performDeletion()
                    }
                } label: {
                    Text("永久删除 \(selectedLedgerIDs.count) 个账本")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isConfirmationValid ? Color.red : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .disabled(!isConfirmationValid)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("确认删除")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        confirmationInput = ""
                        showFinalConfirmation = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Progress Overlay
    
    private var progressOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                
                Text(progressMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(30)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var availableLedgers: [Ledger] {
        ledgers.filter { !$0.isArchived }
    }
    
    private var selectedLedgers: [Ledger] {
        availableLedgers.filter { selectedLedgerIDs.contains($0.id) }
    }
    
    private var isConfirmationValid: Bool {
        confirmationInput == requiredConfirmationText
    }
    
    /// 是否可以删除（至少选中一个，且不会删除所有账本）
    private var canDelete: Bool {
        !selectedLedgerIDs.isEmpty && !wouldDeleteAllLedgers
    }
    
    /// 是否会删除所有账本
    private var wouldDeleteAllLedgers: Bool {
        selectedLedgerIDs.count >= availableLedgers.count
    }
    
    // MARK: - Actions
    
    private func performDeletion() async {
        isDeleting = true
        progress = 0
        progressMessage = "正在删除..."
        confirmationInput = ""
        
        let service = DataManagementService(modelContext: modelContext)
        service.progressHandler = { prog, message in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.progress = prog
                    self.progressMessage = message
                }
            }
        }
        
        do {
            // 检查是否要删除当前账本
            let deletingCurrentLedger = selectedLedgers.contains { $0.id == appState.currentLedger?.id }
            
            // 检查是否要删除默认账本
            let deletingDefaultLedger = selectedLedgers.contains { $0.isDefault }
            
            // 获取删除后剩余的账本（用于确定新的默认账本）
            let remainingLedgers = availableLedgers.filter { !selectedLedgerIDs.contains($0.id) }
            
            deletedCount = try service.deleteLedgers(selectedLedgers)
            
            // 如果删除了默认账本，需要设置新的默认账本
            if deletingDefaultLedger, let newDefaultLedger = remainingLedgers.sorted(by: { $0.createdAt > $1.createdAt }).first {
                newDefaultLedger.isDefault = true
                try modelContext.save()
            }
            
            // 如果删除了当前账本，切换到其他账本
            if deletingCurrentLedger {
                appState.currentLedger = appState.loadDefaultLedger()
            }
            
            HapticManager.success()
            showCompletionAlert = true
        } catch {
            HapticManager.error()
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        
        isDeleting = false
        selectedLedgerIDs.removeAll()
    }
}

// MARK: - Preview

#Preview {
    DeleteLedgersView()
        .environment(AppState())
        .modelContainer(for: Ledger.self)
}
