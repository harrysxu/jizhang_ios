# UI设计规范文档

## 文档信息

- **项目名称**: Lumina记账App
- **设计语言**: Minimal Elegant (极简优雅)
- **设计系统版本**: v1.0
- **创建日期**: 2026-01-24

---

## 1. 设计哲学

### 1.1 核心原则

**"Less is More, But Not Less Functional"**  
*简洁，但不简陋*

我们的设计理念是在保持专业功能完整性的同时，追求视觉上的极致简洁。每一个元素都经过深思熟虑，既要美观，更要实用。

#### 四大设计支柱

1. **清晰性 (Clarity)**
   - 信息层级分明
   - 关键数据突出显示
   - 避免视觉噪音

2. **一致性 (Consistency)**
   - 统一的交互模式
   - 可预测的用户体验
   - 遵循iOS平台规范

3. **效率性 (Efficiency)**
   - 减少操作步骤
   - 智能默认值
   - 快捷操作手势

4. **愉悦性 (Delight)**
   - 流畅的动画
   - 精致的细节
   - 触觉反馈

---

## 2. 色彩系统 (Color System)

### 2.1 主色调 (Primary Colors)

#### 品牌蓝 (Brand Blue)

```swift
// 主色调 - 用于主要按钮、强调元素
Color("PrimaryBlue")

// SwiftUI代码
extension Color {
    static let primaryBlue = Color(
        light: Color(hex: "007AFF"),  // iOS默认蓝
        dark: Color(hex: "0A84FF")     // iOS暗黑模式蓝
    )
}
```

**使用场景**:
- ✅ 主要CTA按钮
- ✅ 重要链接
- ✅ 选中状态
- ✅ 进度条（预算安全区）
- ❌ 不用于大面积背景

**色值表**:

| 模式 | Hex | RGB | 用途 |
|-----|-----|-----|------|
| Light Mode | #007AFF | rgb(0, 122, 255) | 主按钮、链接 |
| Dark Mode | #0A84FF | rgb(10, 132, 255) | 暗黑模式主色 |

### 2.2 功能色 (Semantic Colors)

#### 收入绿 (Income Green)

```swift
Color.incomeGreen

// 定义
static let incomeGreen = Color(
    light: Color(hex: "34C759"),  // iOS系统绿
    dark: Color(hex: "30D158")
)
```

**使用场景**: 收入金额、收入图标、收入趋势

#### 支出红 (Expense Red)

```swift
Color.expenseRed

// 定义
static let expenseRed = Color(
    light: Color(hex: "FF3B30"),  // iOS系统红
    dark: Color(hex: "FF453A")
)
```

**使用场景**: 支出金额、支出图标、超支警告

#### 警告橙 (Warning Orange)

```swift
Color.warningOrange

// 定义
static let warningOrange = Color(
    light: Color(hex: "FF9500"),
    dark: Color(hex: "FF9F0A")
)
```

**使用场景**: 预算预警（80-99%）、重要提示

#### 中性灰 (Neutral Gray)

```swift
// 六级灰度系统
Color.gray1  // 最深 - 主要文字
Color.gray2  // 次要文字
Color.gray3  // 辅助文字
Color.gray4  // 边框、分割线
Color.gray5  // 禁用状态
Color.gray6  // 背景 - 最浅

// 具体定义
extension Color {
    static let gray1 = Color(light: Color(hex: "000000"), dark: Color(hex: "FFFFFF"))
    static let gray2 = Color(.secondaryLabel)
    static let gray3 = Color(.tertiaryLabel)
    static let gray4 = Color(.separator)
    static let gray5 = Color(.quaternaryLabel)
    static let gray6 = Color(.systemGray6)
}
```

### 2.3 背景色系统 (Background System)

```swift
// 三层背景系统
Color.backgroundPrimary    // 主背景
Color.backgroundSecondary  // 卡片背景
Color.backgroundTertiary   // 分组背景

// SwiftUI代码
extension Color {
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    // 分组列表背景
    static let backgroundGrouped = Color(.systemGroupedBackground)
}
```

**层级关系**:

```
┌─────────────────────────────────┐
│ Primary (最底层)                │
│  ┌───────────────────────────┐  │
│  │ Secondary (卡片层)         │  │
│  │  ┌─────────────────────┐  │  │
│  │  │ Tertiary (内嵌元素) │  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### 2.4 色彩使用规则

#### 对比度要求

| 元素类型 | 最小对比度 | 推荐对比度 |
|---------|-----------|-----------|
| 大文字 (≥18pt) | 3:1 | 4.5:1 |
| 小文字 (<18pt) | 4.5:1 | 7:1 |
| 图标、按钮 | 3:1 | 4.5:1 |

#### 颜色组合示例

```swift
// ✅ 良好组合
Text("¥123.45")
    .foregroundColor(.primary)
    .background(Color.backgroundPrimary)

// ✅ 金额颜色
Text("-¥100")
    .foregroundColor(.expenseRed)

Text("+¥500")
    .foregroundColor(.incomeGreen)

// ❌ 避免使用
Text("重要信息")
    .foregroundColor(.red)  // 不要直接用系统色
    .background(.green)      // 对比度不足
```

---

## 3. 字体系统 (Typography)

### 3.1 字体家族

**系统字体**: San Francisco (SF Pro / SF Compact)

- **SF Pro Text**: 用于正文（< 20pt）
- **SF Pro Display**: 用于标题（≥ 20pt）
- **SF Mono**: 用于数字金额、代码

### 3.2 字体等级 (Type Scale)

#### 标题层级

```swift
// 大标题 (Large Title)
Text("首页")
    .font(.largeTitle)      // 34pt, Bold
    .fontWeight(.bold)

// 标题1 (Title 1)
Text("净资产")
    .font(.title)           // 28pt, Bold
    .fontWeight(.bold)

// 标题2 (Title 2)
Text("本月支出")
    .font(.title2)          // 22pt, Bold
    .fontWeight(.bold)

// 标题3 (Title 3)
Text("分类分析")
    .font(.title3)          // 20pt, Semibold
    .fontWeight(.semibold)
```

#### 正文层级

```swift
// 标准正文 (Body)
Text("这是一段描述文字")
    .font(.body)            // 17pt, Regular

// 标注 (Callout)
Text("次要信息")
    .font(.callout)         // 16pt, Regular

// 副标题 (Subheadline)
Text("辅助说明")
    .font(.subheadline)     // 15pt, Regular

// 脚注 (Footnote)
Text("提示信息")
    .font(.footnote)        // 13pt, Regular

// 说明文字 (Caption)
Text("2小时前")
    .font(.caption)         // 12pt, Regular

// 极小文字 (Caption 2)
Text("详细说明")
    .font(.caption2)        // 11pt, Regular
```

#### 金额专用字体

```swift
// 大额金额 (主屏幕)
Text("¥123,456.78")
    .font(.system(size: 48, weight: .bold, design: .rounded))
    .monospacedDigit()

// 中等金额 (卡片)
Text("¥12,345")
    .font(.system(size: 28, weight: .semibold, design: .rounded))
    .monospacedDigit()

// 小金额 (列表)
Text("¥123.45")
    .font(.system(size: 17, weight: .medium, design: .default))
    .monospacedDigit()

// 金额格式化工具
extension Decimal {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self as NSNumber) ?? "¥0"
    }
}
```

### 3.3 字体使用规则

#### 行高与间距

```swift
// 标题行高
.lineSpacing(4)  // 标题：字号 × 1.2

// 正文行高
.lineSpacing(8)  // 正文：字号 × 1.5

// 段落间距
.padding(.vertical, 16)
```

#### 字重选择指南

| 场景 | 字重 | 示例 |
|-----|------|------|
| 大标题 | Bold (700) | 页面标题 |
| 小标题 | Semibold (600) | 卡片标题 |
| 金额 | Medium/Semibold | ¥123.45 |
| 正文 | Regular (400) | 描述文字 |
| 辅助 | Regular (400) | 说明文字 |

---

## 4. 间距系统 (Spacing System)

### 4.1 标准间距单位

采用**8点网格系统** (8pt Grid System)

```swift
enum Spacing {
    static let xxs: CGFloat = 2    // 极小间距
    static let xs: CGFloat = 4     // 超小间距
    static let s: CGFloat = 8      // 小间距
    static let m: CGFloat = 16     // 标准间距 ⭐
    static let l: CGFloat = 24     // 大间距
    static let xl: CGFloat = 32    // 超大间距
    static let xxl: CGFloat = 48   // 极大间距
    static let xxxl: CGFloat = 64  // 特大间距
}

// 使用示例
VStack(spacing: Spacing.m) {
    Text("标题")
    Text("内容")
}
.padding(Spacing.l)
```

### 4.2 组件内间距规范

#### 按钮内边距

```swift
// 大按钮 (Primary Button)
.padding(.horizontal, Spacing.xl)   // 32pt
.padding(.vertical, Spacing.m)      // 16pt
.frame(height: 56)

// 中按钮 (Secondary Button)
.padding(.horizontal, Spacing.l)    // 24pt
.padding(.vertical, Spacing.s)      // 8pt
.frame(height: 44)

// 小按钮 (Tertiary Button)
.padding(.horizontal, Spacing.m)    // 16pt
.padding(.vertical, Spacing.xs)     // 4pt
.frame(height: 32)
```

#### 卡片内边距

```swift
// 标准卡片
CardView {
    content
}
.padding(Spacing.m)  // 16pt 内边距

// 大卡片
CardView {
    content
}
.padding(Spacing.l)  // 24pt 内边距
```

#### 列表项间距

```swift
// 列表项高度
.frame(height: 60)  // 标准行高

// 列表项内边距
.padding(.horizontal, Spacing.m)
.padding(.vertical, Spacing.s)

// 分组间距
.listRowSpacing(Spacing.s)
```

### 4.3 页面布局间距

```swift
// 页面顶部安全区
.padding(.top, Spacing.l)

// 页面左右边距
.padding(.horizontal, Spacing.m)

// 底部导航栏上方间距
.padding(.bottom, Spacing.xxl)

// 分组标题与内容间距
.padding(.bottom, Spacing.s)
```

---

## 5. 圆角系统 (Corner Radius)

### 5.1 圆角规范

```swift
enum CornerRadius {
    static let xs: CGFloat = 4      // 标签
    static let s: CGFloat = 8       // 小元素
    static let m: CGFloat = 12      // 按钮、小卡片 ⭐
    static let l: CGFloat = 16      // 大卡片 ⭐
    static let xl: CGFloat = 20     // 模态框顶部
    static let xxl: CGFloat = 24    // 特殊元素
    static let full: CGFloat = 9999 // 圆形
}

// 使用示例
RoundedRectangle(cornerRadius: CornerRadius.m)
    .fill(Color.backgroundSecondary)
```

### 5.2 圆角使用场景

| 元素类型 | 圆角值 | 示例 |
|---------|--------|------|
| 图标容器 | 8pt | 分类图标背景 |
| 按钮 | 12pt | 主按钮、次要按钮 |
| 输入框 | 10pt | 文本输入框 |
| 小卡片 | 12pt | 预算卡片 |
| 大卡片 | 16pt | 净资产卡片 |
| Sheet顶部 | 20pt | 模态框 |
| 头像 | full | 圆形头像 |
| 标签 | 4pt | Tag标签 |

---

## 6. 阴影系统 (Shadow System)

### 6.1 阴影层级

```swift
enum ShadowStyle {
    // 一级阴影 - 悬浮元素
    static let level1 = ShadowConfig(
        color: .black.opacity(0.05),
        radius: 4,
        x: 0,
        y: 2
    )
    
    // 二级阴影 - 卡片
    static let level2 = ShadowConfig(
        color: .black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
    )
    
    // 三级阴影 - 模态框
    static let level3 = ShadowConfig(
        color: .black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 8
    )
    
    // 四级阴影 - 浮动按钮
    static let level4 = ShadowConfig(
        color: .black.opacity(0.16),
        radius: 24,
        x: 0,
        y: 12
    )
}

struct ShadowConfig {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// 使用示例
extension View {
    func cardShadow() -> some View {
        self.shadow(
            color: ShadowStyle.level2.color,
            radius: ShadowStyle.level2.radius,
            x: ShadowStyle.level2.x,
            y: ShadowStyle.level2.y
        )
    }
}
```

### 6.2 阴影使用规则

- ✅ Light Mode: 使用黑色阴影，透明度5-16%
- ✅ Dark Mode: 使用更浅的阴影或不使用
- ❌ 避免彩色阴影
- ❌ 避免过大的模糊半径

---

## 7. 图标系统 (Icon System)

### 7.1 图标来源

**SF Symbols 5.0**

- 5000+ 高质量图标
- 自动适配字体大小
- 支持多色渲染
- 自动适配Dark Mode

### 7.2 图标尺寸规范

```swift
enum IconSize {
    case small      // 16×16 - 列表辅助图标
    case medium     // 24×24 - 标准图标 ⭐
    case large      // 32×32 - 卡片图标
    case xlarge     // 48×48 - 空状态图标
    case xxlarge    // 64×64 - 功能入口图标
}

// 使用示例
Image(systemName: "fork.knife")
    .font(.system(size: 24))
    .foregroundColor(.primary)
```

### 7.3 分类图标推荐

#### 支出分类

```swift
let expenseCategoryIcons: [String: String] = [
    "餐饮": "fork.knife",
    "交通": "car.fill",
    "购物": "cart.fill",
    "居住": "house.fill",
    "娱乐": "gamecontroller.fill",
    "医疗": "cross.case.fill",
    "教育": "book.fill",
    "通讯": "phone.fill",
    "服饰": "tshirt.fill",
    "美容": "face.smiling",
    "运动": "figure.run",
    "宠物": "pawprint.fill",
    "礼物": "gift.fill",
    "捐赠": "heart.fill"
]
```

#### 收入分类

```swift
let incomeCategoryIcons: [String: String] = [
    "工资": "banknote.fill",
    "奖金": "star.fill",
    "投资": "chart.line.uptrend.xyaxis",
    "兼职": "briefcase.fill",
    "礼金": "envelope.fill",
    "报销": "doc.text.fill"
]
```

#### 账户类型图标

```swift
let accountTypeIcons: [String: String] = [
    "现金": "banknote.fill",
    "储蓄卡": "creditcard.fill",
    "信用卡": "creditcard.circle.fill",
    "支付宝": "ant.fill",  // 或 "a.circle.fill"
    "微信": "message.fill",
    "投资账户": "chart.pie.fill",
    "公积金": "building.columns.fill"
]
```

### 7.4 图标渲染模式

```swift
// 单色渲染 (默认)
Image(systemName: "heart")
    .foregroundColor(.red)

// 多色渲染
Image(systemName: "heart.fill")
    .symbolRenderingMode(.multicolor)

// 分层渲染
Image(systemName: "square.stack.3d.up")
    .symbolRenderingMode(.hierarchical)
    .foregroundColor(.blue)

// 调色板渲染
Image(systemName: "person.crop.circle.badge.checkmark")
    .symbolRenderingMode(.palette)
    .foregroundStyle(.blue, .green)
```

---

## 8. 通用组件库

### 8.1 按钮组件 (Buttons)

#### 主按钮 (Primary Button)

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.m)
                        .fill(isEnabled ? Color.primaryBlue : Color.gray5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// 使用
PrimaryButton(title: "确认添加") {
    // 操作
}
```

#### 次要按钮 (Secondary Button)

```swift
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primaryBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.m)
                        .stroke(Color.primaryBlue, lineWidth: 1.5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
```

#### 浮动操作按钮 (FAB)

```swift
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.primaryBlue)
                        .shadow(
                            color: .black.opacity(0.16),
                            radius: 24,
                            x: 0,
                            y: 12
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.9))
    }
}
```

#### 按钮样式

```swift
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}
```

### 8.2 卡片组件 (Cards)

```swift
struct CardView<Content: View>: View {
    let content: Content
    var shadow: Bool = true
    
    init(shadow: Bool = true, @ViewBuilder content: () -> Content) {
        self.shadow = shadow
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.l)
                    .fill(Color.backgroundSecondary)
                    .shadow(
                        color: shadow ? Color.black.opacity(0.08) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// 使用
CardView {
    VStack(alignment: .leading, spacing: Spacing.m) {
        Text("卡片标题")
            .font(.title3)
            .fontWeight(.semibold)
        
        Text("卡片内容")
            .font(.body)
            .foregroundColor(.gray2)
    }
    .padding(Spacing.l)
}
```

### 8.3 输入框组件 (Text Fields)

```swift
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray2)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .font(.body)
                .padding(Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.backgroundTertiary)
                )
        }
    }
}
```

### 8.4 进度条组件 (Progress Bars)

```swift
struct BudgetProgressBar: View {
    let progress: Double  // 0.0 - 1.0
    var height: CGFloat = 8
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .expenseRed
        } else if progress >= 0.9 {
            return .warningOrange
        } else if progress >= 0.8 {
            return .warningOrange
        } else {
            return .incomeGreen
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray6)
                
                // 进度
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * min(progress, 1.0))
                    .animation(.spring(response: 0.6), value: progress)
            }
        }
        .frame(height: height)
    }
}
```

### 8.5 标签组件 (Tags)

```swift
struct TagView: View {
    let text: String
    var color: Color = .primaryBlue
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(color.opacity(0.15))
            )
    }
}
```

---

## 9. 动画规范 (Animation)

### 9.1 动画时长

```swift
enum AnimationDuration {
    static let instant: Double = 0.15      // 瞬时反馈
    static let quick: Double = 0.25        // 快速动画 ⭐
    static let normal: Double = 0.35       // 标准动画 ⭐
    static let slow: Double = 0.5          // 慢速动画
    static let verySlow: Double = 0.7      // 特殊效果
}
```

### 9.2 缓动函数 (Easing)

```swift
extension Animation {
    // 弹簧动画 (推荐用于大多数场景)
    static let spring = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7
    )
    
    // 平滑进入
    static let easeIn = Animation.easeIn(duration: AnimationDuration.quick)
    
    // 平滑退出
    static let easeOut = Animation.easeOut(duration: AnimationDuration.quick)
    
    // 平滑进出
    static let easeInOut = Animation.easeInOut(duration: AnimationDuration.normal)
}
```

### 9.3 常用动画效果

#### 淡入淡出

```swift
.opacity(isVisible ? 1 : 0)
.animation(.easeInOut, value: isVisible)
```

#### 滑入滑出

```swift
.offset(y: isPresented ? 0 : UIScreen.main.bounds.height)
.animation(.spring, value: isPresented)
```

#### 缩放

```swift
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.spring, value: isPressed)
```

#### 数字滚动

```swift
struct AnimatedNumber: View {
    let value: Decimal
    @State private var displayValue: Decimal = 0
    
    var body: some View {
        Text(displayValue.formatted())
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .monospacedDigit()
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.easeOut(duration: 0.8)) {
                    displayValue = newValue
                }
            }
    }
}
```

---

## 10. 触觉反馈 (Haptic Feedback)

### 10.1 反馈类型

```swift
import UIKit

enum HapticFeedback {
    case light          // 轻触
    case medium         // 中等
    case heavy          // 重击
    case success        // 成功
    case warning        // 警告
    case error          // 错误
    case selection      // 选择
    
    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
```

### 10.2 使用场景

| 场景 | 反馈类型 | 说明 |
|-----|---------|------|
| 点击按钮 | light | 轻微反馈 |
| 添加交易成功 | success | 操作成功 |
| 删除交易 | medium | 重要操作 |
| 超支警告 | warning | 警告提示 |
| 操作失败 | error | 错误提示 |
| 切换标签 | selection | 选择变更 |
| 长按弹出菜单 | medium | 重要交互 |

---

## 11. 深色模式 (Dark Mode)

### 11.1 自动适配策略

所有颜色使用**语义化颜色**，自动适配Dark Mode：

```swift
// ✅ 推荐：使用语义化颜色
.foregroundColor(.primary)        // 自动适配
.background(Color.backgroundPrimary)

// ❌ 避免：硬编码颜色
.foregroundColor(Color(hex: "000000"))  // 不会适配
```

### 11.2 Dark Mode专属调整

某些元素需要针对Dark Mode特殊处理：

```swift
@Environment(\.colorScheme) var colorScheme

var shadowOpacity: Double {
    colorScheme == .dark ? 0.3 : 0.08
}

// 阴影在Dark Mode下更明显
.shadow(color: .black.opacity(shadowOpacity), radius: 8)
```

---

## 12. 响应式设计

### 12.1 屏幕尺寸适配

```swift
enum DeviceSize {
    case compact    // iPhone SE, Mini
    case regular    // iPhone 标准
    case large      // iPhone Plus, Pro Max
    case iPad       // iPad
}

extension View {
    var deviceSize: DeviceSize {
        let width = UIScreen.main.bounds.width
        if width < 375 {
            return .compact
        } else if width < 414 {
            return .regular
        } else if width < 768 {
            return .large
        } else {
            return .iPad
        }
    }
}

// 根据屏幕调整字体
var titleFontSize: CGFloat {
    switch deviceSize {
    case .compact: return 24
    case .regular: return 28
    case .large, .iPad: return 32
    }
}
```

### 12.2 横屏适配

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass
@Environment(\.verticalSizeClass) var verticalSizeClass

var isLandscape: Bool {
    verticalSizeClass == .compact
}

// 横屏时调整布局
if isLandscape {
    HStack { /* 横向布局 */ }
} else {
    VStack { /* 纵向布局 */ }
}
```

---

## 13. 无障碍设计 (Accessibility)

### 13.1 Dynamic Type支持

```swift
// 自动支持用户字体大小设置
Text("标题")
    .font(.title)  // 会随用户设置缩放

// 限制最大字体（避免布局崩溃）
.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

### 13.2 VoiceOver支持

```swift
Image(systemName: "trash")
    .accessibilityLabel("删除")
    .accessibilityHint("删除此交易记录")

Button("添加") { }
    .accessibilityIdentifier("addTransactionButton")
```

### 13.3 颜色对比度

确保所有文字与背景对比度符合WCAG AA标准（4.5:1）

---

## 14. 设计资源

### 14.1 Figma设计文件

*（留空，后续补充设计稿链接）*

### 14.2 色板导出

```swift
// 可导出的色板文件
// Assets.xcassets/Colors/

PrimaryBlue.colorset
IncomeGreen.colorset
ExpenseRed.colorset
WarningOrange.colorset
```

### 14.3 组件库

所有组件保存在 `Views/Components/` 目录，可直接复用。

---

## 附录：快速参考

### 常用颜色

```swift
.primaryBlue         // 主色调
.incomeGreen         // 收入
.expenseRed          // 支出
.warningOrange       // 警告
.backgroundPrimary   // 主背景
```

### 常用间距

```swift
Spacing.xs   // 4pt
Spacing.s    // 8pt
Spacing.m    // 16pt ⭐
Spacing.l    // 24pt ⭐
Spacing.xl   // 32pt
```

### 常用圆角

```swift
CornerRadius.m   // 12pt - 按钮
CornerRadius.l   // 16pt - 卡片
```

### 常用字体

```swift
.font(.largeTitle)   // 34pt
.font(.title)        // 28pt
.font(.body)         // 17pt ⭐
.font(.caption)      // 12pt
```

---

**文档维护**: 随设计系统演进持续更新  
**最后更新**: 2026-01-24
