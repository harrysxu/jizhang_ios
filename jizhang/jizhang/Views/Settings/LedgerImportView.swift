//
//  LedgerImportView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//
//  账本导入视图 - 从文件导入账本数据
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 账本导入视图
struct LedgerImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.hideTabBar) private var hideTabBar
    
    // MARK: - State
    
    @State private var showFilePicker = false
    @State private var selectedFileData: Data?
    @State private var importPreview: ImportPreview?
    
    @State private var isImporting = false
    @State private var progress: Double = 0
    @State private var progressMessage = ""
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    @State private var showSuccessAlert = false
    @State private var importedLedgerName = ""
    
    @State private var showSwitchLedgerAlert = false
    @State private var importedLedger: Ledger?
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SubPageNavigationBar(title: "导入账本", backButtonText: "取消") {
                EmptyView()
            }
            .opacity(isImporting ? 0.5 : 1)
            .allowsHitTesting(!isImporting)
            
            ScrollView {
                VStack(spacing: 0) {
                    // 说明横幅
                    infoBanner
                    
                    // 文件选择区域
                    filePickerSection
                    
                    // 预览区域
                    if let preview = importPreview {
                        previewSection(preview)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // 底部导入按钮
                if importPreview != nil {
                    importButtonBar
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .disabled(isImporting)
        .onAppear {
            hideTabBar.wrappedValue = true
        }
        .onDisappear {
            hideTabBar.wrappedValue = false
        }
        .overlay {
            if isImporting {
                progressOverlay
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.json, UTType.jizhangBackup],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("导入失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("导入成功", isPresented: $showSuccessAlert) {
            Button("留在当前账本") {
                dismiss()
            }
            Button("切换到新账本") {
                if let ledger = importedLedger {
                    appState.currentLedger = ledger
                }
                dismiss()
            }
        } message: {
            Text("账本「\(importedLedgerName)」已成功导入")
        }
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down.fill")
                .font(.title2)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("导入账本数据")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("从 .jizhang 或 .json 文件导入账本数据")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green)
    }
    
    // MARK: - File Picker Section
    
    private var filePickerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Text("选择文件")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            // 文件选择按钮
            Button {
                showFilePicker = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: importPreview == nil ? "doc.badge.plus" : "doc.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(importPreview == nil ? Color.secondary : Color.green)
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if importPreview != nil {
                            Text("已选择文件")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("点击重新选择其他文件")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("点击选择文件")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("支持 .jizhang 和 .json 格式")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            
            // 导入说明
            if importPreview == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("导入说明")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("支持通过「导出账本」生成的备份文件", systemImage: "checkmark.circle")
                        Label("导入后会创建新的账本，不会覆盖现有数据", systemImage: "plus.circle")
                        Label("如果账本名称重复，会自动添加编号", systemImage: "textformat.123")
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
    
    // MARK: - Preview Section
    
    private func previewSection(_ preview: ImportPreview) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Text("导入预览")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            // 预览卡片
            VStack(spacing: 0) {
                // 账本名称
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("账本名称")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(preview.ledgerName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Text(preview.currencyCode)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.leading, 16)
                
                // 数据统计
                VStack(spacing: 12) {
                    HStack {
                        Text("数据统计")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatisticItem(title: "账户", count: preview.accountCount, icon: "creditcard")
                        StatisticItem(title: "分类", count: preview.categoryCount, icon: "folder")
                        StatisticItem(title: "交易", count: preview.transactionCount, icon: "list.bullet")
                        StatisticItem(title: "预算", count: preview.budgetCount, icon: "chart.pie")
                        StatisticItem(title: "标签", count: preview.tagCount, icon: "tag")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.leading, 16)
                
                // 导出信息
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("导出时间")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(preview.formattedExportDate)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("文件版本")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("v\(preview.version)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            
            // 注意事项
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("导入后会创建新的账本，您可以随时删除")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Import Button Bar
    
    private var importButtonBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                Task {
                    await performImport()
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("导入账本")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.green)
                )
                .foregroundStyle(.white)
            }
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
    
    // MARK: - Actions
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // 开始访问安全作用域资源
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "无法访问选择的文件"
                showErrorAlert = true
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let data = try Data(contentsOf: url)
                selectedFileData = data
                
                // 解析预览
                let service = LedgerImportService(modelContext: modelContext)
                let preview = try service.preview(from: data)
                
                withAnimation {
                    importPreview = preview
                }
                
                HapticManager.success()
            } catch {
                errorMessage = "文件读取失败: \(error.localizedDescription)"
                showErrorAlert = true
                HapticManager.error()
            }
            
        case .failure(let error):
            errorMessage = "文件选择失败: \(error.localizedDescription)"
            showErrorAlert = true
            HapticManager.error()
        }
    }
    
    private func performImport() async {
        guard let data = selectedFileData else { return }
        
        isImporting = true
        progress = 0
        progressMessage = "正在准备导入..."
        
        let service = LedgerImportService(modelContext: modelContext)
        service.progressHandler = { prog, message in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.progress = prog
                    self.progressMessage = message
                }
            }
        }
        
        do {
            let ledger = try service.importLedger(from: data)
            
            HapticManager.success()
            
            importedLedger = ledger
            importedLedgerName = ledger.name
            isImporting = false
            showSuccessAlert = true
            
        } catch {
            HapticManager.error()
            errorMessage = error.localizedDescription
            isImporting = false
            showErrorAlert = true
        }
    }
}

// MARK: - Statistic Item

private struct StatisticItem: View {
    let title: String
    let count: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.headline)
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    LedgerImportView()
        .environment(AppState())
        .modelContainer(for: Ledger.self)
}
