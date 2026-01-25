# 账本功能使用指南

## 🚀 快速开始

### 对于开发者

账本功能优化已全部完成并通过测试。以下是关键改进:

#### 1. 启动应用
```swift
// 应用会自动:
// ✅ 检查并执行数据迁移
// ✅ 加载上次使用的账本
// ✅ 如果没有账本,创建默认账本
```

#### 2. 切换账本
- 点击首页顶部的 **"📘 账本名称 ▼"** 胶囊按钮
- 选择目标账本
- 界面主题色自动切换

#### 3. 管理账本
- 在账本选择器中点击 **"管理账本"**
- 或直接进入设置页面

---

## 📚 关键API

### AppState - 全局账本状态

```swift
// 获取当前账本
let currentLedger = appState.currentLedger

// 切换账本 (会自动触发主题应用)
appState.currentLedger = newLedger

// 加载默认账本
appState.currentLedger = appState.loadDefaultLedger()
```

### LedgerViewModel - 账本操作

```swift
let viewModel = LedgerViewModel(modelContext: modelContext)

// 创建账本
try viewModel.createLedger(
    name: "新账本",
    currencyCode: "CNY",
    colorHex: "#007AFF",
    iconName: "book.fill"
)

// 复制账本设置
try viewModel.copyLedgerSettings(
    from: sourceLedger,
    to: targetLedger
)

// 设为默认
try viewModel.setDefaultLedger(ledger)
```

### DataMigration - 数据迁移

```swift
// 在AppState初始化时自动调用
DataMigration.migrateIfNeeded(context: modelContext)

// 手动清理无效数据
try DataMigration.cleanupInvalidData(context: modelContext)
```

---

## 🎨 UI组件

### LedgerSwitcher - 导航栏切换器

```swift
// 在NavigationBar中使用
.toolbar {
    ToolbarItem(placement: .principal) {
        LedgerSwitcher()
    }
}
```

### LedgerPickerSheet - 账本选择器

```swift
.sheet(isPresented: $showPicker) {
    LedgerPickerSheet(currentLedger: $appState.currentLedger)
}
```

### LedgerOverviewView - 账本详情

```swift
.sheet(isPresented: $showOverview) {
    LedgerOverviewView(ledger: selectedLedger)
}
```

---

## 🧪 测试

运行测试:
```bash
# 运行所有测试
xcodebuild test -scheme jizhang

# 只运行账本隔离测试
xcodebuild test -scheme jizhang -only-testing:jizhangTests/LedgerIsolationTests
```

---

## 🎯 核心改进点

### 1. 数据完全隔离 ✅
- 每个账本拥有独立的账户、分类、交易、预算
- 切换账本=切换完整的数据环境
- 删除账本自动级联删除所有关联数据

### 2. 视觉清晰区分 ✅
- 每个账本有独立的主题色
- 导航栏显示当前账本名称和图标
- 切换时界面主题色动态变化

### 3. 用户体验流畅 ✅
- 账本切换器位于显著位置
- 显示账本统计信息(账户数、交易数)
- 支持账本设置快速复制

### 4. 数据迁移安全 ✅
- 自动检测并修复数据问题
- 确保至少有一个默认账本
- 所有数据正确关联到账本

---

## 📝 最佳实践

### 创建新账本

```swift
// 1. 创建基础账本
let newLedger = Ledger(
    name: "2025账本",
    currencyCode: "CNY",
    colorHex: "#34C759",  // 绿色
    iconName: "calendar",
    isDefault: false
)
modelContext.insert(newLedger)

// 2. 复制现有账本的设置
try viewModel.copyLedgerSettings(
    from: oldLedger,
    to: newLedger
)

// 3. 保存
try modelContext.save()
```

### 查询当前账本的数据

```swift
// 在View中使用计算属性
private var currentLedgerTransactions: [Transaction] {
    guard let currentLedger = appState.currentLedger else {
        return []
    }
    return transactions.filter { $0.ledger?.id == currentLedger.id }
}

// 在ViewModel中使用FetchDescriptor
func fetchAccounts(for ledger: Ledger) throws -> [Account] {
    let descriptor = FetchDescriptor<Account>(
        predicate: #Predicate { $0.ledger?.id == ledger.id },
        sortBy: [SortDescriptor(\.sortOrder)]
    )
    return try modelContext.fetch(descriptor)
}
```

### 切换账本时刷新数据

```swift
// HomeView示例
.onChange(of: appState.currentLedger) { oldValue, newValue in
    // 视图会自动重新计算所有计算属性
    // 无需手动刷新,因为使用的是响应式数据绑定
}
```

---

## ⚠️ 注意事项

### 1. 避免跨账本操作
```swift
// ❌ 错误: 在账本A中使用账本B的账户
let transaction = Transaction(
    ledger: ledgerA,
    fromAccount: ledgerB.accounts.first, // 错误!
    ...
)

// ✅ 正确: 确保账户属于当前账本
let transaction = Transaction(
    ledger: currentLedger,
    fromAccount: currentLedger.accounts.first,
    ...
)
```

### 2. 删除账本前检查
```swift
// 建议在删除前提示用户
if !ledger.transactions.isEmpty {
    // 显示警告: "账本中还有X笔交易,删除后无法恢复"
}
```

### 3. 默认账本管理
```swift
// 系统保证:
// - 至少有一个账本
// - 有且仅有一个默认账本
// - 删除默认账本时,自动设置另一个为默认
```

---

## 🔧 故障排查

### 问题1: 切换账本后数据未更新

**检查:**
1. 是否正确过滤了当前账本? 
2. 是否使用了`@Query`而没有过滤条件?

**解决:**
```swift
// 使用计算属性过滤
private var filteredData: [Transaction] {
    transactions.filter { $0.ledger?.id == appState.currentLedger?.id }
}
```

### 问题2: 主题色未变化

**检查:**
1. AppState的`currentLedger`是否正确更新?
2. `applyTheme()`是否被调用?

**解决:**
- 确保通过`appState.currentLedger = newLedger`触发didSet
- 检查UIApplication.shared.connectedScenes是否可用

### 问题3: 数据迁移失败

**检查:**
1. 查看控制台迁移日志
2. 检查数据库文件权限

**解决:**
```swift
// 手动触发迁移
DataMigration.migrateIfNeeded(context: modelContext)
```

---

## 📱 用户场景示例

### 场景1: 个人+家庭记账

```swift
// 创建个人账本 (已有)
// 创建家庭账本
let familyLedger = Ledger(
    name: "家庭账本",
    currencyCode: "CNY",
    colorHex: "#FF9500",  // 橙色
    iconName: "house.fill"
)

// 工作日使用个人账本
// 周末切换到家庭账本
```

### 场景2: 年度账本管理

```swift
// 每年1月创建新账本
let newYearLedger = Ledger(name: "2025账本")

// 复制去年的账户和分类设置
try viewModel.copyLedgerSettings(
    from: ledger2024,
    to: newYearLedger
)

// 归档去年的账本
ledger2024.isArchived = true
```

### 场景3: 旅行专用账本

```swift
// 出发前创建旅行账本
let travelLedger = Ledger(
    name: "日本旅行",
    currencyCode: "JPY",  // 使用日元
    colorHex: "#34C759",
    iconName: "airplane"
)

// 旅行期间使用此账本
// 回国后归档
```

---

## 🎓 总结

账本功能现在已经:
- ✅ **数据完全隔离** - 每个账本独立管理
- ✅ **视觉清晰明确** - 主题色区分不同账本
- ✅ **操作简单流畅** - 一键切换,自动同步
- ✅ **数据安全可靠** - 完整测试,迁移保护

**开始使用吧!** 🚀
