//
//  PremiumFeatureGate.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//
//  付费功能入口组件 - 用于统一处理权限检查

import SwiftUI

/// 付费功能入口组件
/// 用法：
/// ```
/// PremiumFeatureGate(feature: .accountManagement) {
///     NavigationLink { ... } label: { ... }
/// }
/// ```
struct PremiumFeatureGate<Content: View>: View {
    @Environment(AppState.self) private var appState
    
    let feature: PremiumFeature
    let content: Content
    
    @State private var showSubscriptionSheet = false
    
    init(feature: PremiumFeature, @ViewBuilder content: () -> Content) {
        self.feature = feature
        self.content = content()
    }
    
    var body: some View {
        if appState.subscriptionManager.hasAccess(to: feature) {
            // 有权限，直接显示内容
            content
        } else {
            // 无权限，显示锁定状态
            Button {
                HapticManager.light()
                showSubscriptionSheet = true
            } label: {
                HStack {
                    content
                        .disabled(true)
                    
                    Spacer()
                    
                    // 锁定图标
                    PremiumBadge()
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionView()
            }
        }
    }
}

/// 用于NavigationLink的付费功能入口
/// 可以替代NavigationLink，在无权限时显示订阅页面
struct PremiumNavigationLink<Label: View, Destination: View>: View {
    @Environment(AppState.self) private var appState
    
    let feature: PremiumFeature
    let destination: Destination
    let label: Label
    
    @State private var showSubscriptionSheet = false
    
    init(
        feature: PremiumFeature,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.feature = feature
        self.destination = destination()
        self.label = label()
    }
    
    var body: some View {
        if appState.subscriptionManager.hasAccess(to: feature) {
            // 有权限，正常导航
            NavigationLink {
                destination
            } label: {
                label
            }
        } else {
            // 无权限，显示订阅页面
            Button {
                HapticManager.light()
                showSubscriptionSheet = true
            } label: {
                HStack {
                    label
                    Spacer()
                    PremiumBadge()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionView()
            }
        }
    }
}

/// 高级版徽章
struct PremiumBadge: View {
    var compact: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: compact ? 10 : 12))
            
            if !compact {
                Text("高级")
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
}

/// 付费功能锁定覆盖层
/// 用于在整个视图上显示锁定状态
struct PremiumFeatureOverlay: View {
    @Environment(AppState.self) private var appState
    
    let feature: PremiumFeature
    
    @State private var showSubscriptionSheet = false
    
    var body: some View {
        if !appState.subscriptionManager.hasAccess(to: feature) {
            ZStack {
                // 背景模糊
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // 提示内容
                VStack(spacing: Spacing.m) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    
                    Text("高级功能")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(feature.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showSubscriptionSheet = true
                    } label: {
                        Text("升级解锁")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.xxl)
                            .padding(.vertical, Spacing.m)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                    }
                    .padding(.top, Spacing.s)
                }
                .padding(Spacing.xxl)
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionView()
            }
        }
    }
}

/// 检查是否有权限的视图修饰符
struct PremiumFeatureModifier: ViewModifier {
    @Environment(AppState.self) private var appState
    
    let feature: PremiumFeature
    
    @State private var showSubscriptionSheet = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if !appState.subscriptionManager.hasAccess(to: feature) {
                    PremiumFeatureOverlay(feature: feature)
                }
            }
    }
}

extension View {
    /// 为视图添加付费功能检查
    func premiumFeature(_ feature: PremiumFeature) -> some View {
        modifier(PremiumFeatureModifier(feature: feature))
    }
}

// MARK: - Preview

#Preview("Premium Badge") {
    VStack(spacing: 20) {
        PremiumBadge()
        PremiumBadge(compact: true)
    }
    .padding()
}

#Preview("Premium Overlay") {
    VStack {
        Text("这是一个被锁定的功能")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(height: 300)
    .overlay {
        PremiumFeatureOverlay(feature: .accountManagement)
    }
    .environment(AppState())
}
