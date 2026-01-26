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
    @State private var showKeyboard = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 类型切换
                TransactionTypeSegment(selectedType: $viewModel.type)
                    .padding(.top, Spacing.m)
                
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
            .navigationTitle("记一笔")
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
        NavigationStack {
            DatePicker(
                "选择日期",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .padding()
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
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
        NavigationStack {
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
            .navigationTitle("选择时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        // 合并日期和时间
                        selectedDate = Date.combine(date: selectedDate, time: selectedTime)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Note Input Sheet

private struct NoteInputSheet: View {
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
            .navigationTitle("添加备注")
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

// MARK: - Preview

#Preview {
    AddTransactionSheet()
        .modelContainer(for: [Transaction.self, Account.self, Category.self, Ledger.self, Tag.self])
        .environment(AppState())
}
