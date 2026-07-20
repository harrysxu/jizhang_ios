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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppState.self) private var appState
    
    // MARK: - Body
    
    var body: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    private var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            TabContent(selectedTab: selectedTab)
                .ignoresSafeArea(.keyboard)
                .environment(\.hideTabBar, $hideTabBar)
                .padding(.bottom, hideTabBar ? 0 : 62)
            
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
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: hideTabBar)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionSheet()
        }
        // 账本抽屉 - 放在最外层，覆盖整个界面包括 TabBar
        .ledgerDrawer()
        .safeAreaInset(edge: .bottom) { undoBar }
        .fullScreenCover(isPresented: newUserSetupBinding) {
            NewUserSetupView()
                .environment(appState)
        }
        .sheet(isPresented: updateSummaryBinding) {
            UpdateSummaryView()
                .environment(appState)
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            List {
                Section {
                    sidebarItem(.home, title: "首页", icon: "house")
                    sidebarItem(.transactions, title: "流水", icon: "list.bullet")
                    sidebarItem(.report, title: "洞察", icon: "chart.bar")
                    sidebarItem(.budget, title: "预算", icon: "gauge.with.dots.needle.33percent")
                }
                Section {
                    sidebarItem(.settings, title: "设置", icon: "gearshape")
                }
                Section {
                    Button {
                        showAddTransaction = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("记一笔")
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityIdentifier("tab.addTransaction")
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
            .navigationTitle("简记账")
        } detail: {
            TabContent(selectedTab: selectedTab)
                .id(selectedTab)
                .environment(\.hideTabBar, $hideTabBar)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showAddTransaction = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("记一笔")
                        .accessibilityIdentifier("tab.addTransaction")
                        .help("记一笔")
                        .keyboardShortcut("n", modifiers: .command)
                    }
                }
        }
        .id(selectedTab)
        .sheet(isPresented: $showAddTransaction) { AddTransactionSheet() }
        .fullScreenCover(isPresented: newUserSetupBinding) {
            NewUserSetupView()
                .environment(appState)
        }
        .sheet(isPresented: updateSummaryBinding) {
            UpdateSummaryView()
                .environment(appState)
        }
        .background {
            Group {
                Button("") { selectedTab = .home }.keyboardShortcut("1", modifiers: .command)
                Button("") { selectedTab = .transactions }.keyboardShortcut("2", modifiers: .command)
                Button("") { selectedTab = .report }.keyboardShortcut("3", modifiers: .command)
                Button("") { selectedTab = .settings }.keyboardShortcut("4", modifiers: .command)
            }
            .hidden()
        }
        .ledgerDrawer()
        .safeAreaInset(edge: .bottom) { undoBar }
    }

    private func sidebarItem(_ tab: Tab, title: String, icon: String) -> some View {
        NavigationLink {
            TabContent(selectedTab: tab)
                .id(tab)
                .onAppear { selectedTab = tab }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)
        }
        .accessibilityLabel(title)
        .listRowBackground(
            selectedTab == tab ? Color.brandEmerald.opacity(0.1) : Color.clear
        )
    }

    private var newUserSetupBinding: Binding<Bool> {
        Binding(
            get: { appState.shouldShowNewUserSetup },
            set: { appState.shouldShowNewUserSetup = $0 }
        )
    }

    private var updateSummaryBinding: Binding<Bool> {
        Binding(
            get: { appState.shouldShowUpdateSummary },
            set: { appState.shouldShowUpdateSummary = $0 }
        )
    }

    @ViewBuilder
    private var undoBar: some View {
        if appState.pendingTransactionUndo != nil {
            HStack {
                Image(systemName: "trash")
                Text("流水已删除")
                Spacer()
                Button("撤销") {
                    try? appState.undoPendingTransactionDeletion()
                }
                .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, Spacing.l)
            .frame(height: 48)
            .background(.bar)
            .accessibilityElement(children: .combine)
        } else if appState.recentlyCreatedTransactionID != nil {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(Color.brandEmerald)
                Text("流水已保存")
                Spacer()
                Button("撤销") {
                    try? appState.undoRecentlyCreatedTransaction()
                }
                .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, Spacing.l)
            .frame(height: 48)
            .background(.bar)
            .accessibilityElement(children: .combine)
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
            case .budget:
                BudgetView()
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
                        .fill(Color.primaryBlue)
                        .frame(width: 56, height: 56)
                    
                    PhosphorIcon.icon(named: "plus", weight: .bold)
                        .frame(width: 26, height: 26)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("记一笔")
            .accessibilityIdentifier("tab.addTransaction")
            .offset(y: -12) // 凸出效果
            .frame(maxWidth: .infinity)
            
            // 报表
            TabBarButton(
                iconName: "chartBar",
                title: "洞察",
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
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
                    .foregroundStyle(isSelected ? Color.brandEmerald : Color.brandMuted)
                
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(title)
                        .font(isSelected ? .caption2.weight(.semibold) : .caption2)
                        .foregroundStyle(isSelected ? Color.brandEmerald : Color.brandMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

enum Tab: Hashable {
    case home
    case transactions
    case report
    case settings
    case budget
}

// MARK: - Preview

#Preview {
    TabBarView()
}
