//
//  CategoryIconView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI

// MARK: - Category Icon View

/// 分类图标组件 (参考UI样式 - 圆形背景色块)
struct CategoryIconView: View {
    
    // MARK: - Properties
    
    let icon: String
    let name: String
    let backgroundColor: Color
    let isSelected: Bool
    let size: IconSize
    let action: () -> Void
    
    // MARK: - Icon Size Enum
    
    enum IconSize {
        case small      // 40×40
        case medium     // 48×48
        case large      // 56×56
        
        var circleSize: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 48
            case .large: return 56
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 24
            case .large: return 28
            }
        }
        
        var nameFont: Font {
            switch self {
            case .small: return .system(size: 11)
            case .medium: return .system(size: 13)
            case .large: return .system(size: 15)
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        icon: String,
        name: String,
        backgroundColor: Color,
        isSelected: Bool = false,
        size: IconSize = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.name = name
        self.backgroundColor = backgroundColor
        self.isSelected = isSelected
        self.size = size
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 图标背景圆
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: size.circleSize, height: size.circleSize)
                    
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Color.primaryBlue : Color.clear,
                            lineWidth: 2.5
                        )
                )
                .shadow(
                    color: isSelected ? Color.primaryBlue.opacity(0.3) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
                
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
            icon: category.iconName,
            name: category.name,
            backgroundColor: Color(hex: category.colorHex),
            isSelected: isSelected,
            size: size,
            action: action
        )
    }
}

// MARK: - Preview

#Preview("Category Icon Sizes") {
    VStack(spacing: 40) {
        HStack(spacing: 20) {
            CategoryIconView(
                icon: "fork.knife",
                name: "三餐",
                backgroundColor: Color(hex: "FFB74D"),
                isSelected: false,
                size: .small
            ) {}
            
            CategoryIconView(
                icon: "fork.knife",
                name: "三餐",
                backgroundColor: Color(hex: "FFB74D"),
                isSelected: false,
                size: .medium
            ) {}
            
            CategoryIconView(
                icon: "fork.knife",
                name: "三餐",
                backgroundColor: Color(hex: "FFB74D"),
                isSelected: false,
                size: .large
            ) {}
        }
        
        Text("不同尺寸")
            .font(.caption)
            .foregroundStyle(.secondary)
        
        Divider()
        
        HStack(spacing: 20) {
            CategoryIconView(
                icon: "car.fill",
                name: "交通",
                backgroundColor: Color(hex: "64B5F6"),
                isSelected: false,
                size: .medium
            ) {}
            
            CategoryIconView(
                icon: "car.fill",
                name: "交通",
                backgroundColor: Color(hex: "64B5F6"),
                isSelected: true,
                size: .medium
            ) {}
        }
        
        Text("选中状态")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("Category Grid") {
    ScrollView {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
            spacing: 20
        ) {
            ForEach(CategoryIconConfig.expenseCategoryNames, id: \.self) { name in
                let style = CategoryIconConfig.expenseStyle(for: name)
                
                CategoryIconView(
                    icon: style.icon,
                    name: name,
                    backgroundColor: style.colorValue,
                    isSelected: name == "三餐",
                    size: .medium
                ) {
                    print("Selected: \(name)")
                }
            }
        }
        .padding()
    }
}
