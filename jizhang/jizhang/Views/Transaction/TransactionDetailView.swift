//
//  TransactionDetailView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 编辑交易Sheet
struct EditTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let transaction: Transaction
    @State private var viewModel = AddTransactionViewModel()
    @State private var showKeyboard = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 类型切换
                TransactionTypeSegment(selectedType: $viewModel.type)
                    .padding(.top, Spacing.m)
                    .disabled(true) // 编辑时不允许修改类型
                
                // 金额显示 - 可点击唤起键盘
                Button(action: {
                    showKeyboard = true
                }) {
                    AmountDisplay(amount: $viewModel.amount)
                        .padding(.vertical, Spacing.l)
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.vertical, Spacing.s)
                
                // 选择区域 - 占据更多空间
                EditSelectionArea(viewModel: viewModel)
                    .padding(.horizontal, Spacing.m)
                
                Spacer()
                
                // 底部确认按钮
                Button(action: {
                    Task {
                        do {
                            try await updateTransaction()
                            dismiss()
                        } catch {
                            // 错误已在viewModel中处理
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("确认修改")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(viewModel.isValid ? Color.primaryBlue : Color.gray.opacity(0.5))
                    )
                }
                .disabled(!viewModel.isValid)
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, Spacing.m)
            }
            .navigationTitle("编辑交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext, appState: appState)
                loadTransactionData()
            }
            .alert("错误", isPresented: $viewModel.showErrorAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showKeyboard) {
                CalculatorKeyboard(
                    amount: $viewModel.amount,
                    onConfirm: {
                        // 键盘完成后不做其他操作，用户需要点击底部确认按钮
                    },
                    isValid: true
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func loadTransactionData() {
        viewModel.type = transaction.type
        viewModel.amount = transaction.amount
        viewModel.date = transaction.date
        viewModel.selectedAccount = transaction.fromAccount
        viewModel.selectedToAccount = transaction.toAccount
        viewModel.selectedCategory = transaction.category
        viewModel.note = transaction.note ?? ""
    }
    
    private func updateTransaction() async throws {
        guard appState.currentLedger != nil else {
            throw TransactionError.missingDependencies
        }
        
        // 验证
        if let error = viewModel.validationError {
            viewModel.errorMessage = error
            viewModel.showErrorAlert = true
            throw TransactionError.validationFailed(error)
        }
        
        // 先恢复原交易的账户余额
        switch transaction.type {
        case .expense:
            if let account = transaction.fromAccount {
                account.balance += transaction.amount
            }
        case .income:
            if let account = transaction.fromAccount {
                account.balance -= transaction.amount
            }
        case .transfer:
            if let fromAccount = transaction.fromAccount {
                fromAccount.balance += transaction.amount
            }
            if let toAccount = transaction.toAccount {
                toAccount.balance -= transaction.amount
            }
        case .adjustment:
            if let account = transaction.fromAccount {
                account.balance -= transaction.amount
            }
        }
        
        // 更新交易数据
        transaction.amount = viewModel.amount
        transaction.date = viewModel.date
        transaction.fromAccount = viewModel.selectedAccount
        transaction.toAccount = viewModel.selectedToAccount
        transaction.category = viewModel.selectedCategory
        transaction.note = viewModel.note.isEmpty ? nil : viewModel.note
        
        // 应用新的账户余额
        switch transaction.type {
        case .expense:
            if let account = transaction.fromAccount {
                account.balance -= transaction.amount
            }
        case .income:
            if let account = transaction.fromAccount {
                account.balance += transaction.amount
            }
        case .transfer:
            if let fromAccount = transaction.fromAccount {
                fromAccount.balance -= transaction.amount
            }
            if let toAccount = transaction.toAccount {
                toAccount.balance += transaction.amount
            }
        case .adjustment:
            if let account = transaction.fromAccount {
                account.balance += transaction.amount
            }
        }
        
        // 保存
        try modelContext.save()
        
        // 刷新Widget
        refreshAllWidgets()
        
        // 触发震动反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Edit Selection Area

private struct EditSelectionArea: View {
    @Bindable var viewModel: AddTransactionViewModel
    
    var body: some View {
        VStack(spacing: Spacing.m) {
            // 第一行：账户和分类
            HStack(spacing: Spacing.m) {
                // 账户
                EditSelectionCard(
                    icon: "creditcard.fill",
                    iconColor: .blue,
                    title: "账户",
                    value: viewModel.selectedAccount?.name ?? "请选择",
                    showArrow: true
                ) {
                    viewModel.showAccountPicker = true
                }
                .frame(maxWidth: .infinity)
                
                // 分类
                EditSelectionCard(
                    icon: viewModel.selectedCategory?.iconName ?? "folder.fill",
                    iconColor: viewModel.selectedCategory != nil ? Color(hex: viewModel.selectedCategory!.colorHex) : .orange,
                    title: "分类",
                    value: viewModel.displayCategory,
                    showArrow: true
                ) {
                    viewModel.showCategoryPicker = true
                }
                .frame(maxWidth: .infinity)
            }
            
            // 第二行：日期和备注
            HStack(spacing: Spacing.m) {
                // 日期
                EditSelectionCard(
                    icon: "calendar",
                    iconColor: .purple,
                    title: "日期",
                    value: viewModel.date.smartDescription,
                    showArrow: true
                ) {
                    viewModel.showDatePicker = true
                }
                .frame(maxWidth: .infinity)
                
                // 备注
                EditSelectionCard(
                    icon: "note.text",
                    iconColor: .gray,
                    title: "备注",
                    value: viewModel.note.isEmpty ? "添加备注" : viewModel.note,
                    showArrow: true
                ) {
                    viewModel.showNotePicker = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $viewModel.showAccountPicker) {
            AccountPickerSheet(selectedAccount: $viewModel.selectedAccount)
        }
        .sheet(isPresented: $viewModel.showCategoryPicker) {
            CategoryGridPicker(
                type: viewModel.type,
                selectedCategory: $viewModel.selectedCategory
            )
        }
        .sheet(isPresented: $viewModel.showDatePicker) {
            QuickDatePicker(selectedDate: $viewModel.date)
        }
        .sheet(isPresented: $viewModel.showNotePicker) {
            EditNoteInputSheet(note: $viewModel.note)
        }
    }
}

// MARK: - Edit Selection Card

private struct EditSelectionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let showArrow: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // 顶部：图标和标题
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if showArrow {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                
                // 底部：值
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(value == "请选择" || value == "添加备注" ? .secondary : .primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Note Input Sheet

private struct EditNoteInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var note: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.m) {
                TextEditor(text: $note)
                    .frame(minHeight: 150)
                    .padding(Spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(Color(.systemGray6))
                    )
                    .focused($isFocused)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("编辑备注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// 交易详情视图
struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let transaction: Transaction
    
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        List {
            // 交易信息
            Section {
                DetailRow(label: "类型", value: transaction.type.displayName)
                
                DetailRow(
                    label: "金额",
                    value: transaction.amount.formatted(.currency(code: transaction.fromAccount?.ledger?.currencyCode ?? "CNY")),
                    valueColor: transaction.type == .expense ? .red : .green
                )
                
                if let account = transaction.fromAccount {
                    DetailRow(label: "账户", value: account.name)
                }
                
                if let toAccount = transaction.toAccount {
                    DetailRow(label: "转入账户", value: toAccount.name)
                }
                
                if let category = transaction.category {
                    let categoryName = category.parent != nil ? "\(category.parent!.name) - \(category.name)" : category.name
                    DetailRow(label: "分类", value: categoryName)
                }
                
                DetailRow(
                    label: "日期",
                    value: transaction.date.toChineseDateTimeString
                )
            }
            
            // 标签
            if !transaction.tags.isEmpty {
                Section("标签") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.s) {
                            ForEach(transaction.tags) { tag in
                                TagBadge(tag: tag)
                            }
                        }
                    }
                }
            }
            
            // 备注
            if let note = transaction.note, !note.isEmpty {
                Section("备注") {
                    Text(note)
                        .font(.body)
                }
            }
            
            // 操作
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("删除交易")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("交易详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") {
                    showEditSheet = true
                }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text("删除后将恢复账户余额,此操作无法撤销")
        }
        .sheet(isPresented: $showEditSheet) {
            EditTransactionSheet(transaction: transaction)
        }
    }
    
    // MARK: - Methods
    
    private func deleteTransaction() {
        // 恢复账户余额
        switch transaction.type {
        case .expense:
            if let account = transaction.fromAccount {
                account.balance += transaction.amount
            }
        case .income:
            if let account = transaction.fromAccount {
                account.balance -= transaction.amount
            }
        case .transfer:
            if let fromAccount = transaction.fromAccount {
                fromAccount.balance += transaction.amount
            }
            if let toAccount = transaction.toAccount {
                toAccount.balance -= transaction.amount
            }
        case .adjustment:
            // 调整类型的余额恢复需要反向操作
            if let account = transaction.fromAccount {
                account.balance -= transaction.amount
            }
        }
        
        modelContext.delete(transaction)
        try? modelContext.save()
        
        dismiss()
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Tag Badge

private struct TagBadge: View {
    let tag: Tag
    
    var body: some View {
        Text("#\(tag.name)")
            .font(.caption)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: tag.colorHex).opacity(0.2))
            )
            .foregroundColor(Color(hex: tag.colorHex))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TransactionDetailView(transaction: Transaction(
            ledger: Ledger(name: "测试"),
            amount: 123.45,
            date: Date(),
            type: .expense
        ))
    }
    .modelContainer(for: [Transaction.self, Account.self, Category.self, Ledger.self, Tag.self])
}
