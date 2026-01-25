//
//  SwipeActions.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import SwiftUI

/// 流水项手势操作扩展
extension View {
    /// 添加流水项的滑动操作
    func transactionSwipeActions(
        transaction: Transaction,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onMarkReimbursed: @escaping () -> Void
    ) -> some View {
        self.swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // 删除按钮
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
            
            // 编辑按钮
            Button {
                onEdit()
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // 复制按钮
            Button {
                onDuplicate()
            } label: {
                Label("复制", systemImage: "doc.on.doc")
            }
            .tint(.orange)
            
            // 报销标记(仅支出类型)
            if transaction.type == .expense {
                Button {
                    onMarkReimbursed()
                } label: {
                    Label("报销", systemImage: "briefcase")
                }
                .tint(.purple)
            }
        }
    }
}

/// 流水项行视图 - 支持手势操作
struct TransactionRowView: View {
    let transaction: Transaction
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onMarkReimbursed: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.m) {
            // 分类图标
            if let category = transaction.category {
                Image(systemName: category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: category.colorHex))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(hex: category.colorHex).opacity(0.15))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 分类名称/备注
                Text(transaction.category?.name ?? "未分类")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // 账户和时间
                HStack(spacing: 4) {
                    if let account = transaction.primaryAccount {
                        Text(account.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(transaction.date.smartDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 金额
            Text(transaction.displayAmount)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(amountColor)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .transactionSwipeActions(
            transaction: transaction,
            onEdit: onEdit,
            onDelete: onDelete,
            onDuplicate: onDuplicate,
            onMarkReimbursed: onMarkReimbursed
        )
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense:
            return .expenseRed
        case .income:
            return .incomeGreen
        case .transfer, .adjustment:
            return .primary
        }
    }
}

// MARK: - Empty State View

struct EmptyTransactionsView: View {
    let message: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("点击下方按钮开始记账")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button {
                action()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("记一笔")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
                .background(
                    Capsule()
                        .fill(Color.primaryBlue)
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    List {
        TransactionRowView(
            transaction: Transaction(
                ledger: Ledger(name: "Test"),
                amount: 45.00,
                type: .expense
            ),
            onEdit: {},
            onDelete: {},
            onDuplicate: {},
            onMarkReimbursed: {}
        )
    }
}
