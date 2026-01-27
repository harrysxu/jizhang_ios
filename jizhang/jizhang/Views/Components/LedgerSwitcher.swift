//
//  LedgerSwitcher.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import SwiftUI
import SwiftData

/// 账本切换器 - 纯文字+箭头样式
/// 点击后触发左侧滑出的账本抽屉
struct LedgerSwitcher: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        // 纯文字 + 箭头，无任何背景
        HStack(spacing: 4) {
            Text(appState.currentLedger?.name ?? "选择账本")
                .font(.system(size: 17, weight: .medium))
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
    }
}

/// 自定义导航栏 - 替代系统 Toolbar，避免胶囊背景样式
/// 用于主页面（首页、流水、报表、设置）
struct CustomNavigationBar<TrailingContent: View>: View {
    @Environment(AppState.self) private var appState
    let title: String?
    let showLedgerSwitcher: Bool
    let trailingContent: TrailingContent
    
    init(
        title: String? = nil,
        showLedgerSwitcher: Bool = true,
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.showLedgerSwitcher = showLedgerSwitcher
        self.trailingContent = trailingContent()
    }
    
    var body: some View {
        HStack {
            // 左侧：账本切换器
            if showLedgerSwitcher {
                Button {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        appState.showLedgerDrawer = true
                    }
                } label: {
                    LedgerSwitcher()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // 中间：标题（如果有）
            if let title = title {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            // 右侧：自定义内容
            trailingContent
                .foregroundStyle(.primary)
        }
        .frame(minHeight: 44) // 确保最小高度符合人机交互指南
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

/// 二级页面导航栏 - 带返回按钮和标题
/// 用于设置的子页面（账户管理、分类管理、预算管理等）
struct SubPageNavigationBar<TrailingContent: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let showBackButton: Bool
    let backButtonText: String
    let trailingContent: TrailingContent
    
    init(
        title: String,
        showBackButton: Bool = true,
        backButtonText: String = "返回",
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.backButtonText = backButtonText
        self.trailingContent = trailingContent()
    }
    
    var body: some View {
        ZStack {
            // 中间：标题（绝对居中）
            Text(title)
                .font(.headline)
            
            // 左右两侧按钮
            HStack {
                // 左侧：返回按钮
                if showBackButton {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text(backButtonText)
                                .font(.system(size: 17))
                        }
                        .foregroundStyle(.primary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // 右侧：自定义内容
                trailingContent
                    .foregroundStyle(.primary)
            }
        }
        .frame(minHeight: 44) // 确保最小高度符合人机交互指南
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

/// Sheet 页面导航栏 - 用于模态弹出页面
/// 带有取消和确认按钮
struct SheetNavigationBar: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let confirmText: String
    let confirmDisabled: Bool
    let onConfirm: () -> Void
    
    init(
        title: String,
        confirmText: String = "保存",
        confirmDisabled: Bool = false,
        onConfirm: @escaping () -> Void
    ) {
        self.title = title
        self.confirmText = confirmText
        self.confirmDisabled = confirmDisabled
        self.onConfirm = onConfirm
    }
    
    var body: some View {
        ZStack {
            // 中间：标题（绝对居中）
            Text(title)
                .font(.headline)
            
            // 左右两侧按钮
            HStack {
                // 左侧：取消按钮
                Button {
                    dismiss()
                } label: {
                    Text("取消")
                        .foregroundStyle(.primary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 右侧：确认按钮
                Button {
                    onConfirm()
                } label: {
                    Text(confirmText)
                        .foregroundStyle(confirmDisabled ? Color.secondary : Color.blue)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(confirmDisabled)
            }
        }
        .frame(minHeight: 44) // 确保最小高度符合人机交互指南
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

/// 简单的 Sheet 导航栏 - 只有左侧关闭按钮
/// 用于只需要关闭功能的弹窗页面
struct SimpleCloseNavigationBar: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let closeText: String
    
    init(title: String, closeText: String = "关闭") {
        self.title = title
        self.closeText = closeText
    }
    
    var body: some View {
        ZStack {
            // 中间：标题（绝对居中）
            Text(title)
                .font(.headline)
            
            // 左侧：关闭按钮
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text(closeText)
                        .foregroundStyle(.primary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

/// 简单的 Sheet 导航栏 - 只有左侧取消按钮
/// 用于 Picker 类型的弹窗
struct SimpleCancelNavigationBar: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    
    init(title: String) {
        self.title = title
    }
    
    var body: some View {
        ZStack {
            // 中间：标题（绝对居中）
            Text(title)
                .font(.headline)
            
            // 左侧：取消按钮
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("取消")
                        .foregroundStyle(.primary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

/// 灵活的 Sheet 导航栏 - 可自定义左右按钮
/// 用于需要自定义按钮文字的弹窗
struct FlexibleSheetNavigationBar: View {
    let title: String
    let leftText: String
    let rightText: String
    let leftAction: () -> Void
    let rightAction: () -> Void
    
    init(
        title: String,
        leftText: String,
        rightText: String,
        leftAction: @escaping () -> Void,
        rightAction: @escaping () -> Void
    ) {
        self.title = title
        self.leftText = leftText
        self.rightText = rightText
        self.leftAction = leftAction
        self.rightAction = rightAction
    }
    
    var body: some View {
        ZStack {
            // 中间：标题（绝对居中）
            Text(title)
                .font(.headline)
            
            // 左右两侧按钮
            HStack {
                Button {
                    leftAction()
                } label: {
                    Text(leftText)
                        .foregroundStyle(.primary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    rightAction()
                } label: {
                    Text(rightText)
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

#Preview("Ledger Switcher") {
    VStack(spacing: 20) {
        CustomNavigationBar(title: nil) {
            Button {
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .background(Color.gray.opacity(0.1))
        
        Spacer()
    }
    .modelContainer(for: [Ledger.self])
    .environment(AppState())
}

