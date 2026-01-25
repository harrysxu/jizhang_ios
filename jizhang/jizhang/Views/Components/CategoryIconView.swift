//
//  CategoryIconView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//  随手记风格分类图标视图
//

import SwiftUI

/// 随手记风格分类图标容器
struct CategoryIconView: View {
    let iconName: String
    let colorHex: String
    let size: CGFloat
    
    init(iconName: String, colorHex: String, size: CGFloat = 44) {
        self.iconName = iconName
        self.colorHex = colorHex
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 背景容器 - 使用圆角矩形
            RoundedRectangle(cornerRadius: size * 0.27)
                .fill(Color(hex: colorHex).opacity(0.15))
                .frame(width: size, height: size)
            
            // 图标
            Image(systemName: iconName)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(Color(hex: colorHex))
        }
    }
}

/// 圆形风格的分类图标容器
struct CircleCategoryIconView: View {
    let iconName: String
    let colorHex: String
    let size: CGFloat
    
    init(iconName: String, colorHex: String, size: CGFloat = 44) {
        self.iconName = iconName
        self.colorHex = colorHex
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 背景容器 - 圆形
            Circle()
                .fill(Color(hex: colorHex).opacity(0.15))
                .frame(width: size, height: size)
            
            // 图标
            Image(systemName: iconName)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(Color(hex: colorHex))
        }
    }
}

// MARK: - Preview

#Preview("分类图标示例") {
    VStack(spacing: 30) {
        // 圆角方形样式
        VStack(spacing: 16) {
            Text("圆角方形样式")
                .font(.headline)
            
            HStack(spacing: 20) {
                CategoryIconView(
                    iconName: "fork.knife",
                    colorHex: SuishoujiColors.CategoryColor.dining,
                    size: 44
                )
                
                CategoryIconView(
                    iconName: "car.fill",
                    colorHex: SuishoujiColors.CategoryColor.transport,
                    size: 44
                )
                
                CategoryIconView(
                    iconName: "cart.fill",
                    colorHex: SuishoujiColors.CategoryColor.shopping,
                    size: 44
                )
                
                CategoryIconView(
                    iconName: "house.fill",
                    colorHex: SuishoujiColors.CategoryColor.housing,
                    size: 44
                )
            }
            
            HStack(spacing: 20) {
                CategoryIconView(
                    iconName: "gamecontroller.fill",
                    colorHex: SuishoujiColors.CategoryColor.entertainment,
                    size: 44
                )
                
                CategoryIconView(
                    iconName: "cross.case.fill",
                    colorHex: SuishoujiColors.CategoryColor.healthcare,
                    size: 44
                )
                
                CategoryIconView(
                    iconName: "book.fill",
                    colorHex: SuishoujiColors.CategoryColor.education,
                    size: 44
                )
                
                CategoryIconView(
                    iconName: "heart.fill",
                    colorHex: SuishoujiColors.CategoryColor.social,
                    size: 44
                )
            }
        }
        
        Divider()
            .padding(.horizontal)
        
        // 圆形样式
        VStack(spacing: 16) {
            Text("圆形样式")
                .font(.headline)
            
            HStack(spacing: 20) {
                CircleCategoryIconView(
                    iconName: "tshirt.fill",
                    colorHex: SuishoujiColors.CategoryColor.clothing,
                    size: 44
                )
                
                CircleCategoryIconView(
                    iconName: "face.smiling",
                    colorHex: SuishoujiColors.CategoryColor.beauty,
                    size: 44
                )
                
                CircleCategoryIconView(
                    iconName: "pawprint.fill",
                    colorHex: SuishoujiColors.CategoryColor.pet,
                    size: 44
                )
                
                CircleCategoryIconView(
                    iconName: "iphone",
                    colorHex: SuishoujiColors.CategoryColor.digital,
                    size: 44
                )
            }
        }
        
        Divider()
            .padding(.horizontal)
        
        // 不同尺寸示例
        VStack(spacing: 16) {
            Text("不同尺寸")
                .font(.headline)
            
            HStack(spacing: 20) {
                CategoryIconView(
                    iconName: "gift.fill",
                    colorHex: SuishoujiColors.CategoryColor.gift,
                    size: 32
                )
                
                CategoryIconView(
                    iconName: "gift.fill",
                    colorHex: SuishoujiColors.CategoryColor.gift,
                    size: 44
                )
                
                CategoryIconView(
                    iconName: "gift.fill",
                    colorHex: SuishoujiColors.CategoryColor.gift,
                    size: 56
                )
            }
        }
        
        Spacer()
    }
    .padding()
}
