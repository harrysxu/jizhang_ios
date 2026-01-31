//
//  LedgerDrawerView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//

import SwiftUI
import SwiftData

/// 账本切换抽屉 - 从左侧滑出
struct LedgerDrawerView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Ledger.sortOrder) private var ledgers: [Ledger]
    
    // MARK: - Binding
    
    @Binding var isPresented: Bool
    
    // MARK: - State
    
    @State private var showLedgerManagement = false
    @State private var showLedgerForm = false
    @State private var dragOffset: CGFloat = 0
    @State private var showSubscriptionSheet = false
    
    // MARK: - Computed
    
    private var viewModel: LedgerViewModel {
        LedgerViewModel(modelContext: modelContext)
    }
    
    private var activeLedgers: [Ledger] {
        ledgers.filter { !$0.isArchived }
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let drawerWidth = min(geometry.size.width * 0.8, 320)
            
            ZStack(alignment: .leading) {
                // 背景遮罩
                Color.black
                    .opacity(isPresented ? 0.4 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeDrawer()
                    }
                
                // 抽屉内容
                HStack(spacing: 0) {
                    drawerContent
                        .frame(width: drawerWidth)
                        .background(Color(.systemBackground))
                        .offset(x: isPresented ? min(dragOffset, 0) : -drawerWidth)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // 只允许向左拖动
                                    if value.translation.width < 0 {
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    // 如果拖动超过 100pt 或速度较快，则关闭
                                    if value.translation.width < -100 || value.velocity.width < -500 {
                                        closeDrawer()
                                    }
                                    // 重置拖动偏移
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        dragOffset = 0
                                    }
                                }
                        )
                    
                    Spacer()
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
        }
        .sheet(isPresented: $showLedgerManagement) {
            NavigationStack {
                LedgerManagementView()
            }
        }
        .sheet(isPresented: $showLedgerForm) {
            LedgerFormSheet(ledger: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionView()
        }
    }
    
    // MARK: - Drawer Content
    
    private var drawerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部
            headerSection
            
            Divider()
            
            // 账本列表
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 我的账本标题
                    HStack {
                        Text("我的账本")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.s)
                    
                    // 账本列表
                    ForEach(activeLedgers) { ledger in
                        LedgerDrawerRow(
                            ledger: ledger,
                            isSelected: appState.currentLedger?.id == ledger.id,
                            canSwitch: ledger.isDefault || appState.subscriptionManager.hasAccess(to: .accountManagement)
                        ) {
                            if ledger.isDefault || appState.subscriptionManager.hasAccess(to: .accountManagement) {
                                selectLedger(ledger)
                            } else {
                                HapticManager.light()
                                showSubscriptionSheet = true
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, Spacing.m)
                    
                    // 操作按钮
                    actionButtons
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("账本")
                .font(.title2)
                .fontWeight(.bold)
            
            if let ledger = appState.currentLedger {
                Text("当前: \(ledger.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.l)
        .padding(.top, Spacing.s)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 0) {
            // 新建账本
            Button {
                if appState.subscriptionManager.hasAccess(to: .accountManagement) {
                    showLedgerForm = true
                } else {
                    HapticManager.light()
                    showSubscriptionSheet = true
                }
            } label: {
                HStack(spacing: Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    
                    Text("新建账本")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if !appState.subscriptionManager.hasAccess(to: .accountManagement) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
            }
            .buttonStyle(.plain)
            
            // 管理账本
            Button {
                if appState.subscriptionManager.hasAccess(to: .accountManagement) {
                    showLedgerManagement = true
                } else {
                    HapticManager.light()
                    showSubscriptionSheet = true
                }
            } label: {
                HStack(spacing: Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    
                    Text("管理账本")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if !appState.subscriptionManager.hasAccess(to: .accountManagement) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Methods
    
    private func selectLedger(_ ledger: Ledger) {
        HapticManager.selection()
        appState.currentLedger = ledger
        appState.saveCurrentLedgerID()
        
        // 延迟关闭，让用户看到选中效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            closeDrawer()
        }
    }
    
    private func closeDrawer() {
        HapticManager.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
        }
    }
}

// MARK: - Ledger Drawer Row

private struct LedgerDrawerRow: View {
    let ledger: Ledger
    let isSelected: Bool
    var canSwitch: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                // 圆形账本图标
                ZStack {
                    Circle()
                        .fill(Color(hex: ledger.colorHex))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: ledger.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: Color(hex: ledger.colorHex).opacity(0.3), radius: 4, y: 2)
                
                // 账本信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(ledger.name)
                            .font(.body)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(.primary)
                        
                        if ledger.isDefault {
                            Text("默认")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                    }
                    
                    // 统计信息
                    HStack(spacing: 8) {
                        Text("\(ledger.activeAccountsCount)个账户")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(ledger.thisMonthTransactionCount)笔本月交易")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // 选中标记或锁定标记
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.primaryBlue)
                } else if !canSwitch {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(isSelected ? Color.primaryBlue.opacity(0.08) : Color.clear)
            .opacity(canSwitch ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ledger Drawer Modifier

struct LedgerDrawerModifier: ViewModifier {
    @Environment(AppState.self) private var appState
    
    func body(content: Content) -> some View {
        @Bindable var appState = appState
        
        content
            .overlay {
                if appState.showLedgerDrawer {
                    LedgerDrawerView(isPresented: $appState.showLedgerDrawer)
                        .transition(.opacity)
                }
            }
    }
}

extension View {
    func ledgerDrawer() -> some View {
        modifier(LedgerDrawerModifier())
    }
}

// MARK: - Preview

#Preview {
    let appState = AppState()
    appState.showLedgerDrawer = true
    
    return Color.gray.opacity(0.1)
        .ignoresSafeArea()
        .ledgerDrawer()
        .modelContainer(for: [Ledger.self, Account.self, Category.self])
        .environment(appState)
}
