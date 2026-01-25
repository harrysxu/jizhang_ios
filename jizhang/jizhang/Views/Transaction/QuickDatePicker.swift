//
//  QuickDatePicker.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import SwiftUI

/// 快速日期选择器 - 提供日历选择
struct QuickDatePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 日历(定位到选中的日期)
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .padding()
                .onChange(of: selectedDate) { oldValue, newValue in
                    // 当日期改变时，自动关闭选择器
                    // 使用延迟以确保UI更新完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dismiss()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    QuickDatePicker(selectedDate: .constant(Date()))
}
