//
//  AddTransactionSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 快速记账Sheet
struct AddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @State private var viewModel = AddTransactionViewModel()
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SimpleCancelNavigationBar(title: "记一笔")
            
            // 类型切换
            TransactionTypeSegment(selectedType: $viewModel.type)
                .padding(.top, Spacing.m)
            
            // 金额输入 - 使用系统键盘
            AmountInputField(
                amount: $viewModel.amount,
                isFocused: $isAmountFocused,
                currencyCode: appState.currentLedger?.currencyCode ?? "CNY"
            )
            .padding(.vertical, Spacing.l)
            
            // 快速选择分类区域
            if viewModel.type != .transfer && !viewModel.quickSelectCategories.isEmpty {
                QuickCategorySelection(
                    categories: viewModel.quickSelectCategories,
                    selectedCategory: viewModel.selectedCategory,
                    onSelect: { category in
                        viewModel.selectQuickCategory(category)
                    }
                )
                .padding(.horizontal, Spacing.m)
            }
            
            Divider()
                .padding(.vertical, Spacing.s)
            
            // 选择区域 - 占据更多空间
            SelectionArea(viewModel: viewModel)
                .padding(.horizontal, Spacing.m)
            
            Spacer()
            
            // 底部确认按钮
            Button(action: {
                Task {
                    do {
                        try await viewModel.saveTransaction()
                        dismiss()
                    } catch {
                        // 错误已在viewModel中处理
                    }
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text("确认添加")
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
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.configure(modelContext: modelContext, appState: appState)
            // 自动聚焦金额输入
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAmountFocused = true
            }
        }
        .alert("错误", isPresented: $viewModel.showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Selection Area

private struct SelectionArea: View {
    @Bindable var viewModel: AddTransactionViewModel
    
    var body: some View {
        VStack(spacing: Spacing.m) {
            // 第一行：根据类型显示不同内容
            if viewModel.type == .transfer {
                // 转账模式：转出账户和转入账户
                HStack(spacing: Spacing.m) {
                    // 转出账户
                    SelectionCard(
                        icon: "arrow.up.circle.fill",
                        iconColor: .red,
                        title: "转出账户",
                        value: viewModel.selectedAccount?.name ?? "请选择",
                        showArrow: true
                    ) {
                        viewModel.showAccountPicker = true
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 转入账户
                    SelectionCard(
                        icon: "arrow.down.circle.fill",
                        iconColor: .green,
                        title: "转入账户",
                        value: viewModel.selectedToAccount?.name ?? "请选择",
                        showArrow: true
                    ) {
                        viewModel.showToAccountPicker = true
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                // 收支模式：账户和分类
                HStack(spacing: Spacing.m) {
                    // 账户
                    SelectionCard(
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
                    SelectionCard(
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
            }
            
            // 第二行：日期和时间
            HStack(spacing: Spacing.m) {
                // 日期
                SelectionCard(
                    icon: "calendar",
                    iconColor: .purple,
                    title: "日期",
                    value: viewModel.date.smartDescription,
                    showArrow: true
                ) {
                    viewModel.showDatePicker = true
                }
                .frame(maxWidth: .infinity)
                
                // 时间
                SelectionCard(
                    icon: "clock",
                    iconColor: .green,
                    title: "时间",
                    value: viewModel.date.timeString,
                    showArrow: true
                ) {
                    viewModel.showTimePicker = true
                }
                .frame(maxWidth: .infinity)
            }
            
            // 第三行：备注
            HStack(spacing: Spacing.m) {
                // 备注
                SelectionCard(
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
        .sheet(isPresented: $viewModel.showToAccountPicker) {
            AccountPickerSheet(
                selectedAccount: $viewModel.selectedToAccount,
                excludeAccount: viewModel.selectedAccount
            )
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
        .sheet(isPresented: $viewModel.showTimePicker) {
            TimePickerSheet(selectedDate: $viewModel.date)
        }
        .sheet(isPresented: $viewModel.showNotePicker) {
            NoteInputSheet(note: $viewModel.note)
        }
    }
}

// MARK: - Selection Card

private struct SelectionCard: View {
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

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SimpleCloseNavigationBar(title: "选择日期", closeText: "完成")
            
            DatePicker(
                "选择日期",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .padding()
        }
        .background(Color(.systemBackground))
        .presentationDetents([.medium])
    }
}

// MARK: - Time Picker Sheet

private struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    @State private var selectedTime: Date
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._selectedTime = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SheetNavigationBar(
                title: "选择时间",
                confirmText: "完成"
            ) {
                // 合并日期和时间
                selectedDate = Date.combine(date: selectedDate, time: selectedTime)
                dismiss()
            }
            
            VStack(spacing: Spacing.l) {
                DatePicker(
                    "选择时间",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
                
                Spacer()
            }
            .padding(.top, Spacing.l)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.medium])
    }
}

// MARK: - Note Input Sheet

private struct NoteInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var note: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SheetNavigationBar(
                title: "添加备注",
                confirmText: "完成"
            ) {
                dismiss()
            }
            
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
        }
        .background(Color(.systemBackground))
        .onAppear {
            isFocused = true
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Quick Category Selection

/// 快速选择分类区域 - 最多显示两行
private struct QuickCategorySelection: View {
    let categories: [Category]
    let selectedCategory: Category?
    let onSelect: (Category) -> Void
    
    // 每行最多显示的数量
    private let maxPerRow = 5
    
    private var firstRowCategories: [Category] {
        Array(categories.prefix(maxPerRow))
    }
    
    private var secondRowCategories: [Category] {
        if categories.count > maxPerRow {
            return Array(categories.dropFirst(maxPerRow).prefix(maxPerRow))
        }
        return []
    }
    
    var body: some View {
        VStack(spacing: Spacing.s) {
            // 第一行
            HStack(spacing: Spacing.s) {
                ForEach(firstRowCategories) { category in
                    QuickCategoryButton(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        onTap: { onSelect(category) }
                    )
                }
                
                // 如果第一行不满，添加空白占位
                if firstRowCategories.count < maxPerRow {
                    ForEach(0..<(maxPerRow - firstRowCategories.count), id: \.self) { _ in
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                }
            }
            
            // 第二行（如果有）
            if !secondRowCategories.isEmpty {
                HStack(spacing: Spacing.s) {
                    ForEach(secondRowCategories) { category in
                        QuickCategoryButton(
                            category: category,
                            isSelected: selectedCategory?.id == category.id,
                            onTap: { onSelect(category) }
                        )
                    }
                    
                    // 如果第二行不满，添加空白占位
                    if secondRowCategories.count < maxPerRow {
                        ForEach(0..<(maxPerRow - secondRowCategories.count), id: \.self) { _ in
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                        }
                    }
                }
            }
        }
        .padding(.vertical, Spacing.s)
    }
}

/// 快速分类按钮
private struct QuickCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    private var displayName: String {
        // 如果是子分类，显示简短名称
        category.name
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                PhosphorIcon.icon(named: category.iconName, weight: isSelected ? .fill : .regular)
                    .frame(width: 14, height: 14)
                
                Text(displayName)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(isSelected ? .white : Color(hex: category.colorHex))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: category.colorHex) : Color(hex: category.colorHex).opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: category.colorHex).opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AddTransactionSheet()
        .modelContainer(for: [Transaction.self, Account.self, Category.self, Ledger.self, Tag.self])
        .environment(AppState())
}
