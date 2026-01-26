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

// MARK: - View Extensions

extension View {
    /// 应用缩放按钮样式
    func scaleButtonStyle(scale: CGFloat = 0.95) -> some View {
        self.buttonStyle(ScaleButtonStyle(scaleEffect: scale))
    }
}

// MARK: - Preview

#Preview("Scale Button Style") {
    VStack(spacing: Spacing.l) {
        Button("点击我") {
            print("Scale button tapped")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.blue)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .scaleButtonStyle()
    }
    .padding()
}
