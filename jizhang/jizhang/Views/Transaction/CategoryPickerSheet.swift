//
//  CategoryPickerSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

/// 分类选择器Sheet
struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let type: TransactionType
    @Binding var selectedCategory: Category?
    
    @Query private var allCategories: [Category]
    
    // MARK: - Computed Properties
    
    private var filteredCategories: [Category] {
        let categoryType: CategoryType = (type == .income) ? .income : .expense
        
        // 只显示一级分类
        return allCategories
            .filter { $0.type == categoryType && $0.parent == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SimpleCancelNavigationBar(title: type == .income ? "选择收入分类" : "选择支出分类")
            
            List {
                if filteredCategories.isEmpty {
                    ContentUnavailableView(
                        "暂无分类",
                        systemImage: "folder.badge.plus",
                        description: Text("请先在设置中创建分类")
                    )
                } else {
                    ForEach(filteredCategories) { parentCategory in
                        if parentCategory.children.isEmpty {
                            // 无子分类,直接显示
                            CategoryRowView(
                                category: parentCategory,
                                isSelected: selectedCategory?.id == parentCategory.id
                            ) {
                                selectedCategory = parentCategory
                                dismiss()
                            }
                        } else {
                            // 有子分类,使用DisclosureGroup
                            DisclosureGroup {
                                ForEach(parentCategory.children.sorted { $0.sortOrder < $1.sortOrder }) { childCategory in
                                    CategoryRowView(
                                        category: childCategory,
                                        isSelected: selectedCategory?.id == childCategory.id,
                                        isChild: true
                                    ) {
                                        selectedCategory = childCategory
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack(spacing: Spacing.m) {
                                    // 图标
                                    Image(systemName: parentCategory.iconName)
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: parentCategory.colorHex))
                                        .frame(width: 32)
                                    
                                    // 名称
                                    Text(parentCategory.name)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    // 子分类数量
                                    Text("\(parentCategory.children.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Category Row View

private struct CategoryRowView: View {
    let category: Category
    let isSelected: Bool
    var isChild: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                // 缩进(子分类)
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
                
                Spacer()
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CategoryPickerSheet(
        type: .expense,
        selectedCategory: .constant(nil)
    )
    .modelContainer(for: [Category.self, Ledger.self])
}
