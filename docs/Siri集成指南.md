# Siri 快捷指令调试指南

## 🚨 已修复的关键问题

### 1. App Group ID 不匹配 ✅
**问题：** Intent 代码中使用 `group.com.yourcompany.jizhang`，但实际配置是 `group.com.xxl.jizhang`

**影响：** Intent 无法访问共享数据，导致 Siri 提示"不支持此操作"

**修复：** 已将所有 Intent 文件中的 App Group ID 统一为 `group.com.xxl.jizhang`

### 2. 缺少 Siri 权限 ✅
**问题：** entitlements 文件中缺少 `com.apple.developer.siri` 权限

**修复：** 已添加到 `jizhang.entitlements`

---

## 🔍 验证步骤

### 第一步：检查 Xcode 设置

1. **打开项目设置**
   - 选择 jizhang target
   - 点击 "Signing & Capabilities" 标签

2. **验证 Capabilities**
   确认已启用以下功能：
   - ✅ App Groups (`group.com.xxl.jizhang`)
   - ✅ iCloud (CloudKit)
   - ✅ Push Notifications
   - ⚠️ **检查是否有 "Siri" Capability**

3. **如果缺少 Siri Capability**
   - 点击 "+ Capability"
   - 搜索并添加 "Siri"

### 第二步：Clean Build

```bash
# 方法1：Xcode 菜单
Product → Clean Build Folder (Cmd + Shift + K)

# 方法2：终端命令
cd /Users/xuxiaolong/OpenSource/jizhang_ios
xcodebuild clean -scheme jizhang
```

### 第三步：检查编译产物

运行后检查 App Bundle 中是否包含 Intents 元数据：

```bash
# 安装后查找 Metadata.appintents 文件
# 在 Xcode 控制台查找以下日志：
ExtractAppIntentsMetadata
Writing Metadata.appintents
```

如果看到 `Writing Metadata.appintents`，说明 Intents 已被正确提取。

### 第四步：完全卸载重装

**重要！必须完全删除数据！**

1. **删除 App**
   ```
   长按 App 图标 → 删除 App → 删除
   ```

2. **清除设置中的数据**
   - 打开"设置" App
   - 搜索"简记账"
   - 如果有任何配置，删除它们

3. **清除 Siri 缓存（可选）**
   - 设置 → Siri 与搜索
   - 关闭"听取 '嘿 Siri'"
   - 等待 10 秒
   - 重新打开

4. **重启设备（推荐）**
   - 完全关机
   - 等待 10 秒
   - 重新开机

5. **重新安装**
   - Xcode → Product → Run

### 第五步：验证 Shortcuts 注册

1. **打开快捷指令 App**

2. **创建新快捷指令**
   - 点击右上角 "+"
   - 点击"添加操作"
   - 搜索"简记账"

3. **应该看到的内容**
   - ✅ 记一笔支出
   - ✅ 查询今日支出
   - ✅ 查询本月预算

4. **如果看不到任何动作**
   - 说明 Intents 未被注册
   - 查看下一节的调试方法

---

## 🛠️ 深度调试

### 检查 1：验证 App Group 配置

```swift
// 在 AppDelegate 或 App 启动时添加调试代码
let appGroupIdentifier = "group.com.xxl.jizhang"
if let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupIdentifier
) {
    print("✅ App Group 配置正确: \(containerURL.path)")
} else {
    print("❌ App Group 配置错误！")
}
```

### 检查 2：查看 Xcode 编译日志

在 Xcode 的 Report Navigator 中：
1. 选择最新的 Build
2. 搜索 `appintentsmetadataprocessor`
3. 应该看到：
   ```
   ExtractAppIntentsMetadata (in target 'jizhang' from project 'jizhang')
   Writing Metadata.appintents
   ```

### 检查 3：验证 Intent 初始化

在 `AddExpenseIntent.swift` 中添加调试日志：

```swift
@MainActor
func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    print("🎤 AddExpenseIntent 开始执行")
    print("📊 金额: \(amount)")
    print("📁 分类: \(categoryName ?? "无")")
    
    // ... 现有代码
}
```

### 检查 4：测试简单的 Intent

先测试不需要参数的 Intent，比如 `GetTodayExpenseIntent`：

```
"Hey Siri，在简记账查看今日支出"
```

如果这个可以工作，说明问题在参数传递上。

### 检查 5：iOS 版本验证

```
设置 → 通用 → 关于本机 → 软件版本
```

**必须是 iOS 16.0 或更高！**

如果是 iOS 15，App Intents 完全不可用。

---

## 🎯 手动创建快捷指令测试

如果 Siri 语音无法识别，可以先尝试手动创建快捷指令：

### 测试方案 1：查询今日支出（无参数）

1. 打开快捷指令 App
2. 点击 "+" 新建快捷指令
3. 搜索"简记账"
4. 选择"查询今日支出"
5. 点击"完成"
6. 运行这个快捷指令

**预期结果：**
- ✅ 显示今日支出金额和笔数
- ❌ 如果失败，查看错误信息

### 测试方案 2：记一笔支出（带参数）

1. 创建新快捷指令
2. 添加"记一笔支出"动作
3. 设置：
   - 金额：50
   - 分类：餐饮
   - 备注：测试
4. 运行快捷指令

**预期结果：**
- ✅ 显示"已记录支出 ¥50.0"
- ✅ 在 App 中能看到这笔交易
- ❌ 如果失败，查看具体错误

---

## 🚑 常见错误及解决方案

### 错误 1："简记账暂时不支持此操作"

**可能原因：**
1. ❌ Intents 未注册到系统
2. ❌ App Group ID 不匹配
3. ❌ 缺少 Siri 权限
4. ❌ iOS 版本过低

**解决方案：**
- 确认上述所有修复已应用
- 完全卸载重装
- 重启设备

### 错误 2："数据访问失败"

**可能原因：**
- App Group ID 错误
- 数据库文件路径不正确

**解决方案：**
```swift
// 验证 App Group
let appGroupIdentifier = "group.com.xxl.jizhang"
guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupIdentifier
) else {
    print("❌ 无法访问 App Group: \(appGroupIdentifier)")
    throw IntentError.dataAccessFailed
}

print("✅ App Group URL: \(containerURL.path)")

let storeURL = containerURL.appendingPathComponent("jizhang.sqlite")
print("✅ 数据库路径: \(storeURL.path)")
print("✅ 文件存在: \(FileManager.default.fileExists(atPath: storeURL.path))")
```

### 错误 3："未找到账本"

**可能原因：**
- 首次安装后未创建账本
- 账本被归档或删除

**解决方案：**
1. 打开 App
2. 创建一个新账本
3. 创建至少一个账户
4. 添加一笔测试交易
5. 再次测试 Siri

### 错误 4：Siri 说"我不理解"

**可能原因：**
- 语音指令格式不正确
- Siri 语言设置问题

**解决方案：**
1. 确认 Siri 语言设置为"中文（简体）"
2. 使用完整的指令格式：
   - ✅ "Hey Siri，在简记账记一笔"
   - ❌ "Hey Siri，简记账记一笔"（缺少"在"）
   - ❌ "Hey Siri，记一笔"（缺少 App 名称）

---

## 🎤 测试用语音指令

### 标准指令（完整格式）
```
"Hey Siri，在简记账记一笔"
"Hey Siri，在简记账查看今日支出"
"Hey Siri，在简记账查看预算"
```

### 变体指令
```
"Hey Siri，用简记账添加支出"
"Hey Siri，用简记账查看今天花了多少"
"Hey Siri，用简记账查询预算"
```

### 简短指令
```
"Hey Siri，简记账今日花费"
"Hey Siri，简记账预算情况"
```

---

## 📊 成功标志

当一切正常时，你应该看到：

1. **快捷指令 App 中**
   - ✅ 能搜索到"简记账"
   - ✅ 显示 3 个可用动作
   - ✅ 每个动作都有图标和说明

2. **运行快捷指令时**
   - ✅ 无需打开 App 即可执行
   - ✅ 有语音反馈
   - ✅ 数据正确保存到数据库

3. **使用 Siri 时**
   - ✅ Siri 正确识别命令
   - ✅ 提示输入必要参数
   - ✅ 播报执行结果

4. **在 App 中**
   - ✅ 通过 Siri 添加的交易正常显示
   - ✅ Widget 数据同步更新

---

## 🔧 Xcode 项目检查清单

在 Xcode 中确认以下配置：

### Target: jizhang

- [ ] Deployment Target: iOS 17.6
- [ ] Swift Version: Swift 5+
- [ ] Signing: 正确配置
- [ ] Capabilities:
  - [ ] App Groups: `group.com.xxl.jizhang`
  - [ ] iCloud: CloudKit
  - [ ] Push Notifications
  - [ ] **Siri** ⚠️ 重点检查

### Info.plist

- [ ] `NSSiriUsageDescription`: 已配置
- [ ] `NSUserActivityTypes`: 包含 3 个 Intent
- [ ] `INIntentsSupported`: 包含 3 个 Intent
- [ ] `INIntentsRestrictedWhileLocked`: 空数组
- [ ] `INIntentsRestrictedWhileProtectedDataUnavailable`: 空数组

### Entitlements

- [ ] `com.apple.developer.siri`: true
- [ ] `com.apple.security.application-groups`: `group.com.xxl.jizhang`
- [ ] `com.apple.developer.icloud-services`: CloudKit

### 源代码

- [ ] 所有 Intent 使用 `group.com.xxl.jizhang`
- [ ] `@available(iOS 16.0, *)` 标注正确
- [ ] `AppShortcutsProvider` 正确实现
- [ ] 在 App 启动时调用 `updateAppShortcutParameters()`

---

## 📞 获取帮助

如果以上步骤都无法解决问题：

1. **查看 Console.app 日志**
   - 打开 macOS 的"控制台" App
   - 连接 iPhone
   - 筛选关键词：`jizhang`、`AppIntents`、`Siri`

2. **提取详细错误信息**
   - 在 Xcode 控制台中查看完整错误堆栈
   - 截图发送给开发者

3. **提供设备信息**
   - iOS 版本
   - 设备型号
   - Xcode 版本
   - 是否使用 TestFlight 或直接安装

---

## 💡 最终建议

如果尝试了所有方法仍然失败：

### 方案 A：使用 URL Scheme 代替
```swift
// 创建简单的快捷指令
打开 URL: jizhang://add-transaction
```
虽然不如 App Intents 智能，但保证可用。

### 方案 B：等待 iOS 系统索引
有时 iOS 需要 24-48 小时才能完全索引新的 App Intents。
尝试等待一天后再测试。

### 方案 C：使用 Shortcuts 编辑器
即使 Siri 语音不工作，用户也可以在快捷指令 App 中手动创建和运行快捷指令。
