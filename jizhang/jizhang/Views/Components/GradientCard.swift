//
//  GradientCard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//  随手记风格渐变卡片组件
//

import SwiftUI

/// 随手记风格渐变卡片
struct GradientCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let lightGradient: [Color]
    let darkGradient: [Color]
    let height: CGFloat
    let cornerRadius: CGFloat
    let showDecorativeCircles: Bool
    let content: Content
    
    init(
        lightGradient: [Color],
        darkGradient: [Color],
        height: CGFloat = 200,
        cornerRadius: CGFloat = 20,
        showDecorativeCircles: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.lightGradient = lightGradient
        self.darkGradient = darkGradient
        self.height = height
        self.cornerRadius = cornerRadius
        self.showDecorativeCircles = showDecorativeCircles
        self.content = content()
    }
    
    private var gradientColors: [Color] {
        colorScheme == .dark ? darkGradient : lightGradient
    }
    
    private var shadowColor: Color {
        (colorScheme == .dark ? darkGradient.first : lightGradient.first)?.opacity(0.3) ?? Color.clear
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 渐变背景
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 装饰性圆点
            if showDecorativeCircles {
                DecorativeCircles()
            }
            
            // 内容
            content
        }
        .frame(height: height)
        .cornerRadius(cornerRadius)
        .shadow(color: shadowColor, radius: 15, x: 0, y: 8)
        .padding(.horizontal, 16)
    }
}

/// 装饰性圆点组件
struct DecorativeCircles: View {
    var body: some View {
        ZStack {
            // 左上角大圆点
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 120, height: 120)
                .offset(x: -40, y: -30)
            
            // 右上角小圆点
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 80, height: 80)
                .offset(x: UIScreen.main.bounds.width - 100, y: -20)
        }
    }
}

/// 占位插画视图 (纯色圆形代替)
struct PlaceholderIllustration: View {
    let color: Color
    let size: CGFloat
    let alignment: Alignment
    
    init(color: Color = .white, size: CGFloat = 150, alignment: Alignment = .bottomTrailing) {
        self.color = color
        self.size = size
        self.alignment = alignment
    }
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.15))
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(.trailing, alignment == .bottomTrailing ? -30 : 0)
            .padding(.bottom, alignment == .bottomTrailing ? -30 : 0)
    }
}

// MARK: - Preview

#Preview("渐变卡片示例") {
    VStack(spacing: 20) {
        // 首页风格卡片
        GradientCard(
            lightGradient: SuishoujiColors.homeGradientLight,
            darkGradient: SuishoujiColors.homeGradientDark,
            height: 200
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("本月收支")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("12,345.67")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("总收入")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("8,900.00")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("结余")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("-3,445.67")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(24)
        }
        
        // 报表风格卡片
        GradientCard(
            lightGradient: SuishoujiColors.reportGradientLight,
            darkGradient: SuishoujiColors.reportGradientDark,
            height: 120
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("账本流水统计")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("收入")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("8,900")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("支出")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("12,345")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        
        Spacer()
    }
    .padding()
    .background(SuishoujiColors.pageBackgroundLight)
}
