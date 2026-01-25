//
//  Constants.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

// MARK: - Spacing

/// 间距系统
enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - CornerRadius

/// 圆角系统
enum CornerRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
}

// MARK: - FontSize

/// 字体大小
enum FontSize {
    static let largeTitle: CGFloat = 34
    static let title: CGFloat = 28
    static let title2: CGFloat = 22
    static let title3: CGFloat = 20
    static let headline: CGFloat = 17
    static let body: CGFloat = 17
    static let callout: CGFloat = 16
    static let subheadline: CGFloat = 15
    static let footnote: CGFloat = 13
    static let caption: CGFloat = 12
    
    // 金额显示
    static let amountLarge: CGFloat = 48
    static let amountMedium: CGFloat = 32
    static let amountSmall: CGFloat = 24
}

// MARK: - AnimationDuration

/// 动画时长
enum AnimationDuration {
    static let fast: Double = 0.2
    static let normal: Double = 0.3
    static let slow: Double = 0.5
}

// MARK: - Color Extensions

extension Color {
    // MARK: - Primary Colors
    
    /// 主色调
    static var primaryBlue: Color {
        Color(hex: "#007AFF")
    }
    
    // MARK: - Function Colors
    
    /// 收入绿色
    static var incomeGreen: Color {
        Color(hex: "#34C759")
    }
    
    /// 支出红色
    static var expenseRed: Color {
        Color(hex: "#FF3B30")
    }
    
    /// 警告橙色
    static var warningOrange: Color {
        Color(hex: "#FF9500")
    }
    
    // MARK: - Background Colors
    
    /// 卡片背景(亮色模式)
    static let cardBackgroundLight = Color(hex: "#FFFFFF")
    
    /// 卡片背景(暗色模式)
    static let cardBackgroundDark = Color(hex: "#1C1C1E")
    
    /// 分组背景(亮色模式)
    static let groupedBackgroundLight = Color(hex: "#F2F2F7")
    
    /// 分组背景(暗色模式)
    static let groupedBackgroundDark = Color(hex: "#000000")
    
    // MARK: - Helper: Hex Initializer
    
    /// 从Hex字符串初始化颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Constants

/// 应用常量
enum AppConstants {
    /// App名称
    static let appName = "简记账"
    
    /// App Groups标识符 (用于Widget和Live Activity数据共享)
    static let appGroupIdentifier = "group.com.xxl.jizhang"
    
    /// URL Scheme
    static let urlScheme = "jizhang"
    
    /// 默认货币代码
    static let defaultCurrencyCode = "CNY"
    
    /// 默认货币符号
    static let defaultCurrencySymbol = "¥"
    
    /// 每页加载数量
    static let pageSize = 50
    
    /// 最大金额
    static let maxAmount: Decimal = 999_999_999.99
}
