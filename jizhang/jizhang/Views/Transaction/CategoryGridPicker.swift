//
//  CategoryGridPicker.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//
//  分类选择器
//

import SwiftUI
import SwiftData

/// 分类网格选择器 - 使用底部抽屉和网格布局
struct CategoryGridPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let type: TransactionType
    @Binding var selectedCategory: Category?
    
    @State private var categories: [Category] = []
    @State private var selectedParent: Category?
    
    var body: some View {
        VStack(spacing: 0) {
            // 手柄
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // 标题
            HStack {
                Text("选择分类")
                    .font(.headline)
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
                .font(.body)
            }
            .padding()
            
            // 父分类选择(如果有多个父分类)
            if !parentCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s) {
                        ForEach(parentCategories) { parent in
                            ParentCategoryChip(
                                category: parent,
                                isSelected: selectedParent?.id == parent.id
                            ) {
                                withAnimation {
                                    selectedParent = parent
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 50)
            }
            
            Divider()
            
            // 分类网格 (参考UI样式: 5列布局)
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 5),
                    spacing: Spacing.l
                ) {
                    ForEach(displayCategories) { category in
                        CategoryGridItem(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        ) {
                            selectedCategory = category
                            
                            // 触觉反馈
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            // 延迟关闭,让用户看到选中效果
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                dismiss()
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            loadCategories()
        }
    }
    
    // MARK: - Computed Properties
    
    private var parentCategories: [Category] {
        categories.filter { $0.parent == nil }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    private var displayCategories: [Category] {
        if let parent = selectedParent {
            // 显示选中父分类本身 + 其子分类（允许选择一级分类）
            var result = [parent]
            let children = categories
                .filter { $0.parent?.id == parent.id }
                .sorted { $0.sortOrder < $1.sortOrder }
            result.append(contentsOf: children)
            return result
        } else {
            // 显示所有父分类
            return parentCategories
        }
    }
    
    // MARK: - Methods
    
    private func loadCategories() {
        guard let ledger = appState.currentLedger else { return }
        
        let categoryType: CategoryType = type == .expense ? .expense : .income
        categories = (ledger.categories ?? []).filter { $0.type == categoryType }
        
        // 默认选择第一个父分类
        if selectedParent == nil {
            selectedParent = parentCategories.first
        }
    }
}

// MARK: - Parent Category Chip

private struct ParentCategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.primaryBlue : Color.secondary.opacity(0.1))
                )
        }
    }
}

// MARK: - Category Grid Item

private struct CategoryGridItem: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // 图标 (直接彩色显示，无圆形背景)
                PhosphorIcon.icon(named: category.iconName, weight: isSelected ? .fill : .regular)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(isSelected ? .primaryBlue : Color(hex: category.colorHex))
                    .scaleEffect(isPressed ? 0.9 : (isSelected ? 1.1 : 1.0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                // 名称
                Text(category.name)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .primaryBlue : .primary)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    CategoryGridPicker(
        type: .expense,
        selectedCategory: .constant(nil)
    )
    .modelContainer(for: [Category.self, Ledger.self])
    .environment(AppState())
}
