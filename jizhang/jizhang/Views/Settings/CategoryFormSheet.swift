//
//  CategoryFormSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//
//  分类表单Sheet (创建/编辑)
//

import SwiftUI
import SwiftData

/// 分类表单Sheet (创建/编辑)
struct CategoryFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let category: Category? // nil表示创建新分类
    let defaultType: CategoryType
    
    @Query private var allCategories: [Category]
    
    @State private var name: String = ""
    @State private var type: CategoryType = .expense
    @State private var parent: Category? = nil
    @State private var iconName: String = "folder"
    @State private var colorHex: String = "#007AFF"
    @State private var sortOrder: Int = 0
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isEditing: Bool {
        category != nil
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // 可选的父分类列表
    private var availableParentCategories: [Category] {
        guard let ledger = appState.currentLedger else { return [] }
        
        return allCategories
            .filter { $0.ledger?.id == ledger.id && $0.type == type && $0.parent == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // 常用图标 (Phosphor 图标名称) - 使用 CategoryIconConfig 中定义的统一图标
    private let commonIcons = [
        // 餐饮
        "forkKnife", "coffee", "sunHorizon", "sun", "moon", "orangeSlice",
        // 购物
        "shoppingBag", "tShirt", "basket", "sparkle", "laptop",
        // 交通出行
        "car", "bus", "taxi", "gasPump", "parking",
        // 居家生活
        "houseLine", "lightning", "phone", "buildings",
        // 娱乐休闲
        "gameController", "personSimpleRun", "airplaneTilt",
        // 医疗健康
        "firstAidKit", "pill", "leaf",
        // 人情往来
        "gift", "envelopeSimple",
        // 学习培训
        "bookOpen", "chalkboardTeacher",
        // 收入相关
        "briefcase", "money", "trophy", "trendUp",
        // 其他
        "baby", "pawPrint", "wine", "dotsThreeCircle"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SheetNavigationBar(
                title: isEditing ? "编辑分类" : "添加分类",
                confirmText: isEditing ? "保存" : "添加",
                confirmDisabled: !isValid
            ) {
                saveCategory()
            }
            
            Form {
                // 基本信息
                Section("基本信息") {
                    TextField("分类名称", text: $name)
                    
                    Picker("分类类型", selection: $type) {
                        Text("支出").tag(CategoryType.expense)
                        Text("收入").tag(CategoryType.income)
                    }
                    .disabled(isEditing) // 编辑时不允许修改类型
                    
                    Picker("父分类", selection: $parent) {
                        Text("无(一级分类)").tag(nil as Category?)
                        ForEach(availableParentCategories) { parentCategory in
                            HStack {
                                PhosphorIcon.icon(named: parentCategory.iconName, weight: .fill)
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Color(hex: parentCategory.colorHex))
                                Text(parentCategory.name)
                            }
                            .tag(parentCategory as Category?)
                        }
                    }
                }
                
                // 外观
                Section("外观") {
                    // 图标选择
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        Text("图标")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.m) {
                            ForEach(commonIcons, id: \.self) { icon in
                                Button {
                                    iconName = icon
                                } label: {
                                    PhosphorIcon.icon(named: icon, weight: icon == iconName ? .fill : .regular)
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(icon == iconName ? Color(hex: colorHex) : .gray)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(icon == iconName ? Color(hex: colorHex).opacity(0.15) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.s)
                    
                    // 颜色选择
                    ColorPicker("颜色", selection: Binding(
                        get: { Color(hex: colorHex) },
                        set: { colorHex = $0.toHex() ?? colorHex }
                    ))
                }
                
                // 预览
                Section("预览") {
                    HStack(spacing: Spacing.m) {
                        PhosphorIcon.icon(named: iconName, weight: .fill)
                            .frame(width: 32, height: 32)
                            .foregroundColor(Color(hex: colorHex))
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let parent = parent {
                                Text("\(parent.name) - \(name.isEmpty ? "分类名称" : name)")
                                    .font(.body)
                            } else {
                                Text(name.isEmpty ? "分类名称" : name)
                                    .font(.body)
                            }
                            
                            Text(type.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, Spacing.s)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadCategory()
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Methods
    
    private func loadCategory() {
        if let category = category {
            name = category.name
            type = category.type
            parent = category.parent
            iconName = category.iconName
            colorHex = category.colorHex
            sortOrder = category.sortOrder
        } else {
            type = defaultType
            // 设置默认排序
            let maxOrder = allCategories
                .filter { $0.ledger?.id == appState.currentLedger?.id && $0.type == type && $0.parent == nil }
                .map { $0.sortOrder }
                .max() ?? 0
            sortOrder = maxOrder + 1
        }
    }
    
    private func saveCategory() {
        guard let ledger = appState.currentLedger else {
            errorMessage = "未找到当前账本"
            showError = true
            return
        }
        
        if isEditing {
            // 编辑现有分类
            guard let category = category else { return }
            
            category.name = name.trimmingCharacters(in: .whitespaces)
            category.parent = parent
            category.iconName = iconName
            category.colorHex = colorHex
            
        } else {
            // 创建新分类
            let newCategory = Category(
                ledger: ledger,
                name: name.trimmingCharacters(in: .whitespaces),
                type: type,
                iconName: iconName
            )
            
            newCategory.parent = parent
            newCategory.colorHex = colorHex
            newCategory.sortOrder = sortOrder
            
            modelContext.insert(newCategory)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}

// MARK: - Preview

#Preview("Add") {
    CategoryFormSheet(category: nil, defaultType: .expense)
        .modelContainer(for: [Category.self, Ledger.self])
        .environment(AppState())
}
