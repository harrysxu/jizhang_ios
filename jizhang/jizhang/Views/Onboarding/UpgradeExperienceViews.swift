import SwiftUI
import SwiftData

struct NewUserSetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var currencyCode = AppConstants.defaultCurrencyCode
    @State private var accountName = "现金"
    @State private var showFirstTransaction = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                ProgressView(value: Double(step + 1), total: 3)
                    .tint(.brandEmerald)
                    .accessibilityHidden(true)
                Text("第 \(step + 1) 步，共 3 步")
                    .font(.caption)
                    .foregroundStyle(Color.brandMuted)

                if step < 2 {
                    Button {
                        saveStepAndContinue()
                    } label: {
                        HStack {
                            Text("下一步")
                                .font(.body.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .disabled(step == 1 && accountName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Group {
                    switch step {
                    case 0: currencyStep
                    case 1: accountStep
                    default: firstTransactionStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(Spacing.xxl)
            .navigationTitle("简记账")
            .sheet(isPresented: $showFirstTransaction) {
                AddTransactionSheet()
                    .environment(appState)
            }
        }
        .interactiveDismissDisabled()
    }

    private var currencyStep: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("选择常用币种").font(.title2.weight(.semibold))
            Picker("币种", selection: $currencyCode) {
                Text("人民币 CNY").tag("CNY")
                Text("美元 USD").tag("USD")
                Text("欧元 EUR").tag("EUR")
            }
            .pickerStyle(.inline)
        }
    }

    private var accountStep: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("设置默认账户").font(.title2.weight(.semibold))
            TextField("账户名称", text: $accountName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
        }
    }

    private var firstTransactionStep: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("记录第一笔").font(.title2.weight(.semibold))
            Button {
                showFirstTransaction = true
            } label: {
                Label("记一笔", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primaryBlue)
            .accessibilityIdentifier("onboarding.firstTransaction")

            Button("进入首页") {
                appState.completeNewUserSetup()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func saveStepAndContinue() {
        guard let ledger = appState.currentLedger else { return }
        if step == 0 {
            ledger.currencyCode = currencyCode
        } else if let account = (ledger.accounts ?? []).sorted(by: { $0.sortOrder < $1.sortOrder }).first {
            account.name = accountName.trimmingCharacters(in: .whitespaces)
        }
        do {
            try modelContext.save()
            step += 1
        } catch {
            modelContext.rollback()
        }
    }
}

struct UpdateSummaryView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Label("账本打开失败时可重试并导出恢复包", systemImage: "shield.lefthalf.filled")
                Label("余额、预算、Widget 与 Siri 使用统一口径", systemImage: "equal.circle")
                Label("首页、流水、洞察和 iPad 导航已更新", systemImage: "rectangle.3.group")
            }
            .navigationTitle("简记账 · 简迹 2.0")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("知道了") { appState.dismissUpdateSummary() }
                }
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }
}
