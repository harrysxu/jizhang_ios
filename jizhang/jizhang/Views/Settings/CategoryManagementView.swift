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
                            // 无子分类 - 支持滑动删除和编辑
                            CategoryRowButton(category: parentCategory) {
                                categoryToEdit = parentCategory
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    categoryToDelete = parentCategory
                                    showDeleteAlert = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                
                                Button {
                                    categoryToEdit = parentCategory
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.primaryBlue)
                            }
                        } else {
                            // 有子分类,使用DisclosureGroup
                            // 父分类也支持左滑编辑和删除
                            DisclosureGroup {
                                ForEach(parentCategory.children.sorted { $0.sortOrder < $1.sortOrder }) { childCategory in
                                    CategoryRowButton(category: childCategory, isChild: true) {
                                        categoryToEdit = childCategory
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            categoryToDelete = childCategory
                                            showDeleteAlert = true
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            categoryToEdit = childCategory
                                        } label: {
                                            Label("编辑", systemImage: "pencil")
                                        }
                                        .tint(.primaryBlue)
                                    }
                                }
                            } label: {
                                CategoryRowLabel(category: parentCategory, childCount: parentCategory.children.count)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    categoryToDelete = parentCategory
                                    showDeleteAlert = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                
                                Button {
                                    categoryToEdit = parentCategory
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.primaryBlue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("分类管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LedgerSwitcher(displayMode: .fullName)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
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

// MARK: - Category Row Button

private struct CategoryRowButton: View {
    let category: Category
    var isChild: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                if isChild {
                    Spacer()
                        .frame(width: 20)
                    
                    // 子分类图标 (使用 PhosphorIcon)
                    PhosphorIcon.icon(named: category.iconName, weight: .fill)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color(hex: category.colorHex))
                        .frame(width: 32, height: 32)
                } else {
                    // 父分类图标 (使用 PhosphorIcon)
                    PhosphorIcon.icon(named: category.iconName, weight: .fill)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color(hex: category.colorHex))
                        .frame(width: 40, height: 40)
                }
                
                // 名称
                Text(category.name)
                    .font(isChild ? .subheadline : .body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 交易数量
                if !category.transactions.isEmpty {
                    Text("\(category.transactions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Row Label

private struct CategoryRowLabel: View {
    let category: Category
    let childCount: Int
    
    var body: some View {
        HStack(spacing: Spacing.m) {
            // 图标 (使用 PhosphorIcon)
            PhosphorIcon.icon(named: category.iconName, weight: .fill)
                .frame(width: 24, height: 24)
                .foregroundStyle(Color(hex: category.colorHex))
                .frame(width: 40, height: 40)
            
            // 名称
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            // 子分类数量
            Text("\(childCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
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
