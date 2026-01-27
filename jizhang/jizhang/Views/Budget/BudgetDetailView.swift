//
//  BudgetDetailView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

struct BudgetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let budget: Budget
    let viewModel: BudgetViewModel
    
    @State private var showDeleteAlert = false
    
    private var statusColor: Color {
        switch budget.status {
        case .safe:
            return .incomeGreen
        case .caution, .warning:
            return .warningOrange
        case .exceeded:
            return .expenseRed
        }
    }
    
    // 获取本周期内的交易
    private var periodTransactions: [Transaction] {
        budget.category?.allTransactions.filter { transaction in
            transaction.type == .expense &&
            transaction.date >= budget.startDate &&
            transaction.date < budget.endDate
        } .sorted(by: { $0.date > $1.date }) ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SheetNavigationBar(
                title: "预算详情",
                confirmText: "完成",
                confirmDisabled: false
            ) {
                dismiss()
            }
            
            List {
                budgetInfoSection
                progressSection  
                statsSection
                transactionsListSection
                actionButtonsSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("删除预算", isPresented: $showDeleteAlert) {
            alertButtons
        } message: {
            Text("确定要删除这个预算吗?此操作无法撤销。")
        }
    }
    
    // MARK: - Sections
    
    private var budgetInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.m) {
                categoryHeaderView
                Divider()
                budgetAmountsView
                Divider()
                budgetPeriodView
            }
            .listRowInsets(EdgeInsets(top: Spacing.m, leading: Spacing.m, bottom: Spacing.m, trailing: Spacing.m))
        }
    }
    
    private var categoryHeaderView: some View {
        HStack {
            categoryIconView
            categoryTextView
        }
    }
    
    private var categoryIconView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: budget.category?.colorHex ?? "#007AFF").opacity(0.2))
                .frame(width: 50, height: 50)
            
            Image(systemName: budget.category?.iconName ?? "folder.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: budget.category?.colorHex ?? "#007AFF"))
        }
    }
    
    private var categoryTextView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(budget.category?.name ?? "未分类")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(budget.period.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var budgetAmountsView: some View {
        VStack(spacing: Spacing.s) {
            amountRow(label: "预算金额", amount: budget.amount, color: nil)
            
            if budget.rolloverAmount > 0 {
                amountRow(label: "结转金额", amount: budget.rolloverAmount, color: Color.incomeGreen)
            }
            
            amountRow(label: "已用金额", amount: budget.usedAmount, color: Color.expenseRed)
            amountRow(
                label: budget.isOverBudget ? "超支金额" : "剩余金额",
                amount: abs(budget.remainingAmount),
                color: budget.isOverBudget ? Color.expenseRed : Color.incomeGreen
            )
        }
    }
    
    private func amountRow(label: String, amount: Decimal, color: Color?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("¥\(amount.formatted(.number.precision(.fractionLength(2))))")
                .font(.headline)
                .foregroundStyle(color ?? .primary)
                .monospacedDigit()
        }
    }
    
    private var budgetPeriodView: some View {
        HStack {
            Text("预算周期")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(formatDateRange())
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
    
    private var progressSection: some View {
        Section("预算进度") {
            VStack(alignment: .leading, spacing: Spacing.m) {
                BudgetProgressBar(progress: budget.progress, height: 16)
                
                HStack {
                    Text("进度")
                    Spacer()
                    Text("\(Int(budget.progress * 100))%")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .listRowInsets(EdgeInsets(top: Spacing.m, leading: Spacing.m, bottom: Spacing.m, trailing: Spacing.m))
        }
    }
    
    private var statsSection: some View {
        Section("统计信息") {
            HStack {
                Text("日均可用")
                Spacer()
                Text("¥\(budget.dailyAverage.formatted(.number.precision(.fractionLength(2))))")
                    .foregroundStyle(Color.incomeGreen)
                    .monospacedDigit()
            }
            
            HStack {
                Text("交易笔数")
                Spacer()
                Text("\(periodTransactions.count) 笔")
            }
            
            if budget.enableRollover {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.incomeGreen)
                    Text("已启用结转")
                }
            }
        }
    }
    
    private var transactionsListSection: some View {
        Group {
            if !periodTransactions.isEmpty {
                Section("本周期交易") {
                    ForEach(periodTransactions.prefix(10)) { transaction in
                        transactionRowView(transaction)
                    }
                    
                    if periodTransactions.count > 10 {
                        Text("还有 \(periodTransactions.count - 10) 笔交易...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private func transactionRowView(_ transaction: Transaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category?.name ?? "未分类")
                    .font(.body)
                
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("-¥\(transaction.amount.formatted(.number.precision(.fractionLength(2))))")
                .font(.body)
                .foregroundStyle(Color.expenseRed)
                .monospacedDigit()
        }
    }
    
    private var actionButtonsSection: some View {
        Section {
            Button {
                viewModel.showEditBudget(budget)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("编辑预算")
                }
            }
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("删除预算")
                }
            }
        }
    }
    
    @ViewBuilder
    private var alertButtons: some View {
        Button("取消", role: .cancel) { }
        Button("删除", role: .destructive) {
            deleteBudget()
        }
    }
    
    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: budget.startDate)) - \(formatter.string(from: budget.endDate))"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func deleteBudget() {
        do {
            try viewModel.deleteBudget(budget)
            dismiss()
        } catch {
            // 错误处理
        }
    }
}

#Preview {
    let mockLedger = Ledger(name: "测试账本")
    let mockCategory = Category(
        ledger: mockLedger,
        name: "餐饮",
        type: .expense,
        iconName: "fork.knife",
        colorHex: "#FF6B6B"
    )
    let mockBudget = Budget(
        ledger: mockLedger,
        category: mockCategory,
        amount: 2000,
        period: .monthly,
        startDate: Date(),
        enableRollover: true
    )
    
    return BudgetDetailView(
        budget: mockBudget,
        viewModel: BudgetViewModel(modelContext: ModelContext(try! ModelContainer(for: Budget.self)))
    )
}
