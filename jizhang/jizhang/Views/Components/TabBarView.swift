//
//  TabBarView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//
//  底部导航栏
//

import SwiftUI

struct TabBarView: View {
    // MARK: - Properties
    
    @State private var selectedTab: Tab = .home
    @State private var showAddTransaction = false
    @State private var hideTabBar = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            TabContent(selectedTab: selectedTab)
                .ignoresSafeArea(.keyboard)
                .environment(\.hideTabBar, $hideTabBar)
            
            // 自定义底部TabBar
            if !hideTabBar {
                CustomTabBar(
                    selectedTab: $selectedTab,
                    onAddTap: {
                        showAddTransaction = true
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hideTabBar)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionSheet()
        }
    }
}

// MARK: - Hide TabBar Environment Key

private struct HideTabBarKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var hideTabBar: Binding<Bool> {
        get { self[HideTabBarKey.self] }
        set { self[HideTabBarKey.self] = newValue }
    }
}

// MARK: - Tab Content

struct TabContent: View {
    let selectedTab: Tab
    
    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView()
            case .transactions:
                TransactionListView()
            case .report:
                ReportView()
            case .settings:
                SettingsView()
            }
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    let onAddTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 首页
            TabBarButton(
                iconName: "house",
                title: "首页",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            // 流水
            TabBarButton(
                iconName: "listDashes",
                title: "流水",
                isSelected: selectedTab == .transactions
            ) {
                selectedTab = .transactions
            }
            
            // 中间大号添加按钮 (参考UI样式: FAB浮动按钮)
            Button(action: onAddTap) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryBlue, Color.primaryBlue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.primaryBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                    
                    PhosphorIcon.icon(named: "plus", weight: .bold)
                        .frame(width: 26, height: 26)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: -12) // 凸出效果
            .frame(maxWidth: .infinity)
            
            // 报表
            TabBarButton(
                iconName: "chartBar",
                title: "报表",
                isSelected: selectedTab == .report
            ) {
                selectedTab = .report
            }
            
            // 设置
            TabBarButton(
                iconName: "gear",
                title: "设置",
                isSelected: selectedTab == .settings
            ) {
                selectedTab = .settings
            }
        }
        .frame(height: 54)
        .padding(.bottom, 8)
        .background(
            // 毛玻璃效果 (参考UI样式)
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let iconName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                // 图标
                PhosphorIcon.icon(named: iconName, weight: isSelected ? .fill : .regular)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isSelected ? Color.primaryBlue : Color.secondary)
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primaryBlue : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Tab Enum

enum Tab {
    case home
    case transactions
    case report
    case settings
}

// MARK: - Preview

#Preview {
    TabBarView()
}
