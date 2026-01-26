//
//  EmptyStateView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI

// MARK: - Empty State View

/// 空状态组件
struct EmptyStateView: View {
    
    // MARK: - Properties
    
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            
            VStack(spacing: Spacing.l) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                
                // 标题和描述
                VStack(spacing: Spacing.s) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                // 操作按钮
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text(actionTitle)
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, Spacing.s)
                }
            }
            .padding(.horizontal, Spacing.xxl)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// 无交易记录
    static func noTransactions(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "tray",
            title: "暂无交易记录",
            description: "开始记录您的第一笔收支吧",
            actionTitle: "添加记账",
            action: action
        )
    }
    
    /// 无报表数据
    static func noReportData() -> EmptyStateView {
        EmptyStateView(
            icon: "chart.bar",
            title: "暂无报表数据",
            description: "添加交易记录后,这里将显示详细的数据分析"
        )
    }
    
    /// 无预算
    static func noBudgets(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "dollarsign.circle",
            title: "暂无预算",
            description: "设置预算帮助您更好地管理支出",
            actionTitle: "创建预算",
            action: action
        )
    }
    
    /// 无账本
    static func noLedgers(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "book.closed",
            title: "暂无账本",
            description: "创建账本开始记账之旅",
            actionTitle: "创建账本",
            action: action
        )
    }
    
    /// 无搜索结果
    static func noSearchResults(searchTerm: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "无搜索结果",
            description: "没有找到包含 \"\(searchTerm)\" 的记录"
        )
    }
    
    /// 网络错误
    static func networkError(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "网络连接失败",
            description: "请检查您的网络连接后重试",
            actionTitle: "重新加载",
            action: action
        )
    }
    
    /// 无权限
    static func noPermission(permissionName: String) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "需要\(permissionName)权限",
            description: "请在设置中允许访问\(permissionName)"
        )
    }
}

// MARK: - Loading State View

/// 加载状态组件
struct LoadingStateView: View {
    let message: String
    
    init(message: String = "加载中...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(.circular)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State View

/// 错误状态组件
struct ErrorStateView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            
            VStack(spacing: Spacing.l) {
                // 错误图标
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.red.gradient)
                    .symbolRenderingMode(.multicolor)
                
                // 错误信息
                VStack(spacing: Spacing.s) {
                    Text("出错了")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 重试按钮
                if let retryAction = retryAction {
                    Button(action: retryAction) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("重试")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, Spacing.s)
                }
            }
            .padding(.horizontal, Spacing.xxl)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Empty States") {
    TabView {
        EmptyStateView.noTransactions {
            print("Add transaction")
        }
        .tabItem { Label("无交易", systemImage: "1.circle") }
        
        EmptyStateView.noReportData()
            .tabItem { Label("无报表", systemImage: "2.circle") }
        
        EmptyStateView.noBudgets {
            print("Create budget")
        }
        .tabItem { Label("无预算", systemImage: "3.circle") }
        
        EmptyStateView.noSearchResults(searchTerm: "测试")
            .tabItem { Label("无搜索结果", systemImage: "4.circle") }
        
        LoadingStateView(message: "正在加载数据...")
            .tabItem { Label("加载中", systemImage: "5.circle") }
        
        ErrorStateView(
            error: NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "网络连接超时"]),
            retryAction: {
                print("Retry")
            }
        )
        .tabItem { Label("错误", systemImage: "6.circle") }
    }
}

