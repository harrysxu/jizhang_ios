# CloudKit 修复说明 (v6)

## 📋 问题总结

之前 CloudKit 在真机上失败的根本原因是：

### ❌ 错误 1: 关系缺少反向绑定
```
CloudKit integration requires that all relationships have an inverse, the following do not:
Tag: transactions
Transaction: tags
```

**原因**：Tag 和 Transaction 之间的多对多关系没有使用 `@Relationship(inverse:)` 标注。

### ❌ 错误 2: 属性缺少默认值
```
CloudKit integration requires that all attributes be optional, or have a default value set.
The following attributes are marked non-optional but do not have a default value:
Account: balance, colorHex, createdAt, ...
```

**原因**：CloudKit 要求所有非可选属性必须有默认值。SwiftData 的 `@Model` 类不能在 `init` 中设置默认值，必须在属性声明时设置。

### ❌ 错误 3: 缺少后台模式
```
BUG IN CLIENT OF CLOUDKIT: CloudKit push notifications require the 'remote-notification' background mode in your info plist.
```

**原因**：CloudKit 需要接收远程通知以进行数据同步，必须在 Info.plist 中启用 `remote-notification` 后台模式。

---

## ✅ 修复方案

### 1. Tag.swift
```swift
// 修复前
var id: UUID
var name: String
var transactions: [Transaction]?

// 修复后
var id: UUID = UUID()
var name: String = ""
@Relationship(inverse: \Transaction.tags)
var transactions: [Transaction]?
```

### 2. Transaction.swift
```swift
// 修复前
var id: UUID
var amount: Decimal
var tags: [Tag]?

// 修复后
var id: UUID = UUID()
var amount: Decimal = 0
@Relationship(inverse: \Tag.transactions)
var tags: [Tag]?
```

### 3. Account.swift
```swift
// 修复前
var id: UUID
var name: String
var balance: Decimal
var colorHex: String

// 修复后
var id: UUID = UUID()
var name: String = ""
var balance: Decimal = 0
var colorHex: String = "#007AFF"
```

### 4. Ledger.swift
```swift
// 修复前
var id: UUID
var name: String
var currencyCode: String

// 修复后
var id: UUID = UUID()
var name: String = ""
var currencyCode: String = "CNY"
```

### 5. Category.swift
```swift
// 修复前
var id: UUID
var name: String
var type: CategoryType

// 修复后
var id: UUID = UUID()
var name: String = ""
var type: CategoryType = .expense
```

### 6. Budget.swift
```swift
// 修复前
var id: UUID
var amount: Decimal
var period: BudgetPeriod

// 修复后
var id: UUID = UUID()
var amount: Decimal = 0
var period: BudgetPeriod = .monthly
```

### 7. Info.plist
```xml
<!-- 新增 -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 8. AppState.swift
```swift
// 更新 Schema 版本
let needsCleanDatabase = sharedDefaults?.bool(forKey: "needsCleanDatabase_v6") ?? true
```

---

## 🚀 测试步骤

### 步骤 1: 清理环境
```bash
# 在 Xcode 中
1. Product → Clean Build Folder (⇧⌘K)
2. 删除 Derived Data
   rm -rf ~/Library/Developer/Xcode/DerivedData/jizhang-*
```

### 步骤 2: 清理真机数据
```
1. 删除真机上的「简记账」应用
2. 设置 → Apple ID → iCloud → 管理储存空间
   → 找到「简记账」→ 删除数据（如果有）
3. 设置 → 通用 → iPhone 储存空间
   → 找到「简记账」→ 删除应用（如果还在）
```

### 步骤 3: 重新运行
```
1. 确保真机已登录 iCloud
2. 在 Xcode 中选择真机
3. Build and Run (⌘R)
```

### 步骤 4: 验证日志
**期望看到**：
```
📱 iCloud 账户状态: 已登录
✅ 成功创建ModelContainer (CloudKit模式)
✅ 创建并设置默认账本: 日常账本
```

**不应该看到**：
```
⚠️ CloudKit模式失败
CoreData: error: Store failed to load
```

---

## 📊 CloudKit Dashboard 验证

### 访问 Dashboard
1. 打开 https://icloud.developer.apple.com/dashboard/
2. 选择 `iCloud.com.xxl.jizhang` 容器
3. 选择 **Development** 环境
4. 进入 **Schema** → **Record Types**

### 应该看到的 Record Types
- `CD_Ledger`
- `CD_Account`
- `CD_Category`
- `CD_Transaction`
- `CD_Budget`
- `CD_Tag`

### 验证关系
点击 `CD_Tag`，应该看到：
- `transactions` - Type: `Reference List`, Target: `CD_Transaction`

点击 `CD_Transaction`，应该看到：
- `tags` - Type: `Reference List`, Target: `CD_Tag`

---

## 🔍 常见问题

### Q1: 还是看到 "CloudKit模式失败"
**A**: 请确保：
1. 已完全清理旧数据（真机 + iCloud）
2. 真机已登录 iCloud 且 iCloud Drive 已启用
3. 查看完整错误日志，可能是其他原因

### Q2: CloudKit Dashboard 中没有看到 Schema
**A**: Schema 是在首次运行时自动创建的，需要：
1. 确保应用成功启动且显示 "✅ 成功创建ModelContainer (CloudKit模式)"
2. 等待 1-2 分钟，Schema 同步需要时间
3. 刷新 CloudKit Dashboard 页面

### Q3: 个人开发者账号有限制吗？
**A**: 个人账号可以使用 CloudKit，但有一些限制：
- Development 环境：完全可用
- Production 环境：需要发布到 App Store
- 数据配额：1GB 存储 + 25MB/天 下载（免费）

### Q4: 如何在两台设备间测试同步？
**A**:
1. 两台设备都登录同一个 iCloud 账号
2. 在设备 A 上创建数据
3. 等待 10-30 秒
4. 在设备 B 上打开应用，应该自动同步

---

## 📚 技术要点

### SwiftData + CloudKit 的要求

1. **关系必须有反向关系**
   ```swift
   // 正确
   @Relationship(inverse: \Transaction.tags)
   var transactions: [Transaction]?
   
   // 错误
   var transactions: [Transaction]?
   ```

2. **属性必须有默认值或可选**
   ```swift
   // 正确
   var name: String = ""
   var amount: Decimal = 0
   var note: String?  // 可选
   
   // 错误
   var name: String
   var amount: Decimal
   ```

3. **后台模式**
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>remote-notification</string>
   </array>
   ```

4. **Entitlements**
   ```xml
   <!-- iCloud 容器 -->
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array>
       <string>iCloud.com.xxl.jizhang</string>
   </array>
   
   <!-- CloudKit 服务 -->
   <key>com.apple.developer.icloud-services</key>
   <array>
       <string>CloudKit</string>
   </array>
   
   <!-- Push Notifications -->
   <key>aps-environment</key>
   <string>development</string>
   ```

---

## 🎯 预期结果

修复后，应该能够：

1. ✅ 在真机上成功启用 CloudKit 模式
2. ✅ 数据自动同步到 iCloud
3. ✅ 在 CloudKit Dashboard 中看到数据
4. ✅ 多设备间数据自动同步
5. ✅ 应用重装后数据自动恢复

---

## 📞 获取帮助

如果修复后仍有问题，请提供：

1. **完整的控制台日志**（从应用启动开始）
2. **CloudKit Dashboard 截图**（Schema 页面）
3. **真机设置截图**：
   - 设置 → Apple ID → iCloud
   - 设置 → 简记账（如果有）
4. **Xcode 配置截图**：
   - Signing & Capabilities 页面

---

## 版本历史

- **v6 (2026-01-31)**: 修复 CloudKit 兼容性问题
  - 添加关系反向绑定
  - 添加属性默认值
  - 添加后台模式
  
- **v5**: 移除 unique 约束

- **v4**: 初始 CloudKit 集成
