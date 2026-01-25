//
//  SuishoujiColors.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//  随手记风格颜色系统
//

import SwiftUI

/// 随手记风格颜色系统
enum SuishoujiColors {
    // MARK: - 渐变色系统
    
    /// 首页主卡片渐变 (亮色模式)
    static let homeGradientLight = [
        Color(hex: "#1FB6B9"),  // 青蓝色
        Color(hex: "#39CED1"),  // 浅青色
        Color(hex: "#4FD6D8")   // 浅绿青色
    ]
    
    /// 首页主卡片渐变 (暗色模式)
    static let homeGradientDark = [
        Color(hex: "#1A8B8D"),  // 降低亮度的青蓝色
        Color(hex: "#2A9FA2"),  // 降低亮度的浅青色
        Color(hex: "#3AAFB1")   // 降低亮度的浅绿青色
    ]
    
    /// 报表页渐变 (亮色模式)
    static let reportGradientLight = [
        Color(hex: "#8FBF5A"),  // 草绿色
        Color(hex: "#9ED86D"),  // 嫩绿色
        Color(hex: "#B5E87E")   // 浅绿色
    ]
    
    /// 报表页渐变 (暗色模式)
    static let reportGradientDark = [
        Color(hex: "#6A8F4A"),  // 降低亮度的草绿色
        Color(hex: "#7AA85D"),  // 降低亮度的嫩绿色
        Color(hex: "#8ABE6E")   // 降低亮度的浅绿色
    ]
    
    /// 添加按钮渐变 (亮色模式)
    static let addButtonGradientLight = [
        Color(hex: "#FFB366"),  // 浅橙色
        Color(hex: "#FF8F59")   // 橙色
    ]
    
    /// 添加按钮渐变 (暗色模式)
    static let addButtonGradientDark = [
        Color(hex: "#CC8F52"),  // 降低亮度的浅橙色
        Color(hex: "#CC7247")   // 降低亮度的橙色
    ]
    
    // MARK: - 功能色
    
    /// 支出红色 (柔和版本)
    static let expenseRed = Color(hex: "#FF6B6B")
    
    /// 收入绿色 (温和版本)
    static let incomeGreen = Color(hex: "#51CF66")
    
    /// 警告橙色
    static let warningOrange = Color(hex: "#FF922B")
    
    /// 品牌蓝色 (用于按钮、链接)
    static let brandBlue = Color(hex: "#339AF0")
    
    // MARK: - 背景色
    
    /// 页面背景 (亮色模式)
    static let pageBackgroundLight = Color(hex: "#F7F7F7")
    
    /// 页面背景 (暗色模式)
    static let pageBackgroundDark = Color(hex: "#000000")
    
    /// 卡片白色 (亮色模式)
    static let cardBackgroundLight = Color(hex: "#FFFFFF")
    
    /// 卡片背景 (暗色模式)
    static let cardBackgroundDark = Color(hex: "#1C1C1E")
    
    /// 分组背景 (亮色模式)
    static let groupedBackgroundLight = Color(hex: "#F2F2F7")
    
    /// 分组背景 (暗色模式)
    static let groupedBackgroundDark = Color(hex: "#1C1C1E")
    
    // MARK: - 文字颜色
    
    /// 主要文字 (亮色模式)
    static let textPrimaryLight = Color(hex: "#1C1C1E")
    
    /// 主要文字 (暗色模式)
    static let textPrimaryDark = Color(hex: "#FFFFFF")
    
    /// 次要文字 (亮色模式)
    static let textSecondaryLight = Color(hex: "#8E8E93")
    
    /// 次要文字 (暗色模式)
    static let textSecondaryDark = Color(hex: "#8E8E93")
    
    /// 三级文字 (亮色模式)
    static let textTertiaryLight = Color(hex: "#C7C7CC")
    
    /// 三级文字 (暗色模式)
    static let textTertiaryDark = Color(hex: "#48484A")
    
    // MARK: - 分类颜色预设
    
    enum CategoryColor {
        static let dining = "#FF8F59"         // 橙色 - 餐饮
        static let transport = "#5B9FED"      // 蓝色 - 交通
        static let shopping = "#FF6B9D"       // 粉色 - 购物
        static let housing = "#9B59B6"        // 紫色 - 居住
        static let entertainment = "#F368E0"  // 亮粉 - 娱乐
        static let healthcare = "#00D2D3"     // 青色 - 医疗
        static let education = "#FFA502"      // 深橙 - 教育
        static let social = "#26DE81"         // 绿色 - 社交
        static let clothing = "#FDA7DF"       // 浅粉 - 服饰
        static let beauty = "#FF85C2"         // 玫粉 - 美容
        static let pet = "#95E1D3"            // 薄荷绿 - 宠物
        static let digital = "#786BED"        // 靛蓝 - 数码
        static let gift = "#F97C7C"           // 淡红 - 礼物
        static let travel = "#1E88E5"         // 海蓝 - 旅行
        static let others = "#A8A8A8"         // 灰色 - 其他
    }
    
    // MARK: - 辅助方法
    
    /// 根据当前颜色模式获取首页渐变色
    static func homeGradient(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? homeGradientDark : homeGradientLight
    }
    
    /// 根据当前颜色模式获取报表页渐变色
    static func reportGradient(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? reportGradientDark : reportGradientLight
    }
    
    /// 根据当前颜色模式获取添加按钮渐变色
    static func addButtonGradient(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? addButtonGradientDark : addButtonGradientLight
    }
    
    /// 根据当前颜色模式获取页面背景色
    static func pageBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? pageBackgroundDark : pageBackgroundLight
    }
    
    /// 根据当前颜色模式获取卡片背景色
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardBackgroundDark : cardBackgroundLight
    }
    
    /// 根据当前颜色模式获取分组背景色
    static func groupedBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? groupedBackgroundDark : groupedBackgroundLight
    }
    
    /// 根据当前颜色模式获取主要文字颜色
    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textPrimaryDark : textPrimaryLight
    }
    
    /// 根据当前颜色模式获取次要文字颜色
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textSecondaryDark : textSecondaryLight
    }
    
    /// 根据当前颜色模式获取三级文字颜色
    static func textTertiary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textTertiaryDark : textTertiaryLight
    }
}

// MARK: - SwiftUI Color扩展

extension Color {
    /// 随手记风格 - 支出红色
    static var suishoujiExpenseRed: Color {
        SuishoujiColors.expenseRed
    }
    
    /// 随手记风格 - 收入绿色
    static var suishoujiIncomeGreen: Color {
        SuishoujiColors.incomeGreen
    }
    
    /// 随手记风格 - 警告橙色
    static var suishoujiWarningOrange: Color {
        SuishoujiColors.warningOrange
    }
    
    /// 随手记风格 - 品牌蓝色
    static var suishoujiBrandBlue: Color {
        SuishoujiColors.brandBlue
    }
}
