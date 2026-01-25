# 账本切换功能修复报告

## 问题描述

1. **冷启动问题**：App 冷启动后，没有正确显示默认账本
2. **账本切换失效**：在流水、统计、设置页面中选择账本后，点击首页会导致账本回到"日常账本"

## 问题根本原因

### 问题 1：冷启动账本加载

在 `HomeView` 的 `initializeDataIfNeeded()` 方法中，每次 `onAppear` 都会强制将 `appState.currentLedger` 设置为 `ledgers.first`，而不考虑：
- 用户上次选择的账本（保存在 UserDefaults 中）
- 标记为默认的账本
- 当前是否已有选中的账本

这导致即使用户在其他页面切换了账本，回到首页时也会被强制重置。

### 问题 2：账本状态持久化

虽然 `AppState.saveCurrentLedgerID()` 会保存账本 ID 到 UserDefaults，但在 App 启动时的加载顺序存在问题：
1. `jizhangApp` 在 `onAppear` 中尝试加载默认账本
2. `HomeView` 在 `onAppear` 中强制覆盖为第一个账本
3. 导致保存的账本 ID 无法正确恢复

## 修复方案

### 1. 修改 `HomeView.swift`

**移除问题代码：**
- 删除了 `initializeDataIfNeeded()` 方法
- 删除了未使用的 `@State private var selectedLedger: Ledger?`

**优化 `onAppear` 逻辑：**
```swift
.onAppear {
    // 仅在没有账本数据时初始化
    if ledgers.isEmpty {
        createDefaultLedger()
    }
}
```

**改进 `createDefaultLedger()` 方法：**
```swift
private func createDefaultLedger() {
    let ledger = Ledger(name: "日常账本", isDefault: true)
    modelContext.insert(ledger)
    
    // 创建默认分类
    ledger.createDefaultCategories()
    
    // 创建默认账户
    ledger.createDefaultAccounts()
    
    do {
        try modelContext.save()
        // 创建完成后，立即设置为当前账本
        appState.currentLedger = ledger
        print("✅ 创建并设置默认账本: \(ledger.name)")
    } catch {
        print("⚠️ 保存默认账本失败: \(error)")
    }
}
```

### 2. 优化 `AppState.swift`

**改进 `loadDefaultLedger()` 方法：**
- 添加了更详细的日志输出
- 在查询时过滤归档的账本
- 优化了查询逻辑

```swift
@MainActor
func loadDefaultLedger() -> Ledger? {
    let context = modelContainer.mainContext
    
    // 1. 尝试加载上次使用的账本（从UserDefaults中读取）
    if let savedLedgerId = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.string(forKey: "currentLedgerId"),
       let uuid = UUID(uuidString: savedLedgerId) {
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.id == uuid && $0.isArchived == false }
        )
        if let ledger = try? context.fetch(descriptor).first {
            print("📖 加载上次使用的账本: \(ledger.name)")
            return ledger
        } else {
            print("⚠️ 上次使用的账本已归档或不存在，尝试加载默认账本")
        }
    }
    
    // 2. 加载标记为默认的账本
    let defaultDescriptor = FetchDescriptor<Ledger>(
        predicate: #Predicate { $0.isDefault == true && $0.isArchived == false }
    )
    if let ledger = try? context.fetch(defaultDescriptor).first {
        print("📖 加载默认账本: \(ledger.name)")
        return ledger
    }
    
    // 3. 返回第一个未归档的账本
    let firstDescriptor = FetchDescriptor<Ledger>(
        predicate: #Predicate { $0.isArchived == false },
        sortBy: [SortDescriptor(\.sortOrder)]
    )
    if let ledger = try? context.fetch(firstDescriptor).first {
        print("📖 加载第一个可用账本: \(ledger.name)")
        return ledger
    }
    
    print("⚠️ 没有可用的账本")
    return nil
}
```

### 3. 优化 `jizhangApp.swift`

**改进 `loadDefaultLedgerIfNeeded()` 方法：**
```swift
@MainActor
private func loadDefaultLedgerIfNeeded() {
    // 等待一个RunLoop，确保数据库已经完全初始化
    Task {
        // 如果没有当前账本，则加载默认账本
        if appState.currentLedger == nil {
            appState.currentLedger = appState.loadDefaultLedger()
            print("✅ 加载默认账本: \(appState.currentLedger?.name ?? "无")")
        }
    }
}
```

## 修复后的工作流程

### 冷启动流程
1. App 启动 -> `jizhangApp.onAppear`
2. 调用 `loadDefaultLedgerIfNeeded()`
3. 检查 `appState.currentLedger` 是否为 nil
4. 如果为 nil，调用 `appState.loadDefaultLedger()`
5. `loadDefaultLedger()` 按优先级查找：
   - 上次使用的账本（从 UserDefaults）
   - 标记为默认的账本
   - 第一个未归档的账本
6. 如果数据库中没有账本，`HomeView.onAppear` 会创建默认账本

### 账本切换流程
1. 用户在任意页面点击 `LedgerSwitcher`
2. 打开 `LedgerPickerSheet`
3. 选择账本后，通过 Binding 更新 `appState.currentLedger`
4. `AppState.currentLedger.didSet` 触发，调用 `saveCurrentLedgerID()`
5. 账本 ID 保存到 UserDefaults（App Groups 共享容器）
6. 所有视图的计算属性自动刷新（响应式更新）

### 切换 Tab 流程
1. 用户点击底部 TabBar 切换到首页
2. `HomeView.onAppear` 被调用
3. **不再强制重置账本** - 仅在数据库为空时创建默认账本
4. 当前账本保持不变

## 关键改进点

1. **单一数据源**：`appState.currentLedger` 是唯一的账本状态来源
2. **避免强制覆盖**：移除了 `HomeView` 中会覆盖账本选择的代码
3. **正确的初始化顺序**：App 启动时由 `jizhangApp` 统一管理账本加载
4. **状态持久化**：通过 UserDefaults（App Groups）保存和恢复账本选择
5. **响应式更新**：利用 SwiftUI 的响应式机制，账本切换后所有视图自动更新

## 测试建议

### 测试场景 1：冷启动
1. 完全关闭 App（从后台清除）
2. 重新启动 App
3. **预期结果**：显示上次使用的账本或默认账本

### 测试场景 2：账本切换
1. 在"流水"页面点击顶部账本切换器
2. 选择一个不同的账本（例如："旅游账本"）
3. 点击底部"首页"Tab
4. **预期结果**：首页显示"旅游账本"，而不是回到"日常账本"

### 测试场景 3：多账本切换
1. 在"统计"页面切换到账本 A
2. 切换到"设置"页面，切换到账本 B
3. 切换到"首页"
4. **预期结果**：首页显示账本 B

### 测试场景 4：首次启动
1. 删除 App 并重新安装
2. 启动 App
3. **预期结果**：自动创建"日常账本"并设置为当前账本

## 修改的文件清单

- ✅ `jizhang/jizhang/App/AppState.swift` - 优化账本加载逻辑
- ✅ `jizhang/jizhang/App/jizhangApp.swift` - 改进启动时的账本加载
- ✅ `jizhang/jizhang/Views/Home/HomeView.swift` - 移除强制覆盖账本的代码

## 未修改的文件

以下文件的账本切换逻辑已经正确，无需修改：
- `jizhang/jizhang/Views/Components/LedgerSwitcher.swift` - 账本切换器
- `jizhang/jizhang/Views/Ledger/LedgerPickerSheet.swift` - 账本选择器
- `jizhang/jizhang/Views/Transaction/TransactionListView.swift` - 流水页面
- `jizhang/jizhang/Views/Report/ReportView.swift` - 统计页面
- `jizhang/jizhang/Views/Settings/SettingsView.swift` - 设置页面
- `jizhang/jizhang/Views/Components/TabBarView.swift` - Tab 切换

这些视图都正确使用了 `appState.currentLedger`，并且不会错误地修改它。

## 总结

此次修复的核心思想是：
1. **集中管理**：账本的加载和初始化由 App 层面统一管理
2. **避免覆盖**：各个子视图只读取账本状态，不随意修改
3. **持久化存储**：正确使用 UserDefaults 保存和恢复用户选择
4. **响应式设计**：充分利用 SwiftUI 的响应式机制，让数据驱动 UI

修复后，账本切换功能将按照用户预期工作，无论在哪个页面切换账本，状态都会正确保持。
