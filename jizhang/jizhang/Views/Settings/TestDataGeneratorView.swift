//
//  TestDataGeneratorView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI
import SwiftData

/// 测试数据生成视图
struct TestDataGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.hideTabBar) private var hideTabBar
    
    @Query(sort: \Ledger.sortOrder) private var ledgers: [Ledger]
    
    // MARK: - Configuration State
    
    @State private var selectedLedger: Ledger?
    @State private var createNewLedger = false
    @State private var newLedgerName = "测试账本"
    
    @State private var durationMonths = 3
    @State private var transactionsPerDay = 5
    @State private var accountCount = 4
    @State private var budgetCount = 5
    @State private var includeTransfers = true
    
    // MARK: - Progress State
    
    @State private var isGenerating = false
    @State private var progress: Double = 0
    @State private var progressMessage = ""
    @State private var showCompletionAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    private let durationOptions = [1, 3, 6, 12]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义导航栏
                SubPageNavigationBar(title: "填充测试数据", backButtonText: "取消") {
                    EmptyView()
                }
                .opacity(isGenerating ? 0.5 : 1)
                .allowsHitTesting(!isGenerating)
                
                Form {
                    // 目标账本选择
                    targetLedgerSection
                    
                    // 生成配置
                    configurationSection
                    
                    // 生成按钮
                    generateButtonSection
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .disabled(isGenerating)
            .overlay {
                if isGenerating {
                    progressOverlay
                }
            }
            .alert("生成完成", isPresented: $showCompletionAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("测试数据已成功生成！")
            }
            .alert("生成失败", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // 默认选择当前账本
                selectedLedger = appState.currentLedger
                hideTabBar.wrappedValue = true
            }
            .onDisappear {
                hideTabBar.wrappedValue = false
            }
        }
    }
    
    // MARK: - Target Ledger Section
    
    private var targetLedgerSection: some View {
        Section {
            Toggle("创建新账本", isOn: $createNewLedger)
            
            if createNewLedger {
                TextField("账本名称", text: $newLedgerName)
            } else {
                Picker("目标账本", selection: $selectedLedger) {
                    Text("请选择账本").tag(nil as Ledger?)
                    ForEach(ledgers.filter { !$0.isArchived }) { ledger in
                        HStack {
                            Image(systemName: ledger.iconName)
                                .foregroundStyle(Color(hex: ledger.colorHex))
                            Text(ledger.name)
                        }
                        .tag(ledger as Ledger?)
                    }
                }
            }
        } header: {
            Text("目标账本")
        } footer: {
            if createNewLedger {
                Text("将创建一个新账本并填充测试数据")
            } else {
                Text("将在选中的账本中添加测试数据")
            }
        }
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        Section {
            // 时间范围
            Picker("数据时间范围", selection: $durationMonths) {
                ForEach(durationOptions, id: \.self) { months in
                    Text("\(months) 个月").tag(months)
                }
            }
            
            // 每日交易数
            Stepper(value: $transactionsPerDay, in: 1...20) {
                HStack {
                    Text("每日交易数")
                    Spacer()
                    Text("\(transactionsPerDay)")
                        .foregroundStyle(.secondary)
                }
            }
            
            // 账户数量
            Stepper(value: $accountCount, in: 1...8) {
                HStack {
                    Text("账户数量")
                    Spacer()
                    Text("\(accountCount)")
                        .foregroundStyle(.secondary)
                }
            }
            
            // 预算数量
            Stepper(value: $budgetCount, in: 0...10) {
                HStack {
                    Text("预算数量")
                    Spacer()
                    Text("\(budgetCount)")
                        .foregroundStyle(.secondary)
                }
            }
            
            // 包含转账
            Toggle("包含转账交易", isOn: $includeTransfers)
        } header: {
            Text("生成配置")
        } footer: {
            let estimatedCount = estimatedTransactionCount
            Text("预计生成约 \(estimatedCount) 笔交易")
        }
    }
    
    // MARK: - Generate Button Section
    
    private var generateButtonSection: some View {
        Section {
            Button {
                Task {
                    await generateTestData()
                }
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "wand.and.stars")
                    Text("生成测试数据")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!canGenerate)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("注意事项：")
                    .fontWeight(.medium)
                Text("• 生成的数据为随机测试数据")
                Text("• 账户余额会根据交易自动计算")
                Text("• 建议在测试环境中使用")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
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
                
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .padding(30)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canGenerate: Bool {
        if createNewLedger {
            return !newLedgerName.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return selectedLedger != nil
        }
    }
    
    private var estimatedTransactionCount: Int {
        durationMonths * 30 * transactionsPerDay
    }
    
    // MARK: - Actions
    
    private func generateTestData() async {
        isGenerating = true
        progress = 0
        progressMessage = "准备中..."
        
        let config = TestDataConfig(
            durationMonths: durationMonths,
            transactionsPerDay: transactionsPerDay,
            accountCount: accountCount,
            budgetCount: budgetCount,
            includeTransfers: includeTransfers
        )
        
        let generator = TestDataGenerator(modelContext: modelContext, config: config)
        generator.progressHandler = { prog, message in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.progress = prog
                    self.progressMessage = message
                }
            }
        }
        
        do {
            if createNewLedger {
                let ledger = try await generator.createLedgerWithTestData(name: newLedgerName)
                // 切换到新创建的账本
                appState.currentLedger = ledger
            } else if let ledger = selectedLedger {
                try await generator.generateTestData(for: ledger)
            }
            
            HapticManager.success()
            showCompletionAlert = true
        } catch {
            HapticManager.error()
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        
        isGenerating = false
    }
}

// MARK: - Preview

#Preview {
    TestDataGeneratorView()
        .environment(AppState())
        .modelContainer(for: Ledger.self)
}
