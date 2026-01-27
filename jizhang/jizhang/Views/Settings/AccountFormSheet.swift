//
//  AccountFormSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 账户表单Sheet (创建/编辑)
struct AccountFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let account: Account? // nil表示创建新账户
    
    @State private var name: String = ""
    @State private var type: AccountType = .cash
    @State private var balance: Decimal = 0
    @State private var creditLimit: Decimal? = nil
    @State private var statementDay: Int? = nil
    @State private var dueDay: Int? = nil
    @State private var colorHex: String = "#007AFF"
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isEditing: Bool {
        account != nil
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (type != .creditCard || creditLimit != nil)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SheetNavigationBar(
                title: isEditing ? "编辑账户" : "添加账户",
                confirmText: isEditing ? "保存" : "添加",
                confirmDisabled: !isValid
            ) {
                saveAccount()
            }
            
            Form {
                // 基本信息
                Section("基本信息") {
                    TextField("账户名称", text: $name)
                    
                    Picker("账户类型", selection: $type) {
                        ForEach(AccountType.allCases, id: \.self) { accountType in
                            HStack {
                                Image(systemName: accountType.defaultIcon)
                                Text(accountType.displayName)
                            }
                            .tag(accountType)
                        }
                    }
                    .disabled(isEditing) // 编辑时不允许修改类型
                    
                    HStack {
                        Text("初始余额")
                        Spacer()
                        TextField("0.00", value: $balance, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // 显示账本的币种（只读）
                    if let ledger = appState.currentLedger {
                        HStack {
                            Text("币种")
                            Spacer()
                            Text(getCurrencyDisplayName(ledger.currencyCode))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // 信用卡专属设置
                if type == .creditCard {
                    Section("信用卡设置") {
                        HStack {
                            Text("信用额度")
                            Spacer()
                            TextField("必填", value: $creditLimit, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Picker("账单日", selection: $statementDay) {
                            Text("未设置").tag(nil as Int?)
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)日").tag(day as Int?)
                            }
                        }
                        
                        Picker("还款日", selection: $dueDay) {
                            Text("未设置").tag(nil as Int?)
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)日").tag(day as Int?)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadAccount()
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Methods
    
    private func getCurrencyDisplayName(_ code: String) -> String {
        switch code {
        case "CNY": return "人民币 (CNY)"
        case "USD": return "美元 (USD)"
        case "EUR": return "欧元 (EUR)"
        default: return code
        }
    }
    
    private func loadAccount() {
        guard let account = account else { return }
        
        name = account.name
        type = account.type
        balance = account.balance
        creditLimit = account.creditLimit
        statementDay = account.statementDay
        dueDay = account.dueDay
        colorHex = account.colorHex
    }
    
    private func saveAccount() {
        guard let ledger = appState.currentLedger else {
            errorMessage = "未找到当前账本"
            showError = true
            return
        }
        
        if isEditing {
            // 编辑现有账户
            guard let account = account else { return }
            
            account.name = name.trimmingCharacters(in: .whitespaces)
            account.balance = balance
            account.creditLimit = type == .creditCard ? creditLimit : nil
            account.statementDay = type == .creditCard ? statementDay : nil
            account.dueDay = type == .creditCard ? dueDay : nil
            account.colorHex = colorHex
            
        } else {
            // 创建新账户
            let newAccount = Account(
                ledger: ledger,
                name: name.trimmingCharacters(in: .whitespaces),
                type: type,
                balance: balance
            )
            
            newAccount.creditLimit = type == .creditCard ? creditLimit : nil
            newAccount.statementDay = type == .creditCard ? statementDay : nil
            newAccount.dueDay = type == .creditCard ? dueDay : nil
            newAccount.colorHex = colorHex
            newAccount.sortOrder = (ledger.accounts.map { $0.sortOrder }.max() ?? 0) + 1
            
            modelContext.insert(newAccount)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Preview

#Preview("Add") {
    AccountFormSheet(account: nil)
        .modelContainer(for: [Account.self, Ledger.self])
        .environment(AppState())
}
