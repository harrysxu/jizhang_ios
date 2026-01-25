//
//  TabBarView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct TabBarView: View {
    // MARK: - Properties
    
    @State private var selectedTab: Tab = .home
    @State private var showAddTransaction = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            TabContent(selectedTab: selectedTab)
                .ignoresSafeArea(.keyboard)
            
            // 自定义底部TabBar
            CustomTabBar(
                selectedTab: $selectedTab,
                onAddTap: {
                    showAddTransaction = true
                }
            )
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionSheet()
        }
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
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTab: Tab
    let onAddTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 首页
            TabBarButton(
                icon: "house.fill",
                title: "首页",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            // 流水
            TabBarButton(
                icon: "list.bullet.rectangle.fill",
                title: "流水",
                isSelected: selectedTab == .transactions
            ) {
                selectedTab = .transactions
            }
            
            // 中间大号添加按钮 - 使用随手记风格渐变
            Button(action: onAddTap) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: SuishoujiColors.addButtonGradient(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: SuishoujiColors.addButtonGradientLight.first?.opacity(0.4) ?? Color.clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -16) // 向上凸起
            .frame(maxWidth: .infinity)
            
            // 报表
            TabBarButton(
                icon: "chart.bar.fill",
                title: "报表",
                isSelected: selectedTab == .report
            ) {
                selectedTab = .report
            }
            
            // 设置
            TabBarButton(
                icon: "gearshape.fill",
                title: "设置",
                isSelected: selectedTab == .settings
            ) {
                selectedTab = .settings
            }
        }
        .frame(height: 60)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? SuishoujiColors.brandBlue : Color.secondary)
                
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? SuishoujiColors.brandBlue : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
