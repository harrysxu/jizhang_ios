//
//  TransactionTypeSegment.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

/// 交易类型切换组件
struct TransactionTypeSegment: View {
    @Binding var selectedType: TransactionType
    
    var body: some View {
        Picker("类型", selection: $selectedType) {
            Text("支出").tag(TransactionType.expense)
            Text("收入").tag(TransactionType.income)
            Text("转账").tag(TransactionType.transfer)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Spacing.m)
    }
}

#Preview {
    TransactionTypeSegment(selectedType: .constant(.expense))
}
