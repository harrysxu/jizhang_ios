//
//  ResetLedgersView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI
import SwiftData

/// 重置账本视图 - 支持多选和两次确认
struct ResetLedgersView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.hideTabBar) private var hideTabBar
    
    @Query(sort: \Ledger.sortOrder) private var ledgers: [Ledger]
    
    // MARK: - State
    
    @State private var selectedLedgerIDs: Set<UUID> = []
    @State private var showFirstConfirmation = false
    @State private var showFinalConfirmation = false
    @State private var confirmationInput = ""
    
    @State private var isResetting = false
    @State private var progress: Double = 0
    @State private var progressMessage = ""
    
    @State private var showCompletionAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var resetCount = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 警告横幅
                warningBanner
                
                // 说明卡片
                explanationCard
                
                // 账本列表（使用自定义列表而非 List）
                ledgerListContent
            }
        }
        .safeAreaInset(edge: .bottom) {
            // 底部重置按钮 - 固定在底部
            resetButtonBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("重置账本")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    dismiss()
                }
                .disabled(isResetting)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if !selectedLedgerIDs.isEmpty {
                    Button("取消选择") {
                        selectedLedgerIDs.removeAll()
                    }
                    .disabled(isResetting)
                }
            }
        }
        .disabled(isResetting)
        .onAppear {
            hideTabBar.wrappedValue = true
        }
        .onDisappear {
            hideTabBar.wrappedValue = false
        }
        .overlay {
            if isResetting {
                progressOverlay
            }
        }
        // 第一次确认
        .alert("确认重置", isPresented: $showFirstConfirmation) {
            Button("取消", role: .cancel) { }
            Button("继续", role: .destructive) {
                showFinalConfirmation = true
            }
        } message: {
            Text("您确定要重置 \(selectedLedgerIDs.count) 个账本吗？\n\n所有交易记录和预算将被清空，账户余额将归零。\n\n此操作无法撤销！")
        }
        // 第二次确认 - 输入账本名称
        .sheet(isPresented: $showFinalConfirmation) {
            finalConfirmationSheet
        }
        // 完成提示
        .alert("重置完成", isPresented: $showCompletionAlert) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text("已成功重置 \(resetCount) 个账本")
        }
        // 错误提示
        .alert("重置失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Warning Banner
    
    private var warningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("谨慎操作")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("重置将清空所有交易和预算，账户余额归零，此操作无法恢复！")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange)
    }
    
    // MARK: - Explanation Card
    
    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 保留项
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("保留")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("• 账本基本信息")
                    Text("• 账户结构（名称、类型）")
                    Text("• 分类结构")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 28)
            }
            
            Divider()
            
            // 清除项
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("清除")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("• 所有交易记录")
                    Text("• 所有预算设置")
                    Text("• 所有标签")
                    Text("• 账户余额（归零）")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 28)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        }
        .padding()
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
                        Text("没有可重置的账本")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                // Section Header
                Text("选择要重置的账本")
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
                    .foregroundStyle(isSelected ? .orange : .secondary)
                
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
                }
                
                Spacer()
                
                // 数据状态指示
                if statistics.hasData {
                    Text("有数据")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.orange.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Reset Button Bar
    
    private var resetButtonBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                HapticManager.warning()
                showFirstConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("重置选中的账本 (\(selectedLedgerIDs.count))")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedLedgerIDs.isEmpty ? Color.gray : Color.orange)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(selectedLedgerIDs.isEmpty)
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
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                    .padding(.top, 20)
                
                // 说明文字
                VStack(spacing: 8) {
                    Text("最终确认")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("请输入 \"RESET\" 以确认重置")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 将要重置的账本列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("将要重置的账本：")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(selectedLedgers) { ledger in
                        HStack {
                            Image(systemName: ledger.iconName)
                                .foregroundStyle(Color(hex: ledger.colorHex))
                            Text(ledger.name)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 输入框
                TextField("输入 RESET", text: $confirmationInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 40)
                
                // 提示
                if !confirmationInput.isEmpty && confirmationInput != requiredConfirmationText {
                    Text("输入不正确，请输入 \"RESET\"")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                // 重置按钮
                Button {
                    showFinalConfirmation = false
                    Task {
                        await performReset()
                    }
                } label: {
                    Text("重置 \(selectedLedgerIDs.count) 个账本")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isConfirmationValid ? Color.orange : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .disabled(!isConfirmationValid)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("确认重置")
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
        .presentationDetents([.large])
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
    
    private var requiredConfirmationText: String {
        "RESET"
    }
    
    private var isConfirmationValid: Bool {
        confirmationInput == requiredConfirmationText
    }
    
    // MARK: - Actions
    
    private func performReset() async {
        isResetting = true
        progress = 0
        progressMessage = "正在重置..."
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
            resetCount = try service.resetLedgers(selectedLedgers)
            
            HapticManager.success()
            showCompletionAlert = true
        } catch {
            HapticManager.error()
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        
        isResetting = false
        selectedLedgerIDs.removeAll()
    }
}

// MARK: - Preview

#Preview {
    ResetLedgersView()
        .environment(AppState())
        .modelContainer(for: Ledger.self)
}
