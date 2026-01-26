//
//  GlassCard.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI

// MARK: - Glass Card

/// 毛玻璃效果卡片组件 (参考UI样式)
struct GlassCard<Content: View>: View {
    
    // MARK: - Properties
    
    let content: Content
    let material: Material
    let cornerRadius: CGFloat
    let padding: CGFloat
    let hasBorder: Bool
    let hasShadow: Bool
    
    // MARK: - Initialization
    
    /// 创建毛玻璃卡片
    /// - Parameters:
    ///   - material: 毛玻璃材质 (默认: .ultraThinMaterial)
    ///   - cornerRadius: 圆角大小 (默认: 16)
    ///   - padding: 内边距 (默认: 20)
    ///   - hasBorder: 是否显示边框 (默认: true)
    ///   - hasShadow: 是否显示阴影 (默认: true)
    ///   - content: 卡片内容
    init(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = CornerRadius.large,
        padding: CGFloat = Spacing.xl,
        hasBorder: Bool = true,
        hasShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.hasBorder = hasBorder
        self.hasShadow = hasShadow
    }
    
    // MARK: - Body
    
    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
    }
    
    // MARK: - Card Background
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(material)
            .overlay(borderOverlay)
            .shadow(
                color: hasShadow ? .black.opacity(0.05) : .clear,
                radius: hasShadow ? 10 : 0,
                x: 0,
                y: hasShadow ? 5 : 0
            )
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                hasBorder ? Color.white.opacity(0.2) : Color.clear,
                lineWidth: hasBorder ? 1 : 0
            )
    }
}

// MARK: - Glass Card Modifiers

extension View {
    /// 应用毛玻璃卡片样式
    func glassCardStyle(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = CornerRadius.large,
        padding: CGFloat = Spacing.xl
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
    }
}

// MARK: - Glass Card Variants

/// 简洁版毛玻璃卡片 (无边框、无阴影)
struct SimpleGlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(.thinMaterial)
            )
    }
}

/// 强调版毛玻璃卡片 (更厚的材质)
struct ThickGlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            )
    }
}

// MARK: - Preview

#Preview("Glass Card Examples") {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            // 标准毛玻璃卡片
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("标准毛玻璃卡片")
                        .font(.headline)
                    
                    Text("使用 ultraThinMaterial 材质")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Spacer()
                        Text("¥12,345.67")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                }
            }
            
            // 简洁版
            SimpleGlassCard {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("简洁版卡片")
                        .font(.headline)
                    
                    Text("无边框、无阴影")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 强调版
            ThickGlassCard {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("强调版卡片")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("使用 regularMaterial 材质，更强的层次感")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 使用modifier的示例
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("使用Modifier")
                    .font(.headline)
                
                Text("通过 .glassCardStyle() 应用样式")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .glassCardStyle()
        }
        .padding(Spacing.l)
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    )
}

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("深色模式卡片")
                        .font(.headline)
                    
                    Text("毛玻璃效果自动适配深色模式")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Spacer()
                        Text("¥9,876.54")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(Spacing.l)
    }
    .background(Color.black.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
