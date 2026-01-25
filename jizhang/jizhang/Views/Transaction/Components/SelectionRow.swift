//
//  SelectionRow.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

/// 选择行组件 - 用于账户、分类等选择
struct SelectionRow: View {
    let icon: String
    let iconColor: Color?
    let title: String
    let value: String
    let action: () -> Void
    
    init(
        icon: String,
        iconColor: Color? = nil,
        title: String,
        value: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor ?? .gray)
                    .frame(width: 32)
                
                // 标题
                Text(title)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)
                
                // 值
                Text(value)
                    .font(.body)
                    .foregroundColor(value == "请选择" ? .secondary : .primary)
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Spacing.s) {
        SelectionRow(
            icon: "creditcard.fill",
            iconColor: .blue,
            title: "账户",
            value: "招商银行"
        ) {}
        
        Divider()
            .padding(.leading, 56)
        
        SelectionRow(
            icon: "folder.fill",
            iconColor: .orange,
            title: "分类",
            value: "请选择"
        ) {}
    }
    .padding()
}
