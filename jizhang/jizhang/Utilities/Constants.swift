//
//  Constants.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

// MARK: - Spacing

/// 间距系统 (基于8点网格系统)
enum Spacing {
    static let xxs: CGFloat = 2     // 极小间距
    static let xs: CGFloat = 4      // 超小间距
    static let s: CGFloat = 8       // 小间距
    static let m: CGFloat = 12      // 中间距
    static let l: CGFloat = 16      // 标准间距 ⭐
    static let xl: CGFloat = 20     // 大间距
    static let xxl: CGFloat = 24    // 超大间距
    static let xxxl: CGFloat = 32   // 特大间距
}

// MARK: - CornerRadius

/// 圆角系统
enum CornerRadius {
    static let small: CGFloat = 8    // 小圆角(按钮)
    static let medium: CGFloat = 12  // 中圆角(小卡片)
    static let large: CGFloat = 16   // 大圆角(主卡片) ⭐
    static let xlarge: CGFloat = 20  // 超大圆角(特殊组件)
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
    
    // 金额显示 (参考UI标准)
    static let amountXLarge: CGFloat = 52   // 净资产金额 ⭐
    static let amountLarge: CGFloat = 48    // 超大金额
    static let amountMedium: CGFloat = 30   // 月收支金额 ⭐
    static let amountSmall: CGFloat = 20    // 列表金额
    static let amountMini: CGFloat = 16     // 小号金额
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
    
    // MARK: - Category Colors
    
    /// 分类颜色预设 (参考UI样式)
    enum CategoryColors {
        // 餐饮类
        static let meals = Color(hex: "FFB74D")         // 三餐 - 橙色
        static let snacks = Color(hex: "A1887F")        // 零食 - 棕色
        
        // 购物类
        static let clothing = Color(hex: "E57373")      // 衣服 - 红色
        static let dailyGoods = Color(hex: "AED581")    // 日用品 - 浅绿
        
        // 出行类
        static let transport = Color(hex: "64B5F6")     // 交通 - 蓝色
        static let travel = Color(hex: "81C784")        // 旅行 - 绿色
        static let carGas = Color(hex: "90A4AE")        // 汽车/加油 - 灰蓝
        
        // 家庭类
        static let housing = Color(hex: "FFB74D")       // 住房 - 橙色
        static let utilities = Color(hex: "9FA8DA")     // 水电煤 - 蓝紫
        static let children = Color(hex: "FFD54F")      // 孩子 - 黄色
        
        // 娱乐类
        static let entertainment = Color(hex: "BA68C8") // 娱乐 - 紫色
        static let sports = Color(hex: "4DB6AC")        // 运动 - 青色
        
        // 生活服务类
        static let phone = Color(hex: "4DD0E1")         // 话费网费 - 青色
        static let medical = Color(hex: "EF5350")       // 医疗 - 红色
        static let beauty = Color(hex: "F48FB1")        // 美妆 - 粉色
        
        // 学习工作类
        static let study = Color(hex: "4FC3F7")         // 学习 - 浅蓝
        static let electronics = Color(hex: "78909C")   // 电器数码 - 灰色
        
        // 社交类
        static let gifts = Color(hex: "FF8A65")         // 请客送礼 - 橙红
        static let redEnvelope = Color(hex: "E57373")   // 发红包 - 红色
        
        // 其他类
        static let pets = Color(hex: "9575CD")          // 宠物 - 紫色
        static let tobacco = Color(hex: "F06292")       // 烟酒 - 粉色
        static let other = Color(hex: "BDBDBD")         // 其它 - 灰色
    }
    
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

/// 布局常量
enum Layout {
    /// TabBar 底部安全间距 - 用于 ScrollView 等需要避开 TabBar 的内容
    static let tabBarBottomPadding: CGFloat = 90
}

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

// MARK: - Subscription Products

/// 订阅产品ID
enum SubscriptionProducts {
    /// 月订阅 - 6元/月
    static let monthlyID = "com.xxl.jizhang.subscription.monthly"
    
    /// 年订阅 - 38元/年
    static let yearlyID = "com.xxl.jizhang.subscription.yearly"
    
    /// 买断 - 99元
    static let lifetimeID = "com.xxl.jizhang.lifetime"
    
    /// 所有产品ID
    static let allProductIDs: Set<String> = [monthlyID, yearlyID, lifetimeID]
}
