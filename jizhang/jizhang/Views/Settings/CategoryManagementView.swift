//
//  CategoryManagementView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 分类管理视图
struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Query private var allCategories: [Category]
    
    @State private var selectedTab: CategoryType = .expense
    @State private var showAddCategory = false
    @State private var categoryToEdit: Category?
    
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
                            // 无子分类
                            CategoryRowButton(category: parentCategory) {
                                categoryToEdit = parentCategory
                            }
                        } else {
                            // 有子分类,使用DisclosureGroup
                            DisclosureGroup {
                                ForEach(parentCategory.children.sorted { $0.sortOrder < $1.sortOrder }) { childCategory in
                                    CategoryRowButton(category: childCategory, isChild: true) {
                                        categoryToEdit = childCategory
                                    }
                                }
                            } label: {
                                CategoryRowLabel(category: parentCategory, childCount: parentCategory.children.count)
                            }
                        }
                    }
                    .onDelete(perform: deleteCategories)
                }
            }
        }
        .navigationTitle("分类管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LedgerSwitcher()
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
    }
    
    // MARK: - Methods
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = filteredParentCategories[index]
            
            // 检查是否有关联交易
            if !category.transactions.isEmpty {
                // TODO: 显示警告,无法删除有交易的分类
                continue
            }
            
            // 删除子分类
            for child in category.children {
                if !child.transactions.isEmpty {
                    // TODO: 显示警告
                    continue
                }
                modelContext.delete(child)
            }
            
            modelContext.delete(category)
        }
        
        try? modelContext.save()
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
                }
                
                // 图标
                Image(systemName: category.iconName)
                    .font(.system(size: isChild ? 18 : 20))
                    .foregroundColor(Color(hex: category.colorHex))
                    .frame(width: 32)
                
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
            // 图标
            Image(systemName: category.iconName)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: category.colorHex))
                .frame(width: 32)
            
            // 名称
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            // 子分类数量
            Text("\(childCount)")
                .font(.caption)
                .foregroundColor(.secondary)
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
