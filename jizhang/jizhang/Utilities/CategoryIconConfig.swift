//
//  CategoryIconConfig.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI

// MARK: - Category Icon Config

/// 分类图标配置 (参考UI样式)
struct CategoryIconConfig {
    
    // MARK: - Category Style
    
    struct CategoryStyle {
        let icon: String        // SF Symbol图标名称
        let color: String       // 十六进制颜色值
        
        init(icon: String, color: String) {
            self.icon = icon
            self.color = color
        }
        
        /// 获取SwiftUI Color对象
        var colorValue: Color {
            Color(hex: color)
        }
    }
    
    // MARK: - Expense Categories (支出分类)
    
    static let expenseCategories: [String: CategoryStyle] = [
        // 餐饮类
        "三餐": CategoryStyle(icon: "fork.knife", color: "FFB74D"),
        "零食": CategoryStyle(icon: "cup.and.saucer.fill", color: "A1887F"),
        
        // 购物类
        "衣服": CategoryStyle(icon: "tshirt.fill", color: "E57373"),
        "日用品": CategoryStyle(icon: "basket.fill", color: "AED581"),
        
        // 出行类
        "交通": CategoryStyle(icon: "car.fill", color: "64B5F6"),
        "旅行": CategoryStyle(icon: "airplane", color: "81C784"),
        "汽车/加油": CategoryStyle(icon: "fuelpump.fill", color: "90A4AE"),
        
        // 家庭类
        "住房": CategoryStyle(icon: "house.fill", color: "FFB74D"),
        "水电煤": CategoryStyle(icon: "bolt.fill", color: "9FA8DA"),
        "孩子": CategoryStyle(icon: "figure.and.child.holdinghands", color: "FFD54F"),
        
        // 娱乐类
        "娱乐": CategoryStyle(icon: "gamecontroller.fill", color: "BA68C8"),
        "运动": CategoryStyle(icon: "figure.run", color: "4DB6AC"),
        
        // 生活服务类
        "话费网费": CategoryStyle(icon: "phone.fill", color: "4DD0E1"),
        "医疗": CategoryStyle(icon: "cross.case.fill", color: "EF5350"),
        "美妆": CategoryStyle(icon: "sparkles", color: "F48FB1"),
        
        // 学习工作类
        "学习": CategoryStyle(icon: "book.fill", color: "4FC3F7"),
        "电器数码": CategoryStyle(icon: "laptopcomputer", color: "78909C"),
        
        // 社交类
        "请客送礼": CategoryStyle(icon: "gift.fill", color: "FF8A65"),
        "发红包": CategoryStyle(icon: "envelope.fill", color: "E57373"),
        
        // 其他类
        "宠物": CategoryStyle(icon: "pawprint.fill", color: "9575CD"),
        "烟酒": CategoryStyle(icon: "wineglass.fill", color: "F06292"),
        "其它": CategoryStyle(icon: "ellipsis.circle.fill", color: "BDBDBD")
    ]
    
    // MARK: - Income Categories (收入分类)
    
    static let incomeCategories: [String: CategoryStyle] = [
        "工资": CategoryStyle(icon: "banknote.fill", color: "4CAF50"),
        "奖金": CategoryStyle(icon: "gift.fill", color: "66BB6A"),
        "投资收益": CategoryStyle(icon: "chart.line.uptrend.xyaxis", color: "26A69A"),
        "兼职": CategoryStyle(icon: "briefcase.fill", color: "81C784"),
        "报销": CategoryStyle(icon: "doc.text.fill", color: "AED581"),
        "红包": CategoryStyle(icon: "envelope.fill", color: "FF8A80"),
        "其他收入": CategoryStyle(icon: "plus.circle.fill", color: "BDBDBD")
    ]
    
    // MARK: - Helper Methods
    
    /// 获取分类样式 (支出)
    static func expenseStyle(for categoryName: String) -> CategoryStyle {
        return expenseCategories[categoryName] ?? CategoryStyle(
            icon: "questionmark.circle.fill",
            color: "BDBDBD"
        )
    }
    
    /// 获取分类样式 (收入)
    static func incomeStyle(for categoryName: String) -> CategoryStyle {
        return incomeCategories[categoryName] ?? CategoryStyle(
            icon: "plus.circle.fill",
            color: "4CAF50"
        )
    }
    
    /// 获取分类样式 (根据类型自动选择)
    static func style(for categoryName: String, type: CategoryType) -> CategoryStyle {
        switch type {
        case .expense:
            return expenseStyle(for: categoryName)
        case .income:
            return incomeStyle(for: categoryName)
        }
    }
    
    /// 获取所有支出分类名称 (按推荐顺序)
    static var expenseCategoryNames: [String] {
        return [
            // 高频分类
            "三餐", "零食", "交通", "日用品",
            "衣服", "娱乐", "运动", "学习",
            // 中频分类
            "住房", "水电煤", "话费网费", "医疗",
            "美妆", "电器数码", "汽车/加油", "旅行",
            // 低频分类
            "请客送礼", "发红包", "孩子", "宠物",
            "烟酒", "其它"
        ]
    }
    
    /// 获取所有收入分类名称 (按推荐顺序)
    static var incomeCategoryNames: [String] {
        return [
            "工资", "奖金", "兼职", "投资收益",
            "报销", "红包", "其他收入"
        ]
    }
}

// MARK: - Preview Helper

#Preview("支出分类图标") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 20) {
            ForEach(CategoryIconConfig.expenseCategoryNames, id: \.self) { name in
                let style = CategoryIconConfig.expenseStyle(for: name)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(style.colorValue)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: style.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
    }
}

#Preview("收入分类图标") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 20) {
            ForEach(CategoryIconConfig.incomeCategoryNames, id: \.self) { name in
                let style = CategoryIconConfig.incomeStyle(for: name)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(style.colorValue)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: style.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
    }
}
