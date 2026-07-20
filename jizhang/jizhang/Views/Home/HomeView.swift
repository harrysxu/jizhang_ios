import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    private var ledgerTransactions: [Transaction] {
        guard let ledgerID = appState.currentLedger?.id else { return [] }
        return transactions.filter { $0.ledger?.id == ledgerID }
    }

    private var summary: BudgetSummary? {
        guard let ledgerID = appState.currentLedger?.id else { return nil }
        return try? appState.budgetCalculator?.summary(ledgerID: ledgerID, at: Date())
    }

    private var todayExpense: Decimal {
        ledgerTransactions
            .filter { $0.type == .expense && $0.date.isToday }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthIncome: Decimal {
        ledgerTransactions
            .filter { $0.type == .income && $0.date.isThisMonth }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthExpense: Decimal {
        ledgerTransactions
            .filter { $0.type == .expense && $0.date.isThisMonth }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomNavigationBar(title: nil) { EmptyView() }

                if appState.currentLedger == nil {
                    ContentUnavailableView(
                        "正在等待账本",
                        systemImage: "icloud.and.arrow.down",
                        description: Text("本地数据可用后会自动显示")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xxl) {
                            budgetSection
                            todaySection
                            adviceSection
                            recentSection
                            assetDisclosure
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.bottom, Layout.tabBarBottomPadding)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var budgetSection: some View {
        NavigationLink {
            BudgetView()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.l) {
                HStack {
                    Label("预算余量", systemImage: "gauge.with.dots.needle.33percent")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandMuted)
                }

                if let summary, summary.activeBudgetCount > 0 {
                    Text(summary.remaining.formatAmount())
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                        .foregroundStyle(summary.remaining >= 0 ? Color.brandInk : Color.brandCoral)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)

                    ProgressView(value: min(max(summary.progress, 0), 1))
                        .tint(summary.remaining >= 0 ? .brandEmerald : .brandCoral)

                    HStack {
                        metric("预算内支出", value: summary.coveredExpense)
                        Divider().frame(height: 34)
                        metric("未纳入", value: summary.uncoveredExpense)
                        Divider().frame(height: 34)
                        metric("安全日均", value: summary.safeDaily)
                    }
                } else {
                    Text("设置一个预算，首页会显示可用余量")
                        .font(.subheadline)
                        .foregroundStyle(Color.brandMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(Spacing.l)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("今日状态")
                .font(.headline)
            HStack(alignment: .firstTextBaseline) {
                Text(todayExpense.formatAmount())
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.brandCoral)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("今日支出金额 \(todayExpense.formatAmount())")
                if let safeDaily = summary?.safeDaily, safeDaily > 0 {
                    Text(todayExpense <= safeDaily ? "节奏正常" : "高于安全日均")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(todayExpense <= safeDaily ? Color.brandEmerald : Color.brandCoral)
                        .accessibilityLabel(todayExpense <= safeDaily ? "状态正常" : "状态需要注意")
                }
            }
            Text("本月支出 \(monthExpense.formatAmount()) · 收入 \(monthIncome.formatAmount())")
                .font(.subheadline)
                .foregroundStyle(Color.brandMuted)
        }
    }

    private var adviceSection: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: advice.icon)
                .foregroundStyle(advice.color)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(advice.text)
                .font(.subheadline)
                .foregroundStyle(Color.brandInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("建议：\(advice.text)")
        }
        .padding(.vertical, Spacing.s)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("最近流水")
                .font(.headline)

            if ledgerTransactions.isEmpty {
                ContentUnavailableView("还没有流水", systemImage: "tray")
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ForEach(ledgerTransactions.prefix(5)) { transaction in
                    NavigationLink {
                        TransactionDetailView(transaction: transaction)
                    } label: {
                        TransactionRow(transaction: transaction)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 60)
                }
            }
        }
    }

    private var assetDisclosure: some View {
        DisclosureGroup("净资产") {
            HStack {
                Text(appState.currentLedger?.totalAssets.formatAmount() ?? "0.00")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Spacer()
                Text("不含已排除账户")
                    .font(.caption)
                    .foregroundStyle(Color.brandMuted)
            }
            .padding(.top, Spacing.s)
        }
        .font(.headline)
    }

    private func metric(_ title: String, value: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(Color.brandMuted)
            Text(value.formatAmount())
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var advice: (icon: String, text: String, color: Color) {
        guard let summary, summary.activeBudgetCount > 0 else {
            return ("plus.circle", "先为最常用的支出分类设置预算。", .brandEmerald)
        }
        if summary.remaining < 0 {
            return ("exclamationmark.triangle", "预算已超支，今天优先减少非必要支出。", .brandCoral)
        }
        if summary.uncoveredExpense > 0 {
            return ("scope", "有支出尚未纳入预算，可检查分类覆盖范围。", .brandCoral)
        }
        return ("checkmark.circle", "当前支出在预算内，安全日均为 \(summary.safeDaily.formatAmount())。", .brandEmerald)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Ledger.self, Account.self, Category.self, Transaction.self, Budget.self, Tag.self])
        .environment(AppState())
}
