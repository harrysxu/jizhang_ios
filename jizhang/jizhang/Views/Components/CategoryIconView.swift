//
//  CategoryIconView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//
//  分类图标组件
//  直接使用彩色图标，无圆形背景
//

import SwiftUI

// MARK: - Category Icon View

/// 分类图标组件 (无圆形背景，直接彩色显示)
struct CategoryIconView: View {
    
    // MARK: - Properties
    
    let iconName: String
    let name: String
    let iconColor: Color
    let isSelected: Bool
    let size: IconSize
    let action: () -> Void
    
    // MARK: - Icon Size Enum
    
    enum IconSize {
        case small      // 24pt
        case medium     // 32pt
        case large      // 40pt
        case xlarge     // 48pt
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 40
            case .xlarge: return 48
            }
        }
        
        var nameFont: Font {
            switch self {
            case .small: return .system(size: 10)
            case .medium: return .system(size: 12)
            case .large: return .system(size: 13)
            case .xlarge: return .system(size: 14)
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            case .xlarge: return 10
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        iconName: String,
        name: String,
        iconColor: Color,
        isSelected: Bool = false,
        size: IconSize = .medium,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.name = name
        self.iconColor = iconColor
        self.isSelected = isSelected
        self.size = size
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: size.spacing) {
                // 图标 (直接彩色显示)
                PhosphorIcon.icon(named: iconName, weight: isSelected ? .fill : .regular)
                    .frame(width: size.iconSize, height: size.iconSize)
                    .foregroundStyle(isSelected ? .primaryBlue : iconColor)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                // 分类名称
                Text(name)
                    .font(size.nameFont)
                    .foregroundColor(isSelected ? .primaryBlue : .primary)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Category Icon View (From Category Model)

/// 从Category模型创建的图标视图
struct CategoryIconFromModel: View {
    let category: Category
    let isSelected: Bool
    let size: CategoryIconView.IconSize
    let action: () -> Void
    
    var body: some View {
        CategoryIconView(
            iconName: category.iconName,
            name: category.name,
            iconColor: Color(hex: category.colorHex),
            isSelected: isSelected,
            size: size,
            action: action
        )
    }
}

// MARK: - Category Icon (Static Display)

/// 静态分类图标 (不可点击)
struct CategoryIconStatic: View {
    let iconName: String
    let iconColor: Color
    let size: CGFloat
    let weight: PhosphorIcon.IconWeight
    
    init(
        iconName: String,
        iconColor: Color,
        size: CGFloat = 24,
        weight: PhosphorIcon.IconWeight = .fill
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.size = size
        self.weight = weight
    }
    
    var body: some View {
        PhosphorIcon.icon(named: iconName, weight: weight)
            .frame(width: size, height: size)
            .foregroundStyle(iconColor)
    }
}

// MARK: - Preview

#Preview("Category Icon Sizes") {
    VStack(spacing: 40) {
        HStack(spacing: 30) {
            CategoryIconView(
                iconName: "forkKnife",
                name: "餐饮",
                iconColor: Color(hex: "FFB74D"),
                isSelected: false,
                size: .small
            ) {}
            
            CategoryIconView(
                iconName: "forkKnife",
                name: "餐饮",
                iconColor: Color(hex: "FFB74D"),
                isSelected: false,
                size: .medium
            ) {}
            
            CategoryIconView(
                iconName: "forkKnife",
                name: "餐饮",
                iconColor: Color(hex: "FFB74D"),
                isSelected: false,
                size: .large
            ) {}
            
            CategoryIconView(
                iconName: "forkKnife",
                name: "餐饮",
                iconColor: Color(hex: "FFB74D"),
                isSelected: false,
                size: .xlarge
            ) {}
        }
        
        Text("不同尺寸 (small / medium / large / xlarge)")
            .font(.caption)
            .foregroundStyle(.secondary)
        
        Divider()
        
        HStack(spacing: 30) {
            CategoryIconView(
                iconName: "car",
                name: "交通",
                iconColor: Color(hex: "64B5F6"),
                isSelected: false,
                size: .large
            ) {}
            
            CategoryIconView(
                iconName: "car",
                name: "交通",
                iconColor: Color(hex: "64B5F6"),
                isSelected: true,
                size: .large
            ) {}
        }
        
        Text("选中状态对比")
            .font(.caption)
            .foregroundStyle(.secondary)
        
        Divider()
        
        // 静态图标展示
        HStack(spacing: 20) {
            CategoryIconStatic(iconName: "gift", iconColor: Color(hex: "FF8A65"), size: 32, weight: .regular)
            CategoryIconStatic(iconName: "gift", iconColor: Color(hex: "FF8A65"), size: 32, weight: .fill)
        }
        
        Text("不同权重 (regular / fill)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("Category Grid") {
    ScrollView {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
            spacing: 16
        ) {
            ForEach(CategoryIconConfig.expenseHierarchy, id: \.name) { hierarchy in
                CategoryIconView(
                    iconName: hierarchy.style.iconName,
                    name: hierarchy.name,
                    iconColor: hierarchy.style.colorValue,
                    isSelected: hierarchy.name == "餐饮",
                    size: .medium
                ) {
                    print("Selected: \(hierarchy.name)")
                }
            }
        }
        .padding()
    }
}
