# Widget与Live Activities开发指南

## 文档信息

- **项目名称**: Lumina记账App
- **Widget框架**: WidgetKit + ActivityKit
- **版本**: v1.0
- **创建日期**: 2026-01-24

---

## 目录

1. [Widget概述](#1-widget概述)
2. [Widget家族设计](#2-widget家族设计)
3. [TimelineProvider实现](#3-timelineprovider实现)
4. [交互式Widget](#4-交互式widget)
5. [Live Activities设计](#5-live-activities设计)
6. [数据共享策略](#6-数据共享策略)
7. [性能优化](#7-性能优化)
8. [测试与调试](#8-测试与调试)

---

## 1. Widget概述

### 1.1 Widget类型

Lumina提供**三种尺寸**的Widget，分别适应不同的用户需求：

| 尺寸 | 尺寸代码 | 用途 | 更新频率 |
|-----|---------|------|---------|
| **Small** | `systemSmall` | 今日支出/预算进度 | 每30分钟 |
| **Medium** | `systemMedium` | 今日支出+最近流水 | 每30分钟 |
| **Large** | `systemLarge` | 本月支出+流水列表+快捷按钮 | 每30分钟 |

### 1.2 技术栈

```swift
import WidgetKit
import SwiftUI
import SwiftData
import AppIntents  // iOS 17+ 交互式Widget
```

---

## 2. Widget家族设计

### 2.1 项目结构

```
jizhangWidget/                    # Widget扩展Target
├── jizhangWidget.swift           # Widget主入口
├── jizhangWidgetBundle.swift    # Widget Bundle
├── Providers/
│   ├── TodayExpenseProvider.swift       # 今日支出Timeline
│   └── BudgetProgressProvider.swift     # 预算进度Timeline
├── Views/
│   ├── SmallWidgetView.swift     # 小号Widget视图
│   ├── MediumWidgetView.swift    # 中号Widget视图
│   └── LargeWidgetView.swift     # 大号Widget视图
├── Models/
│   └── WidgetData.swift          # Widget数据模型
├── Intents/
│   └── AddTransactionIntent.swift # 快捷记账Intent
└── Assets.xcassets/              # Widget资源
```

### 2.2 Widget Bundle入口

```swift
// jizhangWidgetBundle.swift
import WidgetKit
import SwiftUI

@main
struct jizhangWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 今日支出Widget
        TodayExpenseWidget()
        
        // 预算进度Widget
        BudgetProgressWidget()
        
        // 快速记账Widget（大号专用）
        QuickAddWidget()
    }
}
```

---

## 3. TimelineProvider实现

### 3.1 数据模型

```swift
// WidgetData.swift
import Foundation

struct WidgetData: Codable {
    let todayExpense: Decimal
    let todayBudget: Decimal
    let budgetUsagePercentage: Double
    let recentTransactions: [SimpleTransaction]
    let lastUpdateTime: Date
}

struct SimpleTransaction: Codable, Identifiable {
    let id: UUID
    let amount: Decimal
    let categoryName: String
    let categoryIcon: String
    let date: Date
    let type: String  // "expense" or "income"
}
```

### 3.2 TimelineProvider核心逻辑

```swift
// TodayExpenseProvider.swift
import WidgetKit
import SwiftUI
import SwiftData

struct TodayExpenseEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct TodayExpenseProvider: TimelineProvider {
    typealias Entry = TodayExpenseEntry
    
    // MARK: - Timeline Provider Methods
    
    /// Placeholder：Widget首次加载时显示
    func placeholder(in context: Context) -> TodayExpenseEntry {
        TodayExpenseEntry(
            date: Date(),
            data: WidgetData(
                todayExpense: 256.00,
                todayBudget: 200.00,
                budgetUsagePercentage: 0.65,
                recentTransactions: [
                    SimpleTransaction(
                        id: UUID(),
                        amount: 45,
                        categoryName: "午餐",
                        categoryIcon: "fork.knife",
                        date: Date(),
                        type: "expense"
                    )
                ],
                lastUpdateTime: Date()
            )
        )
    }
    
    /// Snapshot：Widget Gallery预览
    func getSnapshot(in context: Context, completion: @escaping (TodayExpenseEntry) -> Void) {
        if context.isPreview {
            // Gallery预览使用假数据
            completion(placeholder(in: context))
        } else {
            // 真实快照
            Task {
                let entry = await fetchData()
                completion(entry)
            }
        }
    }
    
    /// Timeline：定时刷新策略
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayExpenseEntry>) -> Void) {
        Task {
            let entry = await fetchData()
            
            // 下次刷新时间：30分钟后
            let nextUpdateDate = Calendar.current.date(
                byAdding: .minute,
                value: 30,
                to: Date()
            )!
            
            let timeline = Timeline(
                entries: [entry],
                policy: .after(nextUpdateDate)
            )
            
            completion(timeline)
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchData() async -> TodayExpenseEntry {
        do {
            let widgetData = try await WidgetDataService.shared.fetchTodayData()
            return TodayExpenseEntry(date: Date(), data: widgetData)
        } catch {
            print("Widget数据获取失败: \(error)")
            return placeholder(in: Context())
        }
    }
}
```

### 3.3 数据服务

```swift
// WidgetDataService.swift
import Foundation
import SwiftData

actor WidgetDataService {
    static let shared = WidgetDataService()
    
    private let modelContainer: ModelContainer
    
    private init() {
        // 使用App Group共享的数据容器
        let schema = Schema([
            Ledger.self,
            Account.self,
            Category.self,
            Transaction.self,
            Budget.self
        ])
        
        let appGroupIdentifier = "group.com.yourcompany.jizhang"
        let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )!
        
        let config = ModelConfiguration(
            url: url.appendingPathComponent("Lumina.sqlite")
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("无法创建ModelContainer: \(error)")
        }
    }
    
    func fetchTodayData() async throws -> WidgetData {
        let context = modelContainer.mainContext
        
        // 1. 获取当前账本
        guard let currentLedger = try await getCurrentLedger(context: context) else {
            throw WidgetError.noLedger
        }
        
        // 2. 获取今日交易
        let todayTransactions = try await getTodayTransactions(
            ledger: currentLedger,
            context: context
        )
        
        // 3. 计算今日支出
        let todayExpense = todayTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        // 4. 获取预算信息
        let budget = try await getTotalBudget(ledger: currentLedger, context: context)
        let budgetUsage = budget > 0 ? Double(truncating: (todayExpense / budget) as NSNumber) : 0
        
        // 5. 转换为简化模型
        let simpleTransactions = todayTransactions.prefix(5).map { transaction in
            SimpleTransaction(
                id: transaction.id,
                amount: transaction.amount,
                categoryName: transaction.category?.name ?? "未分类",
                categoryIcon: transaction.category?.iconName ?? "questionmark",
                date: transaction.date,
                type: transaction.type.rawValue
            )
        }
        
        return WidgetData(
            todayExpense: todayExpense,
            todayBudget: budget,
            budgetUsagePercentage: budgetUsage,
            recentTransactions: simpleTransactions,
            lastUpdateTime: Date()
        )
    }
    
    private func getCurrentLedger(context: ModelContext) async throws -> Ledger? {
        // 从UserDefaults获取当前账本ID
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.jizhang")
        guard let ledgerIdString = sharedDefaults?.string(forKey: "currentLedgerId"),
              let ledgerId = UUID(uuidString: ledgerIdString) else {
            return nil
        }
        
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.id == ledgerId }
        )
        
        return try context.fetch(descriptor).first
    }
    
    private func getTodayTransactions(ledger: Ledger, context: ModelContext) async throws -> [Transaction] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.ledger == ledger &&
                transaction.date >= today &&
                transaction.date < tomorrow
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    private func getTotalBudget(ledger: Ledger, context: ModelContext) async throws -> Decimal {
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.ledger == ledger && $0.isEnabled }
        )
        
        let budgets = try context.fetch(descriptor)
        return budgets.reduce(0) { $0 + $1.effectiveBudget }
    }
}

enum WidgetError: Error {
    case noLedger
    case dataCorrupted
}
```

---

## 4. 交互式Widget

### 4.1 交互按钮设计（iOS 17+）

```swift
// AddTransactionIntent.swift
import AppIntents
import SwiftUI

struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "快速记账"
    static var description: IntentDescription = "打开App并开始记账"
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // 打开App到记账页面
        // 使用URL Scheme
        if let url = URL(string: "jizhang://add-transaction") {
            await openURL(url)
        }
        
        return .result()
    }
    
    private func openURL(_ url: URL) async {
        guard let scene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = await scene.windows.first else {
            return
        }
        
        await UIApplication.shared.open(url)
    }
}
```

### 4.2 Large Widget with Button

```swift
// LargeWidgetView.swift
import SwiftUI
import WidgetKit
import AppIntents

struct LargeWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部标题栏
            HStack {
                Text("Lumina")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("本月支出")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 预算卡片
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.todayExpense.formatted())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .monospacedDigit()
                    
                    Text("今日支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(data.budgetUsagePercentage * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(budgetColor)
                    
                    Text("预算使用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )
            
            Divider()
            
            // 最近流水
            Text("最近流水")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(data.recentTransactions.prefix(3)) { transaction in
                HStack {
                    Image(systemName: transaction.categoryIcon)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(transaction.categoryName)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(transaction.amount.formatted())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(transaction.type == "expense" ? .red : .green)
                        .monospacedDigit()
                }
            }
            
            Spacer()
            
            // 交互按钮（iOS 17+）
            Button(intent: AddTransactionIntent()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("快速记账")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var budgetColor: Color {
        if data.budgetUsagePercentage >= 1.0 {
            return .red
        } else if data.budgetUsagePercentage >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
}
```

---

## 5. Live Activities设计

### 5.1 使用场景

Live Activities适用于**需要实时跟踪的短期活动**：

1. **购物模式**：超市购物时实时显示累计支出
2. **旅行模式**：旅行期间跟踪旅行总花费
3. **预算倒计时**：距离月底还剩多少预算

### 5.2 ActivityAttributes定义

```swift
// LiveActivityAttributes.swift
import Foundation
import ActivityKit

struct ShoppingModeAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var totalSpent: Decimal
        var itemCount: Int
        var lastUpdate: Date
    }
    
    // 不变的属性
    var budgetLimit: Decimal
    var startTime: Date
}
```

### 5.3 开启Live Activity

```swift
// LiveActivityService.swift
import ActivityKit
import Foundation

@MainActor
class LiveActivityService {
    static let shared = LiveActivityService()
    
    private var currentActivity: Activity<ShoppingModeAttributes>?
    
    /// 开启购物模式
    func startShoppingMode(budgetLimit: Decimal) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities未授权")
            return
        }
        
        let attributes = ShoppingModeAttributes(
            budgetLimit: budgetLimit,
            startTime: Date()
        )
        
        let initialState = ShoppingModeAttributes.ContentState(
            totalSpent: 0,
            itemCount: 0,
            lastUpdate: Date()
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("Live Activity已启动: \(currentActivity?.id ?? "")")
        } catch {
            print("启动Live Activity失败: \(error)")
        }
    }
    
    /// 更新购物金额
    func updateSpent(amount: Decimal) async {
        guard let activity = currentActivity else { return }
        
        var updatedState = activity.content.state
        updatedState.totalSpent += amount
        updatedState.itemCount += 1
        updatedState.lastUpdate = Date()
        
        await activity.update(
            .init(state: updatedState, staleDate: nil)
        )
    }
    
    /// 结束购物模式
    func endShoppingMode() async {
        guard let activity = currentActivity else { return }
        
        let finalState = activity.content.state
        
        await activity.end(
            .init(state: finalState, staleDate: nil),
            dismissalPolicy: .default
        )
        
        currentActivity = nil
    }
}
```

### 5.4 Live Activity视图

```swift
// ShoppingModeLiveActivity.swift
import WidgetKit
import SwiftUI
import ActivityKit

struct ShoppingModeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShoppingModeAttributes.self) { context in
            // 锁屏显示
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // 灵动岛显示
            DynamicIsland {
                // 展开态
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "cart.fill")
                            .foregroundColor(.blue)
                        Text("购物中")
                            .font(.caption)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.totalSpent.formatted())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.3))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(progressColor(context: context))
                                    .frame(width: geometry.size.width * progress(context: context))
                            }
                        }
                        .frame(height: 8)
                        
                        HStack {
                            Text("已花费 \(context.state.itemCount) 笔")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            let remaining = context.attributes.budgetLimit - context.state.totalSpent
                            Text("剩余 \(remaining.formatted())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } compactLeading: {
                // 紧凑态 - 左侧
                Image(systemName: "cart.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // 紧凑态 - 右侧
                Text(context.state.totalSpent.formatted())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            } minimal: {
                // 最小态
                Image(systemName: "cart.badge.plus")
            }
        }
    }
    
    private func progress(context: ActivityViewContext<ShoppingModeAttributes>) -> CGFloat {
        let spent = context.state.totalSpent
        let budget = context.attributes.budgetLimit
        guard budget > 0 else { return 0 }
        return min(CGFloat(truncating: (spent / budget) as NSNumber), 1.0)
    }
    
    private func progressColor(context: ActivityViewContext<ShoppingModeAttributes>) -> Color {
        let progress = progress(context: context)
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<ShoppingModeAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(.blue)
                
                Text("购物模式进行中")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("累计支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(context.state.totalSpent.formatted())
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("预算剩余")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let remaining = context.attributes.budgetLimit - context.state.totalSpent
                    Text(remaining.formatted())
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(remaining > 0 ? .green : .red)
                }
            }
        }
        .padding()
    }
}
```

---

## 6. 数据共享策略

### 6.1 App Group配置

#### 1. 创建App Group

在Xcode中：
1. 主App Target → Signing & Capabilities → + Capability → App Groups
2. 添加：`group.com.yourcompany.jizhang`
3. Widget Extension Target也添加同样的App Group

#### 2. 共享SwiftData容器

```swift
// AppState.swift (主App)
import SwiftData

@MainActor
class AppState: ObservableObject {
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([/* 模型列表 */])
        
        // 使用App Group路径
        let appGroupIdentifier = "group.com.yourcompany.jizhang"
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )!
        
        let config = ModelConfiguration(
            url: containerURL.appendingPathComponent("Lumina.sqlite"),
            cloudKitDatabase: .automatic
        )
        
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
    }
}
```

### 6.2 UserDefaults共享

```swift
// SharedUserDefaults.swift
import Foundation

class SharedUserDefaults {
    static let shared = SharedUserDefaults()
    
    private let defaults = UserDefaults(suiteName: "group.com.yourcompany.jizhang")!
    
    // 当前账本ID
    var currentLedgerId: UUID? {
        get {
            guard let string = defaults.string(forKey: "currentLedgerId") else { return nil }
            return UUID(uuidString: string)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: "currentLedgerId")
        }
    }
    
    // Widget最后更新时间
    var lastWidgetUpdate: Date? {
        get { defaults.object(forKey: "lastWidgetUpdate") as? Date }
        set { defaults.set(newValue, forKey: "lastWidgetUpdate") }
    }
}
```

### 6.3 刷新Widget

```swift
// 在主App中，交易创建后刷新Widget
extension NotificationCenter {
    static let transactionCreated = Notification.Name("transactionCreated")
}

// 监听通知并刷新
class WidgetUpdateService {
    static let shared = WidgetUpdateService()
    
    func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshWidgets),
            name: .transactionCreated,
            object: nil
        )
    }
    
    @objc private func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

---

## 7. 性能优化

### 7.1 数据缓存

```swift
// WidgetCache.swift
import Foundation

class WidgetCache {
    static let shared = WidgetCache()
    
    private let cacheURL: URL = {
        let appGroup = "group.com.yourcompany.jizhang"
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )!
        return containerURL.appendingPathComponent("WidgetCache.json")
    }()
    
    func save(_ data: WidgetData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: cacheURL)
        } catch {
            print("缓存保存失败: \(error)")
        }
    }
    
    func load() -> WidgetData? {
        do {
            let data = try Data(contentsOf: cacheURL)
            return try JSONDecoder().decode(WidgetData.self, from: data)
        } catch {
            return nil
        }
    }
}

// 使用缓存加速Widget加载
extension TodayExpenseProvider {
    func placeholder(in context: Context) -> TodayExpenseEntry {
        // 优先使用缓存数据
        if let cachedData = WidgetCache.shared.load() {
            return TodayExpenseEntry(date: Date(), data: cachedData)
        }
        
        // 否则使用假数据
        return TodayExpenseEntry(date: Date(), data: mockData)
    }
}
```

### 7.2 内存优化

```swift
// 限制Widget中的数据量
extension WidgetDataService {
    func fetchTodayData() async throws -> WidgetData {
        // ...
        
        // ⚠️ 只取前5笔，避免Widget内存占用过大
        let simpleTransactions = todayTransactions
            .prefix(5)  // 限制数量
            .map { /* 转换 */ }
        
        return WidgetData(/* ... */)
    }
}
```

### 7.3 刷新频率控制

```swift
// 智能刷新策略
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    Task {
        let entry = await fetchData()
        
        // 根据时间段调整刷新频率
        let hour = Calendar.current.component(.hour, from: Date())
        let nextUpdateMinutes: Int
        
        if hour >= 7 && hour <= 22 {
            // 活跃时段：30分钟
            nextUpdateMinutes = 30
        } else {
            // 夜间：2小时
            nextUpdateMinutes = 120
        }
        
        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: nextUpdateMinutes,
            to: Date()
        )!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

---

## 8. 测试与调试

### 8.1 Widget预览

```swift
// 在Xcode中预览Widget
struct TodayExpenseWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small Widget
            SmallWidgetView(data: mockData)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - 今日支出")
            
            // Medium Widget
            MediumWidgetView(data: mockData)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - 支出+流水")
            
            // Large Widget
            LargeWidgetView(data: mockData)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large - 完整视图")
        }
    }
    
    static var mockData: WidgetData {
        WidgetData(
            todayExpense: 256.50,
            todayBudget: 200.00,
            budgetUsagePercentage: 0.78,
            recentTransactions: [
                SimpleTransaction(
                    id: UUID(),
                    amount: 45.00,
                    categoryName: "午餐",
                    categoryIcon: "fork.knife",
                    date: Date(),
                    type: "expense"
                ),
                // ... 更多mock数据
            ],
            lastUpdateTime: Date()
        )
    }
}
```

### 8.2 调试技巧

#### 1. 打印日志

```swift
// Widget日志会输出到Console.app
print("Widget刷新时间: \(Date())")
print("获取到的数据: \(widgetData)")
```

#### 2. 强制刷新

```swift
// 在主App中触发刷新用于测试
Button("刷新Widget") {
    WidgetCenter.shared.reloadAllTimelines()
}
```

#### 3. 检查App Group

```swift
// 验证App Group是否正确配置
if let url = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.yourcompany.jizhang"
) {
    print("App Group路径: \(url.path)")
} else {
    print("❌ App Group未配置")
}
```

---

## 附录：完整示例

### Widget主文件

```swift
// jizhangWidget.swift
import WidgetKit
import SwiftUI

struct TodayExpenseWidget: Widget {
    let kind: String = "TodayExpenseWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: TodayExpenseProvider()
        ) { entry in
            TodayExpenseWidgetView(entry: entry)
        }
        .configurationDisplayName("今日支出")
        .description("查看今日支出和预算使用情况")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayExpenseWidgetView: View {
    let entry: TodayExpenseEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            EmptyView()
        }
    }
}
```

---

**文档维护**: 随Widget功能迭代持续更新  
**最后更新**: 2026-01-24
