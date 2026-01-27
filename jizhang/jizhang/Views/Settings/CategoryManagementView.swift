//
//  CategoryManagementView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//
//  分类管理视图
//

import SwiftUI
import SwiftData

/// 分类管理视图
struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.hideTabBar) private var hideTabBar
    
    @Query private var allCategories: [Category]
    
    @State private var selectedTab: CategoryType = .expense
    @State private var showAddCategory = false
    @State private var categoryToEdit: Category?
    @State private var categoryToDelete: Category?
    @State private var showDeleteAlert = false
    @State private var deleteErrorMessage = ""
    @State private var showDeleteErrorAlert = false
    @State private var expandedCategories: Set<UUID> = []
    
    // MARK: - Computed Properties
    
    private var currentLedgerCategories: [Category] {
        guard let ledger = appState.currentLedger else { return [] }
        return allCategories
            .filter { $0.ledger?.id == ledger.id }
    }
    
    private var filteredParentCategories: [Category] {
        currentLedgerCategories
            .filter { $0.type == selectedTab && $0.parent == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SubPageNavigationBar(title: "分类管理") {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                }
            }
            
            // Tab切换
            Picker("分类类型", selection: $selectedTab) {
                Text("支出分类").tag(CategoryType.expense)
                Text("收入分类").tag(CategoryType.income)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 分类列表
            if filteredParentCategories.isEmpty {
                ContentUnavailableView(
                    "暂无\(selectedTab.displayName)分类",
                    systemImage: "folder.badge.plus",
                    description: Text("点击右上角 + 按钮创建分类")
                )
            } else {
                List {
                    ForEach(filteredParentCategories) { parentCategory in
                        if parentCategory.children.isEmpty {
                            // 无子分类
                            CategoryRowView(
                                category: parentCategory,
                                onEdit: { categoryToEdit = parentCategory },
                                onDelete: {
                                    categoryToDelete = parentCategory
                                    showDeleteAlert = true
                                }
                            )
                        } else {
                            // 有子分类 - 使用自定义展开机制
                            CategoryRowView(
                                category: parentCategory,
                                childCount: parentCategory.children.count,
                                isExpanded: expandedCategories.contains(parentCategory.id),
                                onTap: {
                                    // 点击切换展开状态
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if expandedCategories.contains(parentCategory.id) {
                                            expandedCategories.remove(parentCategory.id)
                                        } else {
                                            expandedCategories.insert(parentCategory.id)
                                        }
                                    }
                                },
                                onEdit: { categoryToEdit = parentCategory },
                                onDelete: {
                                    categoryToDelete = parentCategory
                                    showDeleteAlert = true
                                }
                            )
                            
                            // 子分类列表 - 展开时显示
                            if expandedCategories.contains(parentCategory.id) {
                                ForEach(parentCategory.children.sorted { $0.sortOrder < $1.sortOrder }) { childCategory in
                                    CategoryRowView(
                                        category: childCategory,
                                        isChild: true,
                                        onEdit: { categoryToEdit = childCategory },
                                        onDelete: {
                                            categoryToDelete = childCategory
                                            showDeleteAlert = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddCategory) {
            CategoryFormSheet(category: nil, defaultType: selectedTab)
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryFormSheet(category: category, defaultType: selectedTab)
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {
                categoryToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let category = categoryToDelete {
                    deleteCategory(category)
                }
                categoryToDelete = nil
            }
        } message: {
            if let category = categoryToDelete {
                if category.isParentCategory && !category.children.isEmpty {
                    Text("确定要删除「\(category.name)」及其所有子分类吗？此操作无法撤销。")
                } else {
                    Text("确定要删除「\(category.name)」吗？此操作无法撤销。")
                }
            }
        }
        .alert("无法删除", isPresented: $showDeleteErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .onAppear {
            hideTabBar.wrappedValue = true
        }
        .onDisappear {
            hideTabBar.wrappedValue = false
        }
    }
    
    // MARK: - Methods
    
    private func deleteCategory(_ category: Category) {
        // 检查是否有关联交易
        if !category.transactions.isEmpty {
            deleteErrorMessage = "分类「\(category.name)」下有 \(category.transactions.count) 笔交易记录，无法删除。请先删除或转移相关交易。"
            showDeleteErrorAlert = true
            return
        }
        
        // 如果是父分类，检查子分类是否有交易
        if category.isParentCategory {
            for child in category.children {
                if !child.transactions.isEmpty {
                    deleteErrorMessage = "子分类「\(child.name)」下有 \(child.transactions.count) 笔交易记录，无法删除。请先删除或转移相关交易。"
                    showDeleteErrorAlert = true
                    return
                }
            }
            
            // 删除所有子分类
            for child in category.children {
                modelContext.delete(child)
            }
        }
        
        modelContext.delete(category)
        
        do {
            try modelContext.save()
        } catch {
            deleteErrorMessage = "删除失败: \(error.localizedDescription)"
            showDeleteErrorAlert = true
        }
    }
}

// MARK: - Category Row View

private struct CategoryRowView: View {
    let category: Category
    var isChild: Bool = false
    var childCount: Int = 0
    var isExpanded: Bool = false
    var onTap: (() -> Void)? = nil
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var hasChildren: Bool { childCount > 0 }
    
    var body: some View {
        HStack(spacing: Spacing.m) {
            // 左侧内容区域（可点击）
            Button {
                onTap?()
            } label: {
                HStack(spacing: Spacing.m) {
                    if isChild {
                        Spacer()
                            .frame(width: 20)
                        
                        // 子分类图标
                        PhosphorIcon.icon(named: category.iconName, weight: .fill)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color(hex: category.colorHex))
                            .frame(width: 32, height: 32)
                    } else {
                        // 父分类图标
                        PhosphorIcon.icon(named: category.iconName, weight: .fill)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color(hex: category.colorHex))
                            .frame(width: 40, height: 40)
                    }
                    
                    // 名称
                    Text(category.name)
                        .font(isChild ? .subheadline : .body)
                        .foregroundColor(.primary)
                    
                    // 快速选择标识
                    if category.isQuickSelect {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 操作按钮（在数量和箭头左侧）
            HStack(spacing: Spacing.s) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryBlue)
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            // 子分类数量或交易数量 + 箭头（在最右侧）
            if hasChildren {
                Text("\(childCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                // 展开/收起箭头
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            } else if !category.transactions.isEmpty {
                Text("\(category.transactions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CategoryManagementView()
    }
    .modelContainer(for: [Category.self, Ledger.self, Transaction.self])
    .environment(AppState())
}
