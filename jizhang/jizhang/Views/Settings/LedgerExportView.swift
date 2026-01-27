//
//  LedgerExportView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//
//  账本导出视图 - 选择账本并导出为文件
//

import SwiftUI
import SwiftData

/// 账本导出视图
struct LedgerExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.hideTabBar) private var hideTabBar
    
    @Query(sort: \Ledger.sortOrder) private var ledgers: [Ledger]
    
    // MARK: - State
    
    @State private var selectedLedger: Ledger?
    @State private var isExporting = false
    @State private var progress: Double = 0
    @State private var progressMessage = ""
    
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    @State private var showSuccessAlert = false
    @State private var exportedLedgerName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SubPageNavigationBar(title: "导出账本", backButtonText: "取消") {
                EmptyView()
            }
            .opacity(isExporting ? 0.5 : 1)
            .allowsHitTesting(!isExporting)
            
            ScrollView {
                VStack(spacing: 0) {
                    // 说明横幅
                    infoBanner
                    
                    // 账本列表
                    ledgerListContent
                }
            }
            .safeAreaInset(edge: .bottom) {
                // 底部导出按钮
                exportButtonBar
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .disabled(isExporting)
        .onAppear {
            hideTabBar.wrappedValue = true
            // 默认选中当前账本
            if selectedLedger == nil {
                selectedLedger = appState.currentLedger
            }
        }
        .onDisappear {
            hideTabBar.wrappedValue = false
        }
        .overlay {
            if isExporting {
                progressOverlay
            }
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            // ShareSheet 关闭后显示成功提示
            showSuccessAlert = true
        }) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("导出失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("导出成功", isPresented: $showSuccessAlert) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text("账本「\(exportedLedgerName)」的数据已成功导出，您可以将文件保存到文件App或分享给他人。")
        }
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.fill")
                .font(.title2)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("导出账本数据")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("将账本的所有数据（账户、分类、交易、预算等）导出为文件")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.blue)
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
                        Text("没有可导出的账本")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                // Section Header
                Text("选择要导出的账本")
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
                
                // 导出说明
                VStack(alignment: .leading, spacing: 8) {
                    Text("导出说明")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("导出文件格式为 .jizhang（JSON格式）", systemImage: "doc.text")
                        Label("包含账本的所有数据", systemImage: "archivebox")
                        Label("可通过「导入账本」功能恢复数据", systemImage: "arrow.down.doc")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func ledgerRow(_ ledger: Ledger) -> some View {
        let isSelected = selectedLedger?.id == ledger.id
        let service = LedgerExportService()
        let statistics = service.getStatistics(for: ledger)
        
        return Button {
            HapticManager.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedLedger = ledger
            }
        } label: {
            HStack(spacing: 16) {
                // 选择指示器
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                // 账本图标
                Image(systemName: ledger.iconName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color(hex: ledger.colorHex))
                    .frame(width: 44, height: 44)
                
                // 账本信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ledger.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if ledger.isDefault {
                            Text("默认")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.primaryBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .stroke(Color.primaryBlue, lineWidth: 1)
                                )
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
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Export Button Bar
    
    private var exportButtonBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                Task {
                    await performExport()
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                    Text("导出账本")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(canExport ? Color.blue : Color.gray)
                )
                .foregroundStyle(.white)
            }
            .disabled(!canExport)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
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
    
    private var canExport: Bool {
        selectedLedger != nil
    }
    
    // MARK: - Actions
    
    private func performExport() async {
        guard let ledger = selectedLedger else { return }
        
        isExporting = true
        progress = 0
        progressMessage = "正在准备导出..."
        
        let service = LedgerExportService()
        service.progressHandler = { prog, message in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.progress = prog
                    self.progressMessage = message
                }
            }
        }
        
        do {
            // 导出数据
            let data = try service.export(ledger: ledger)
            
            // 创建临时文件
            let fileURL = try service.createTemporaryFile(for: ledger, data: data)
            
            exportedFileURL = fileURL
            exportedLedgerName = ledger.name
            
            HapticManager.success()
            
            // 显示分享面板
            isExporting = false
            showShareSheet = true
            
        } catch {
            HapticManager.error()
            errorMessage = error.localizedDescription
            isExporting = false
            showErrorAlert = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    LedgerExportView()
        .environment(AppState())
        .modelContainer(for: Ledger.self)
}
