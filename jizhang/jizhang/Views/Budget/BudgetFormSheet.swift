//
//  BudgetFormSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

struct BudgetFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var categories: [Category]
    @Query private var ledgers: [Ledger]
    
    let budget: Budget?
    let viewModel: BudgetViewModel
    
    @State private var selectedCategory: Category?
    @State private var amount: String = ""
    @State private var selectedPeriod: BudgetPeriod = .monthly
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var enableRollover: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    private var isEditMode: Bool {
        budget != nil
    }
    
    private var title: String {
        isEditMode ? "编辑预算" : "创建预算"
    }
    
    private var currentLedger: Ledger? {
        ledgers.first
    }
    
    // 只显示一级分类且为支出类型
    private var expenseParentCategories: [Category] {
        categories.filter { $0.type == .expense && $0.parent == nil }
    }
    
    private var isValid: Bool {
        guard selectedCategory != nil,
              let amountValue = Decimal(string: amount),
              amountValue > 0 else {
            return false
        }
        return true
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SheetNavigationBar(
                title: title,
                confirmText: "保存",
                confirmDisabled: !isValid
            ) {
                saveBudget()
            }
            
            Form {
                // 分类选择
                Section("选择分类") {
                    Picker("分类", selection: $selectedCategory) {
                        Text("请选择").tag(nil as Category?)
                        ForEach(expenseParentCategories) { category in
                            Label {
                                Text(category.name)
                            } icon: {
                                PhosphorIcon.icon(named: category.iconName, weight: .fill)
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Color(hex: category.colorHex))
                            }
                            .tag(category as Category?)
                        }
                    }
                }
                
                // 预算金额
                Section("预算金额") {
                    HStack {
                        Text("¥")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .monospacedDigit()
                    }
                }
                
                // 预算周期
                Section("预算周期") {
                    Picker("周期", selection: $selectedPeriod) {
                        Text(BudgetPeriod.monthly.displayName).tag(BudgetPeriod.monthly)
                        Text(BudgetPeriod.yearly.displayName).tag(BudgetPeriod.yearly)
                        Text(BudgetPeriod.custom.displayName).tag(BudgetPeriod.custom)
                    }
                    .pickerStyle(.segmented)
                    
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    if selectedPeriod == .custom {
                        DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                    } else {
                        HStack {
                            Text("结束日期")
                            Spacer()
                            Text(calculateEndDate().toString(format: "yyyy年M月d日"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // 结转设置
                Section {
                    Toggle("启用结转", isOn: $enableRollover)
                } footer: {
                    Text("启用后,预算周期结束时会将剩余金额结转到下一周期")
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadBudget()
        }
    }
    
    private func loadBudget() {
        if let budget = budget {
            selectedCategory = budget.category
            amount = budget.amount.formatted(.number.precision(.fractionLength(0...2)))
            selectedPeriod = budget.period
            startDate = budget.startDate
            endDate = budget.endDate
            enableRollover = budget.enableRollover
        } else {
            // 默认值:本月1号
            let calendar = Calendar.current
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        }
    }
    
    private func calculateEndDate() -> Date {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .custom:
            return endDate
        }
    }
    
    private func saveBudget() {
        guard let category = selectedCategory,
              let amountValue = Decimal(string: amount),
              let ledger = currentLedger else {
            errorMessage = "请完整填写所有信息"
            showError = true
            return
        }
        
        do {
            if let budget = budget {
                // 更新现有预算
                try viewModel.updateBudget(
                    budget,
                    amount: amountValue,
                    period: selectedPeriod,
                    startDate: startDate,
                    enableRollover: enableRollover
                )
            } else {
                // 创建新预算
                try viewModel.createBudget(
                    ledger: ledger,
                    category: category,
                    amount: amountValue,
                    period: selectedPeriod,
                    startDate: startDate,
                    enableRollover: enableRollover
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    BudgetFormSheet(budget: nil, viewModel: BudgetViewModel(modelContext: ModelContext(try! ModelContainer(for: Budget.self))))
        .modelContainer(for: [Budget.self, Category.self, Ledger.self])
}
