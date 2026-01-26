//
//  ButtonStyles.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI

// MARK: - Scale Button Style

/// 按压缩放按钮样式 (参考UI标准)
struct ScaleButtonStyle: ButtonStyle {
    var scaleEffect: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Primary Action Button Style

/// 主要操作按钮样式 (胶囊形状，用于空状态、创建等主要操作)
struct PrimaryActionButtonStyle: ButtonStyle {
    var backgroundColor: Color = .primaryBlue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Secondary Action Button Style

/// 次要操作按钮样式 (描边胶囊形状)
struct SecondaryActionButtonStyle: ButtonStyle {
    var borderColor: Color = .primaryBlue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(borderColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style

/// 图标按钮样式 (用于列表中的编辑、删除等操作)
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 32
    var iconColor: Color = .secondary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(iconColor)
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// 应用缩放按钮样式
    func scaleButtonStyle(scale: CGFloat = 0.95) -> some View {
        self.buttonStyle(ScaleButtonStyle(scaleEffect: scale))
    }
    
    /// 应用主要操作按钮样式
    func primaryActionButtonStyle(backgroundColor: Color = .primaryBlue) -> some View {
        self.buttonStyle(PrimaryActionButtonStyle(backgroundColor: backgroundColor))
    }
    
    /// 应用次要操作按钮样式
    func secondaryActionButtonStyle(borderColor: Color = .primaryBlue) -> some View {
        self.buttonStyle(SecondaryActionButtonStyle(borderColor: borderColor))
    }
    
    /// 应用图标按钮样式
    func iconButtonStyle(size: CGFloat = 32, iconColor: Color = .secondary) -> some View {
        self.buttonStyle(IconButtonStyle(size: size, iconColor: iconColor))
    }
}

// MARK: - Primary Action Button View

/// 统一的主要操作按钮组件 (用于空状态、创建等场景)
struct PrimaryActionButton: View {
    let title: String
    let icon: String?
    let backgroundColor: Color
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        backgroundColor: Color = .primaryBlue,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
            }
        }
        .primaryActionButtonStyle(backgroundColor: backgroundColor)
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: Spacing.l) {
        // 主要操作按钮
        PrimaryActionButton("创建预算", icon: "plus.circle.fill") {
            print("Primary button tapped")
        }
        
        // 次要操作按钮
        Button {
            print("Secondary button tapped")
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("导出数据")
            }
        }
        .secondaryActionButtonStyle()
        
        // 图标按钮
        HStack(spacing: Spacing.m) {
            Button {
                print("Edit tapped")
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 18))
            }
            .iconButtonStyle(iconColor: .primaryBlue)
            
            Button {
                print("Delete tapped")
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18))
            }
            .iconButtonStyle(iconColor: .expenseRed)
        }
        
        // 缩放按钮
        Button("缩放效果") {
            print("Scale button tapped")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.primaryBlue)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .scaleButtonStyle()
    }
    .padding()
}
