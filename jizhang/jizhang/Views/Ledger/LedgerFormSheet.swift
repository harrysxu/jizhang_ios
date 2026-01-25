//
//  LedgerFormSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

struct LedgerFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let ledger: Ledger?
    let viewModel: LedgerViewModel
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "book.fill"
    @State private var selectedColor: String = "#007AFF"
    @State private var currencyCode: String = "CNY"
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isEditMode: Bool {
        ledger != nil
    }
    
    private var title: String {
        isEditMode ? "编辑账本" : "创建账本"
    }
    
    private let availableIcons = [
        "book.fill", "book.closed.fill", "books.vertical.fill",
        "folder.fill", "briefcase.fill", "bag.fill",
        "cart.fill", "creditcard.fill", "dollarsign.circle.fill",
        "banknote.fill", "wallet.pass.fill", "star.fill"
    ]
    
    private let availableColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#32ADE6", "#5856D6",
        "#AF52DE", "#FF2D55", "#A2845E", "#8E8E93"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // 账本名称
                Section("账本名称") {
                    TextField("请输入账本名称", text: $name)
                }
                
                // 图标选择
                Section("选择图标") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: Spacing.m) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color(hex: selectedColor) : Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 22))
                                        .foregroundStyle(selectedIcon == icon ? .white : .gray)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, Spacing.s)
                }
                
                // 颜色选择
                Section("选择颜色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: Spacing.m) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 44, height: 44)
                                    
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, Spacing.s)
                }
                
                // 货币设置
                Section("货币设置") {
                    Picker("货币", selection: $currencyCode) {
                        Text("人民币 (CNY)").tag("CNY")
                        Text("美元 (USD)").tag("USD")
                        Text("欧元 (EUR)").tag("EUR")
                        Text("日元 (JPY)").tag("JPY")
                        Text("港币 (HKD)").tag("HKD")
                    }
                }
                
                // 预览
                Section("预览") {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: selectedIcon)
                                .font(.system(size: 24))
                                .foregroundStyle(Color(hex: selectedColor))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "未命名账本" : name)
                                .font(.headline)
                            
                            Text(currencyCodeName(currencyCode))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, Spacing.s)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveLedger()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadLedger()
            }
        }
    }
    
    private func loadLedger() {
        if let ledger = ledger {
            name = ledger.name
            selectedIcon = ledger.iconName
            selectedColor = ledger.colorHex
            currencyCode = ledger.currencyCode
        }
    }
    
    private func saveLedger() {
        do {
            if let ledger = ledger {
                try viewModel.updateLedger(
                    ledger,
                    name: name,
                    currencyCode: currencyCode,
                    colorHex: selectedColor,
                    iconName: selectedIcon
                )
            } else {
                try viewModel.createLedger(
                    name: name,
                    currencyCode: currencyCode,
                    colorHex: selectedColor,
                    iconName: selectedIcon
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func currencyCodeName(_ code: String) -> String {
        switch code {
        case "CNY": return "人民币"
        case "USD": return "美元"
        case "EUR": return "欧元"
        case "JPY": return "日元"
        case "HKD": return "港币"
        default: return code
        }
    }
}

#Preview {
    LedgerFormSheet(
        ledger: nil,
        viewModel: LedgerViewModel(modelContext: ModelContext(try! ModelContainer(for: Ledger.self)))
    )
}
