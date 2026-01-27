//
//  CategoryIconConfig.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//
//  分类图标配置
//  直接使用彩色图标显示，无圆形背景
//
//  注意: 需要在 Xcode 中添加 PhosphorSwift 依赖:
//  File > Add Package Dependencies... > https://github.com/phosphor-icons/swift
//

import SwiftUI

// 条件编译：如果有 PhosphorSwift 则使用，否则使用 SF Symbols 后备方案
#if canImport(PhosphorSwift)
import PhosphorSwift
let usePhosphorIcons = true
#else
let usePhosphorIcons = false
#endif

// MARK: - Category Icon Config

/// 分类图标配置
struct CategoryIconConfig {
    
    // MARK: - Category Style
    
    struct CategoryStyle {
        let iconName: String        // Phosphor图标名称
        let sfSymbolName: String    // SF Symbol后备图标名称
        let color: String           // 十六进制颜色值
        
        init(icon: String, sfSymbol: String, color: String) {
            self.iconName = icon
            self.sfSymbolName = sfSymbol
            self.color = color
        }
        
        /// 便捷初始化（使用默认的SF Symbol映射）
        init(icon: String, color: String) {
            self.iconName = icon
            self.sfSymbolName = CategoryIconConfig.phosphorToSFSymbol[icon] ?? "questionmark.circle"
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
    
    // MARK: - SF Symbol to Phosphor Mapping (用于兼容旧数据)
    
    /// SF Symbol图标到Phosphor图标的映射表（用于兼容数据库中的旧图标名称）
    static let sfSymbolToPhosphor: [String: String] = [
        // 餐饮类
        "fork.knife": "forkKnife",
        "cup.and.saucer.fill": "coffee",
        "sunrise.fill": "sunHorizon",
        "sun.max.fill": "sun",
        "moon.fill": "moon",
        "leaf.fill": "leaf",
        
        // 购物类
        "bag.fill": "shoppingBag",
        "tshirt.fill": "tShirt",
        "basket.fill": "basket",
        "sparkles": "sparkle",
        "laptopcomputer": "laptop",
        
        // 交通出行类
        "car.fill": "car",
        "bus.fill": "bus",
        "fuelpump.fill": "gasPump",
        "parkingsign.circle.fill": "parking",
        
        // 居家生活类
        "house.fill": "house",
        "bolt.fill": "lightning",
        "phone.fill": "phone",
        "building.2.fill": "buildings",
        
        // 娱乐休闲类
        "gamecontroller.fill": "gameController",
        "figure.run": "personSimpleRun",
        "airplane": "airplaneTilt",
        
        // 医疗健康类
        "cross.case.fill": "firstAidKit",
        "pills.fill": "pill",
        
        // 人情往来类
        "gift.fill": "gift",
        "envelope.fill": "envelopeSimple",
        "fork.knife.circle.fill": "forkKnife",
        
        // 学习培训类
        "book.fill": "bookOpen",
        "person.fill.viewfinder": "chalkboardTeacher",
        
        // 其他类
        "figure.and.child.holdinghands": "baby",
        "pawprint.fill": "pawPrint",
        "wineglass.fill": "wine",
        "ellipsis.circle.fill": "dotsThreeCircle",
        
        // 收入类
        "briefcase.fill": "briefcase",
        "banknote.fill": "money",
        "trophy.fill": "trophy",
        "plus.circle.fill": "plusCircle",
        "chart.line.uptrend.xyaxis": "trendUp",
        "chart.bar.fill": "chartBar",
        "hammer.fill": "hammer",
        "doc.text.fill": "receipt",
        "leaf.circle.fill": "leaf",
        
        // 常用 UI 图标
        "folder.fill": "folder",
        "gearshape.fill": "gear",
        "list.bullet.rectangle.fill": "listDashes",
        "list.bullet.rectangle": "listDashes",
        "creditcard.fill": "creditCard",
        "dollarsign.circle.fill": "currencyCircleDollar",
        "icloud.fill": "cloud",
        "flask.fill": "flask",
        "arrow.counterclockwise": "arrowCounterClockwise",
        "trash.fill": "trash",
        "arrow.left.arrow.right": "arrowsLeftRight",
        "slider.horizontal.3": "slidersHorizontal",
        "tray": "tray",
        "tray.fill": "tray",
        "questionmark.circle": "question",
        "questionmark.circle.fill": "question"
    ]
    
    // MARK: - Phosphor to SF Symbol Mapping
    
    /// Phosphor图标到SF Symbol的映射表
    static let phosphorToSFSymbol: [String: String] = [
        // Tab Bar
        "house": "house.fill",
        "listDashes": "list.bullet.rectangle.fill",
        "chartBar": "chart.bar.fill",
        "gear": "gearshape.fill",
        "plus": "plus",
        
        // 餐饮类
        "forkKnife": "fork.knife",
        "sunHorizon": "sunrise.fill",
        "sun": "sun.max.fill",
        "moon": "moon.fill",
        "coffee": "cup.and.saucer.fill",
        "orangeSlice": "circle.hexagongrid.fill",  // SF Symbol 中没有橙子图标，使用此图标作为后备
        
        // 购物类
        "shoppingBag": "bag.fill",
        "tShirt": "tshirt.fill",
        "basket": "basket.fill",
        "sparkle": "sparkles",
        "laptop": "laptopcomputer",
        
        // 交通出行类
        "car": "car.fill",
        "bus": "bus.fill",
        "taxi": "car.fill",
        "gasPump": "fuelpump.fill",
        "parking": "parkingsign.circle.fill",
        
        // 居家生活类
        "houseLine": "house.fill",
        "lightning": "bolt.fill",
        "phone": "phone.fill",
        "buildings": "building.2.fill",
        
        // 娱乐休闲类
        "gameController": "gamecontroller.fill",
        "personSimpleRun": "figure.run",
        "airplaneTilt": "airplane",
        
        // 医疗健康类
        "firstAidKit": "cross.case.fill",
        "pill": "pills.fill",
        "leaf": "leaf.fill",
        
        // 人情往来类
        "gift": "gift.fill",
        "envelopeSimple": "envelope.fill",
        
        // 学习培训类
        "bookOpen": "book.fill",
        "chalkboardTeacher": "person.fill.viewfinder",
        
        // 其他类
        "baby": "figure.and.child.holdinghands",
        "pawPrint": "pawprint.fill",
        "wine": "wineglass.fill",
        "dotsThreeCircle": "ellipsis.circle.fill",
        
        // 收入类
        "briefcase": "briefcase.fill",
        "money": "banknote.fill",
        "trophy": "trophy.fill",
        "plusCircle": "plus.circle.fill",
        "trendUp": "chart.line.uptrend.xyaxis",
        "chartLineUp": "chart.bar.fill",
        "hammer": "hammer.fill",
        "receipt": "doc.text.fill",
        
        // 常用 UI 图标
        "pencilSimple": "pencil",
        "trash": "trash.fill",
        "magnifyingGlass": "magnifyingglass",
        "funnel": "line.3.horizontal.decrease.circle.fill",
        "calendar": "calendar",
        "clock": "clock.fill",
        "wallet": "wallet.pass.fill",
        "creditCard": "creditcard.fill",
        "currencyCircleDollar": "dollarsign.circle.fill",
        "arrowUp": "arrow.up",
        "arrowDown": "arrow.down",
        "arrowsLeftRight": "arrow.left.arrow.right",
        "caretLeft": "chevron.left",
        "caretRight": "chevron.right",
        "caretDown": "chevron.down",
        "caretUp": "chevron.up",
        "x": "xmark",
        "check": "checkmark",
        "info": "info.circle.fill",
        "warning": "exclamationmark.triangle.fill",
        "xCircle": "xmark.circle.fill",
        "checkCircle": "checkmark.circle.fill",
        "image": "photo.fill",
        "camera": "camera.fill",
        "share": "square.and.arrow.up",
        "export": "square.and.arrow.up",
        "cloudArrowUp": "icloud.and.arrow.up.fill",
        "notebook": "book.fill",
        "piggyBank": "dollarsign.circle.fill",
        "tag": "tag.fill",
        "noteBlank": "note.text",
        "user": "person.fill",
        "dotsThree": "ellipsis",
        "question": "questionmark.circle.fill",
        
        // 设置页面图标
        "folder": "folder.fill",
        "cloud": "icloud.fill",
        "flask": "flask.fill",
        "arrowCounterClockwise": "arrow.counterclockwise",
        
        // 交易相关图标
        "slidersHorizontal": "slider.horizontal.3",
        "tray": "tray.fill"
    ]
    
    // MARK: - Expense Categories (支出分类) - 父子结构
    
    /// 支出分类层级结构
    static let expenseHierarchy: [CategoryHierarchy] = [
        // 1. 餐饮
        CategoryHierarchy(
            name: "餐饮",
            style: CategoryStyle(icon: "forkKnife", color: "FFB74D"),
            children: [
                ("早餐", CategoryStyle(icon: "sunHorizon", color: "FFCC80")),
                ("午餐", CategoryStyle(icon: "sun", color: "FFB74D")),
                ("晚餐", CategoryStyle(icon: "moon", color: "FFA726")),
                ("零食饮料", CategoryStyle(icon: "coffee", color: "A1887F")),
                ("水果", CategoryStyle(icon: "orangeSlice", color: "81C784"))
            ]
        ),
        // 2. 购物
        CategoryHierarchy(
            name: "购物",
            style: CategoryStyle(icon: "shoppingBag", color: "E57373"),
            children: [
                ("衣服鞋帽", CategoryStyle(icon: "tShirt", color: "E57373")),
                ("日用品", CategoryStyle(icon: "basket", color: "AED581")),
                ("美妆护肤", CategoryStyle(icon: "sparkle", color: "F48FB1")),
                ("电器数码", CategoryStyle(icon: "laptop", color: "78909C"))
            ]
        ),
        // 3. 交通出行
        CategoryHierarchy(
            name: "交通出行",
            style: CategoryStyle(icon: "car", color: "64B5F6"),
            children: [
                ("公共交通", CategoryStyle(icon: "bus", color: "64B5F6")),
                ("打车", CategoryStyle(icon: "taxi", color: "42A5F5")),
                ("汽车加油", CategoryStyle(icon: "gasPump", color: "90A4AE")),
                ("停车费", CategoryStyle(icon: "parking", color: "78909C"))
            ]
        ),
        // 4. 居家生活
        CategoryHierarchy(
            name: "居家生活",
            style: CategoryStyle(icon: "houseLine", color: "FFB74D"),
            children: [
                ("房租房贷", CategoryStyle(icon: "houseLine", color: "FFB74D")),
                ("水电燃气", CategoryStyle(icon: "lightning", color: "9FA8DA")),
                ("话费网费", CategoryStyle(icon: "phone", color: "4DD0E1")),
                ("物业费", CategoryStyle(icon: "buildings", color: "BCAAA4"))
            ]
        ),
        // 5. 娱乐休闲
        CategoryHierarchy(
            name: "娱乐休闲",
            style: CategoryStyle(icon: "gameController", color: "BA68C8"),
            children: [
                ("娱乐", CategoryStyle(icon: "gameController", color: "BA68C8")),
                ("运动健身", CategoryStyle(icon: "personSimpleRun", color: "4DB6AC")),
                ("旅行度假", CategoryStyle(icon: "airplaneTilt", color: "81C784"))
            ]
        ),
        // 6. 医疗健康
        CategoryHierarchy(
            name: "医疗健康",
            style: CategoryStyle(icon: "firstAidKit", color: "EF5350"),
            children: [
                ("看病挂号", CategoryStyle(icon: "firstAidKit", color: "EF5350")),
                ("买药", CategoryStyle(icon: "pill", color: "E57373")),
                ("保健品", CategoryStyle(icon: "leaf", color: "66BB6A"))
            ]
        ),
        // 7. 人情往来
        CategoryHierarchy(
            name: "人情往来",
            style: CategoryStyle(icon: "gift", color: "FF8A65"),
            children: [
                ("请客吃饭", CategoryStyle(icon: "forkKnife", color: "FF8A65")),
                ("送礼", CategoryStyle(icon: "gift", color: "FF7043")),
                ("红包礼金", CategoryStyle(icon: "envelopeSimple", color: "E57373"))
            ]
        ),
        // 8. 学习培训
        CategoryHierarchy(
            name: "学习培训",
            style: CategoryStyle(icon: "bookOpen", color: "4FC3F7"),
            children: [
                ("书籍资料", CategoryStyle(icon: "bookOpen", color: "4FC3F7")),
                ("课程培训", CategoryStyle(icon: "chalkboardTeacher", color: "29B6F6"))
            ]
        ),
        // 9. 其他
        CategoryHierarchy(
            name: "其他",
            style: CategoryStyle(icon: "dotsThreeCircle", color: "BDBDBD"),
            children: [
                ("孩子", CategoryStyle(icon: "baby", color: "FFD54F")),
                ("宠物", CategoryStyle(icon: "pawPrint", color: "9575CD")),
                ("烟酒", CategoryStyle(icon: "wine", color: "F06292")),
                ("其他支出", CategoryStyle(icon: "dotsThreeCircle", color: "BDBDBD"))
            ]
        )
    ]
    
    // MARK: - Income Categories (收入分类) - 父子结构
    
    /// 收入分类层级结构
    static let incomeHierarchy: [CategoryHierarchy] = [
        // 1. 工作收入
        CategoryHierarchy(
            name: "工作收入",
            style: CategoryStyle(icon: "briefcase", color: "4CAF50"),
            children: [
                ("工资", CategoryStyle(icon: "money", color: "4CAF50")),
                ("奖金", CategoryStyle(icon: "trophy", color: "66BB6A")),
                ("补贴", CategoryStyle(icon: "plusCircle", color: "81C784"))
            ]
        ),
        // 2. 投资理财
        CategoryHierarchy(
            name: "投资理财",
            style: CategoryStyle(icon: "trendUp", color: "26A69A"),
            children: [
                ("理财收益", CategoryStyle(icon: "trendUp", color: "26A69A")),
                ("股票基金", CategoryStyle(icon: "chartLineUp", color: "00897B"))
            ]
        ),
        // 3. 兼职副业
        CategoryHierarchy(
            name: "兼职副业",
            style: CategoryStyle(icon: "hammer", color: "81C784"),
            children: [
                ("兼职", CategoryStyle(icon: "briefcase", color: "81C784")),
                ("副业", CategoryStyle(icon: "hammer", color: "66BB6A"))
            ]
        ),
        // 4. 其他收入
        CategoryHierarchy(
            name: "其他收入",
            style: CategoryStyle(icon: "plusCircle", color: "AED581"),
            children: [
                ("报销", CategoryStyle(icon: "receipt", color: "AED581")),
                ("红包", CategoryStyle(icon: "envelopeSimple", color: "FF8A80")),
                ("其他", CategoryStyle(icon: "plusCircle", color: "BDBDBD"))
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
            icon: "question",
            color: "BDBDBD"
        )
    }
    
    /// 获取分类样式 (收入)
    static func incomeStyle(for categoryName: String) -> CategoryStyle {
        return incomeCategories[categoryName] ?? CategoryStyle(
            icon: "plusCircle",
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

// MARK: - PhosphorIcon Helper

/// 图标显示辅助（支持 Phosphor Icons 和 SF Symbols 后备）
enum PhosphorIcon {
    
    /// 图标权重
    enum IconWeight {
        case thin
        case light
        case regular
        case bold
        case fill
        case duotone
    }
    
    /// 将图标名称标准化为 Phosphor 名称
    /// 如果输入是旧的 SF Symbol 名称，会自动转换
    static func normalizeIconName(_ name: String) -> String {
        // 首先检查是否是旧的 SF Symbol 名称
        if let phosphorName = CategoryIconConfig.sfSymbolToPhosphor[name] {
            return phosphorName
        }
        // 否则认为已经是 Phosphor 名称
        return name
    }
    
    /// 根据名称获取图标视图
    @ViewBuilder
    static func icon(named name: String, weight: IconWeight = .fill) -> some View {
        // 标准化图标名称（支持旧的 SF Symbol 名称）
        let normalizedName = normalizeIconName(name)
        
        #if canImport(PhosphorSwift)
        // 使用 Phosphor Icons
        PhosphorIconInternal.icon(named: normalizedName, weight: weight)
        #else
        // 使用 SF Symbols 后备方案
        let sfSymbol = CategoryIconConfig.phosphorToSFSymbol[normalizedName] ?? "questionmark.circle"
        Image(systemName: sfSymbol)
            .resizable()
            .aspectRatio(contentMode: .fit)
        #endif
    }
}

// MARK: - Phosphor Icon Internal (仅在有 PhosphorSwift 时使用)

#if canImport(PhosphorSwift)
import PhosphorSwift

private enum PhosphorIconInternal {
    @ViewBuilder
    static func icon(named name: String, weight: PhosphorIcon.IconWeight) -> some View {
        let phWeight: Ph.IconWeight = {
            switch weight {
            case .thin: return .thin
            case .light: return .light
            case .regular: return .regular
            case .bold: return .bold
            case .fill: return .fill
            case .duotone: return .duotone
            }
        }()
        
        switch name {
        // Tab Bar Icons
        case "house": Ph.house.weight(phWeight)
        case "listDashes": Ph.listDashes.weight(phWeight)
        case "chartBar": Ph.chartBar.weight(phWeight)
        case "gear": Ph.gear.weight(phWeight)
        case "plus": Ph.plus.weight(phWeight)
            
        // 餐饮类
        case "forkKnife": Ph.forkKnife.weight(phWeight)
        case "sunHorizon": Ph.sunHorizon.weight(phWeight)
        case "sun": Ph.sun.weight(phWeight)
        case "moon": Ph.moon.weight(phWeight)
        case "coffee": Ph.coffee.weight(phWeight)
        case "orangeSlice": Ph.orangeSlice.weight(phWeight)
            
        // 购物类
        case "shoppingBag": Ph.shoppingBag.weight(phWeight)
        case "tShirt": Ph.tShirt.weight(phWeight)
        case "basket": Ph.basket.weight(phWeight)
        case "sparkle": Ph.sparkle.weight(phWeight)
        case "laptop": Ph.laptop.weight(phWeight)
            
        // 交通出行类
        case "car": Ph.car.weight(phWeight)
        case "bus": Ph.bus.weight(phWeight)
        case "taxi": Ph.taxi.weight(phWeight)
        case "gasPump": Ph.gasPump.weight(phWeight)
        case "parking": Ph.parking.weight(phWeight)
            
        // 居家生活类
        case "houseLine": Ph.houseLine.weight(phWeight)
        case "lightning": Ph.lightning.weight(phWeight)
        case "phone": Ph.phone.weight(phWeight)
        case "buildings": Ph.buildings.weight(phWeight)
            
        // 娱乐休闲类
        case "gameController": Ph.gameController.weight(phWeight)
        case "personSimpleRun": Ph.personSimpleRun.weight(phWeight)
        case "airplaneTilt": Ph.airplaneTilt.weight(phWeight)
            
        // 医疗健康类
        case "firstAidKit": Ph.firstAidKit.weight(phWeight)
        case "pill": Ph.pill.weight(phWeight)
        case "leaf": Ph.leaf.weight(phWeight)
            
        // 人情往来类
        case "gift": Ph.gift.weight(phWeight)
        case "envelopeSimple": Ph.envelopeSimple.weight(phWeight)
            
        // 学习培训类
        case "bookOpen": Ph.bookOpen.weight(phWeight)
        case "chalkboardTeacher": Ph.chalkboardTeacher.weight(phWeight)
            
        // 其他类
        case "baby": Ph.baby.weight(phWeight)
        case "pawPrint": Ph.pawPrint.weight(phWeight)
        case "wine": Ph.wine.weight(phWeight)
        case "dotsThreeCircle": Ph.dotsThreeCircle.weight(phWeight)
            
        // 收入类
        case "briefcase": Ph.briefcase.weight(phWeight)
        case "money": Ph.money.weight(phWeight)
        case "trophy": Ph.trophy.weight(phWeight)
        case "plusCircle": Ph.plusCircle.weight(phWeight)
        case "trendUp": Ph.trendUp.weight(phWeight)
        case "chartLineUp": Ph.chartLineUp.weight(phWeight)
        case "hammer": Ph.hammer.weight(phWeight)
        case "receipt": Ph.receipt.weight(phWeight)
            
        // 常用 UI 图标
        case "pencilSimple": Ph.pencilSimple.weight(phWeight)
        case "trash": Ph.trash.weight(phWeight)
        case "magnifyingGlass": Ph.magnifyingGlass.weight(phWeight)
        case "funnel": Ph.funnel.weight(phWeight)
        case "calendar": Ph.calendar.weight(phWeight)
        case "clock": Ph.clock.weight(phWeight)
        case "wallet": Ph.wallet.weight(phWeight)
        case "creditCard": Ph.creditCard.weight(phWeight)
        case "currencyCircleDollar": Ph.currencyCircleDollar.weight(phWeight)
        case "arrowUp": Ph.arrowUp.weight(phWeight)
        case "arrowDown": Ph.arrowDown.weight(phWeight)
        case "arrowsLeftRight": Ph.arrowsLeftRight.weight(phWeight)
        case "caretLeft": Ph.caretLeft.weight(phWeight)
        case "caretRight": Ph.caretRight.weight(phWeight)
        case "caretDown": Ph.caretDown.weight(phWeight)
        case "caretUp": Ph.caretUp.weight(phWeight)
        case "x": Ph.x.weight(phWeight)
        case "check": Ph.check.weight(phWeight)
        case "info": Ph.info.weight(phWeight)
        case "warning": Ph.warning.weight(phWeight)
        case "xCircle": Ph.xCircle.weight(phWeight)
        case "checkCircle": Ph.checkCircle.weight(phWeight)
        case "image": Ph.image.weight(phWeight)
        case "camera": Ph.camera.weight(phWeight)
        case "share": Ph.share.weight(phWeight)
        case "export": Ph.export.weight(phWeight)
        case "cloudArrowUp": Ph.cloudArrowUp.weight(phWeight)
        case "notebook": Ph.notebook.weight(phWeight)
        case "piggyBank": Ph.piggyBank.weight(phWeight)
        case "tag": Ph.tag.weight(phWeight)
        case "noteBlank": Ph.noteBlank.weight(phWeight)
        case "user": Ph.user.weight(phWeight)
        case "dotsThree": Ph.dotsThree.weight(phWeight)
        case "question": Ph.question.weight(phWeight)
            
        // 设置页面图标
        case "folder": Ph.folder.weight(phWeight)
        case "cloud": Ph.cloud.weight(phWeight)
        case "flask": Ph.flask.weight(phWeight)
        case "arrowCounterClockwise": Ph.arrowCounterClockwise.weight(phWeight)
            
        // 交易相关图标
        case "slidersHorizontal": Ph.slidersHorizontal.weight(phWeight)
        case "tray": Ph.tray.weight(phWeight)
            
        default:
            Ph.question.weight(phWeight)
        }
    }
}
#endif

// MARK: - Preview

#Preview("支出分类图标") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(CategoryIconConfig.expenseHierarchy, id: \.name) { hierarchy in
                VStack(alignment: .leading, spacing: 12) {
                    // 父分类
                    HStack(spacing: 12) {
                        PhosphorIcon.icon(named: hierarchy.style.iconName, weight: .fill)
                            .frame(width: 28, height: 28)
                            .foregroundStyle(hierarchy.style.colorValue)
                        
                        Text(hierarchy.name)
                            .font(.headline)
                    }
                    
                    // 子分类
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(hierarchy.children, id: \.name) { child in
                            VStack(spacing: 6) {
                                PhosphorIcon.icon(named: child.style.iconName, weight: .fill)
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(child.style.colorValue)
                                
                                Text(child.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.leading, 40)
                }
                
                Divider()
            }
        }
        .padding()
    }
}
