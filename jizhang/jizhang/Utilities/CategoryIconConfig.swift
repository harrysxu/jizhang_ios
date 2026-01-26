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
    
    /// 分类层级结构定义
    struct CategoryHierarchy {
        let name: String
        let style: CategoryStyle
        let children: [(name: String, style: CategoryStyle)]
    }
    
    // MARK: - Expense Categories (支出分类) - 父子结构
    
    /// 支出分类层级结构
    static let expenseHierarchy: [CategoryHierarchy] = [
        // 1. 餐饮
        CategoryHierarchy(
            name: "餐饮",
            style: CategoryStyle(icon: "fork.knife", color: "FFB74D"),
            children: [
                ("早餐", CategoryStyle(icon: "sunrise.fill", color: "FFCC80")),
                ("午餐", CategoryStyle(icon: "sun.max.fill", color: "FFB74D")),
                ("晚餐", CategoryStyle(icon: "moon.fill", color: "FFA726")),
                ("零食饮料", CategoryStyle(icon: "cup.and.saucer.fill", color: "A1887F")),
                ("水果", CategoryStyle(icon: "leaf.fill", color: "81C784"))
            ]
        ),
        // 2. 购物
        CategoryHierarchy(
            name: "购物",
            style: CategoryStyle(icon: "bag.fill", color: "E57373"),
            children: [
                ("衣服鞋帽", CategoryStyle(icon: "tshirt.fill", color: "E57373")),
                ("日用品", CategoryStyle(icon: "basket.fill", color: "AED581")),
                ("美妆护肤", CategoryStyle(icon: "sparkles", color: "F48FB1")),
                ("电器数码", CategoryStyle(icon: "laptopcomputer", color: "78909C"))
            ]
        ),
        // 3. 交通出行
        CategoryHierarchy(
            name: "交通出行",
            style: CategoryStyle(icon: "car.fill", color: "64B5F6"),
            children: [
                ("公共交通", CategoryStyle(icon: "bus.fill", color: "64B5F6")),
                ("打车", CategoryStyle(icon: "car.fill", color: "42A5F5")),
                ("汽车加油", CategoryStyle(icon: "fuelpump.fill", color: "90A4AE")),
                ("停车费", CategoryStyle(icon: "parkingsign.circle.fill", color: "78909C"))
            ]
        ),
        // 4. 居家生活
        CategoryHierarchy(
            name: "居家生活",
            style: CategoryStyle(icon: "house.fill", color: "FFB74D"),
            children: [
                ("房租房贷", CategoryStyle(icon: "house.fill", color: "FFB74D")),
                ("水电燃气", CategoryStyle(icon: "bolt.fill", color: "9FA8DA")),
                ("话费网费", CategoryStyle(icon: "phone.fill", color: "4DD0E1")),
                ("物业费", CategoryStyle(icon: "building.2.fill", color: "BCAAA4"))
            ]
        ),
        // 5. 娱乐休闲
        CategoryHierarchy(
            name: "娱乐休闲",
            style: CategoryStyle(icon: "gamecontroller.fill", color: "BA68C8"),
            children: [
                ("娱乐", CategoryStyle(icon: "gamecontroller.fill", color: "BA68C8")),
                ("运动健身", CategoryStyle(icon: "figure.run", color: "4DB6AC")),
                ("旅行度假", CategoryStyle(icon: "airplane", color: "81C784"))
            ]
        ),
        // 6. 医疗健康
        CategoryHierarchy(
            name: "医疗健康",
            style: CategoryStyle(icon: "cross.case.fill", color: "EF5350"),
            children: [
                ("看病挂号", CategoryStyle(icon: "cross.case.fill", color: "EF5350")),
                ("买药", CategoryStyle(icon: "pills.fill", color: "E57373")),
                ("保健品", CategoryStyle(icon: "leaf.circle.fill", color: "66BB6A"))
            ]
        ),
        // 7. 人情往来
        CategoryHierarchy(
            name: "人情往来",
            style: CategoryStyle(icon: "gift.fill", color: "FF8A65"),
            children: [
                ("请客吃饭", CategoryStyle(icon: "fork.knife.circle.fill", color: "FF8A65")),
                ("送礼", CategoryStyle(icon: "gift.fill", color: "FF7043")),
                ("红包礼金", CategoryStyle(icon: "envelope.fill", color: "E57373"))
            ]
        ),
        // 8. 学习培训
        CategoryHierarchy(
            name: "学习培训",
            style: CategoryStyle(icon: "book.fill", color: "4FC3F7"),
            children: [
                ("书籍资料", CategoryStyle(icon: "book.fill", color: "4FC3F7")),
                ("课程培训", CategoryStyle(icon: "person.fill.viewfinder", color: "29B6F6"))
            ]
        ),
        // 9. 其他
        CategoryHierarchy(
            name: "其他",
            style: CategoryStyle(icon: "ellipsis.circle.fill", color: "BDBDBD"),
            children: [
                ("孩子", CategoryStyle(icon: "figure.and.child.holdinghands", color: "FFD54F")),
                ("宠物", CategoryStyle(icon: "pawprint.fill", color: "9575CD")),
                ("烟酒", CategoryStyle(icon: "wineglass.fill", color: "F06292")),
                ("其他支出", CategoryStyle(icon: "ellipsis.circle.fill", color: "BDBDBD"))
            ]
        )
    ]
    
    // MARK: - Income Categories (收入分类) - 父子结构
    
    /// 收入分类层级结构
    static let incomeHierarchy: [CategoryHierarchy] = [
        // 1. 工作收入
        CategoryHierarchy(
            name: "工作收入",
            style: CategoryStyle(icon: "briefcase.fill", color: "4CAF50"),
            children: [
                ("工资", CategoryStyle(icon: "banknote.fill", color: "4CAF50")),
                ("奖金", CategoryStyle(icon: "gift.fill", color: "66BB6A")),
                ("补贴", CategoryStyle(icon: "plus.circle.fill", color: "81C784"))
            ]
        ),
        // 2. 投资理财
        CategoryHierarchy(
            name: "投资理财",
            style: CategoryStyle(icon: "chart.line.uptrend.xyaxis", color: "26A69A"),
            children: [
                ("理财收益", CategoryStyle(icon: "chart.line.uptrend.xyaxis", color: "26A69A")),
                ("股票基金", CategoryStyle(icon: "chart.bar.fill", color: "00897B"))
            ]
        ),
        // 3. 兼职副业
        CategoryHierarchy(
            name: "兼职副业",
            style: CategoryStyle(icon: "hammer.fill", color: "81C784"),
            children: [
                ("兼职", CategoryStyle(icon: "briefcase.fill", color: "81C784")),
                ("副业", CategoryStyle(icon: "hammer.fill", color: "66BB6A"))
            ]
        ),
        // 4. 其他收入
        CategoryHierarchy(
            name: "其他收入",
            style: CategoryStyle(icon: "plus.circle.fill", color: "AED581"),
            children: [
                ("报销", CategoryStyle(icon: "doc.text.fill", color: "AED581")),
                ("红包", CategoryStyle(icon: "envelope.fill", color: "FF8A80")),
                ("其他", CategoryStyle(icon: "plus.circle.fill", color: "BDBDBD"))
            ]
        )
    ]
    
    // MARK: - All Categories Dictionary (用于快速查找)
    
    static let expenseCategories: [String: CategoryStyle] = {
        var dict: [String: CategoryStyle] = [:]
        for hierarchy in expenseHierarchy {
            dict[hierarchy.name] = hierarchy.style
            for child in hierarchy.children {
                dict[child.name] = child.style
            }
        }
        return dict
    }()
    
    static let incomeCategories: [String: CategoryStyle] = {
        var dict: [String: CategoryStyle] = [:]
        for hierarchy in incomeHierarchy {
            dict[hierarchy.name] = hierarchy.style
            for child in hierarchy.children {
                dict[child.name] = child.style
            }
        }
        return dict
    }()
    
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
    
    /// 获取所有支出一级分类名称
    static var expenseCategoryNames: [String] {
        return expenseHierarchy.map { $0.name }
    }
    
    /// 获取所有收入一级分类名称
    static var incomeCategoryNames: [String] {
        return incomeHierarchy.map { $0.name }
    }
}

// MARK: - Preview Helper

#Preview("支出分类图标 - 层级结构") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(CategoryIconConfig.expenseHierarchy, id: \.name) { hierarchy in
                VStack(alignment: .leading, spacing: 12) {
                    // 父分类
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(hierarchy.style.colorValue)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: hierarchy.style.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        Text(hierarchy.name)
                            .font(.headline)
                    }
                    
                    // 子分类
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(hierarchy.children, id: \.name) { child in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(child.style.colorValue)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: child.style.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                
                                Text(child.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.leading, 56)
                }
                
                Divider()
            }
        }
        .padding()
    }
}

#Preview("收入分类图标 - 层级结构") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(CategoryIconConfig.incomeHierarchy, id: \.name) { hierarchy in
                VStack(alignment: .leading, spacing: 12) {
                    // 父分类
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(hierarchy.style.colorValue)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: hierarchy.style.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        Text(hierarchy.name)
                            .font(.headline)
                    }
                    
                    // 子分类
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(hierarchy.children, id: \.name) { child in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(child.style.colorValue)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: child.style.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                
                                Text(child.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.leading, 56)
                }
                
                Divider()
            }
        }
        .padding()
    }
}
