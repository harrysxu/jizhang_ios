# CloudKit 故障排查指南

## ✅ 最新修复 (v6)

### 已修复的问题

1. ✅ **关系反向绑定**：修复了 Tag ↔ Transaction 的多对多关系
2. ✅ **属性默认值**：所有属性现在都有默认值，符合 CloudKit 要求
3. ✅ **后台模式**：添加了 `remote-notification` 到 Info.plist
4. ✅ **Schema 版本**：更新到 v6，清理旧的不兼容数据

### 修改的文件

- `Models/Tag.swift` - 添加 `@Relationship(inverse:)` 和默认值
- `Models/Transaction.swift` - 添加 `@Relationship(inverse:)` 和默认值
- `Models/Account.swift` - 添加默认值
- `Models/Ledger.swift` - 添加默认值
- `Models/Category.swift` - 添加默认值
- `Models/Budget.swift` - 添加默认值
- `Info.plist` - 添加 UIBackgroundModes
- `App/AppState.swift` - 更新 Schema 版本到 v6

### 下一步操作

1. **删除真机上的旧应用**
2. **清理 iCloud 数据**（设置 → Apple ID → iCloud → 管理储存空间 → 删除「简记账」）
3. **重新 Build and Run**

---

## 错误症状
```
⚠️ CloudKit模式仍然失败，回退到本地模式
📋 重试错误: SwiftDataError(_error: SwiftData.SwiftDataError._Error.loadIssueModelContainer, _explanation: nil)
```

## 真机测试 CloudKit 失败的常见原因

### 1. ⚠️ Apple Developer 配置问题

#### 1.1 检查 App ID 配置
1. 登录 [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. 找到 `com.xxl.jizhang` 这个 App ID
3. 确认已启用以下功能：
   - ✅ **iCloud** (必须勾选)
   - ✅ **CloudKit** (在 iCloud 下方)
   - ✅ **App Groups** (必须勾选)

#### 1.2 检查 CloudKit 容器
1. 在 App ID 设置中点击 "Edit" → "iCloud"
2. 查看 CloudKit Containers 列表
3. **确认 `iCloud.com.xxl.jizhang` 已存在**
   - ❌ 如果不存在，需要点击 "+" 按钮创建
   - ✅ 如果存在，确认已分配给该 App ID

#### 1.3 检查 App Groups
1. 在 [App Groups](https://developer.apple.com/account/resources/identifiers/list/applicationGroup) 中
2. 确认 `group.com.xxl.jizhang` 已创建
3. 确认已分配给 `com.xxl.jizhang` App ID

### 2. ⚠️ Xcode 项目配置问题

#### 2.1 检查 Team ID
```
在 project.pbxproj 中显示: DEVELOPMENT_TEAM = 3LSP26D33P;
```
- 确认这个 Team ID 与您的 Apple Developer 账号一致
- 在 Xcode → Preferences → Accounts 中查看

#### 2.2 检查 Signing & Capabilities
1. 在 Xcode 中选择 `jizhang` target
2. 切换到 "Signing & Capabilities" 标签
3. 确认以下 Capabilities 已添加：
   - ✅ **iCloud**
     - Services: CloudKit
     - Containers: iCloud.com.xxl.jizhang (勾选)
   - ✅ **App Groups**
     - App Groups: group.com.xxl.jizhang (勾选)
   - ✅ **Push Notifications** (CloudKit 需要)
   - ✅ **Background Modes** → Remote notifications (CloudKit 需要)

#### 2.3 检查 Bundle Identifier
```
当前配置: PRODUCT_BUNDLE_IDENTIFIER = com.xxl.jizhang;
```
- 必须与 Apple Developer Portal 中的 App ID 完全一致
- **区分大小写**

### 3. ⚠️ Entitlements 配置问题

检查 `jizhang/jizhang.entitlements` 文件：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Push Notifications (CloudKit 必需) -->
    <key>aps-environment</key>
    <string>development</string>
    
    <!-- iCloud 容器 -->
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.xxl.jizhang</string>
    </array>
    
    <!-- iCloud 服务 -->
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    
    <!-- App Groups -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.xxl.jizhang</string>
    </array>
</dict>
</plist>
```

### 4. ⚠️ 真机设备配置问题

#### 4.1 检查设备 iCloud 登录状态
1. 在真机上打开 **设置** → **Apple ID**（顶部）
2. 确认已登录 iCloud 账号
3. 点击 **iCloud** → 确认 **iCloud Drive** 已启用
4. 向下滚动，确认 **简记账** 应用在列表中（首次运行后出现）

#### 4.2 检查开发者模式
- iOS 16+ 真机首次运行需要启用开发者模式
- 设置 → 隐私与安全 → 开发者模式

### 5. ⚠️ Provisioning Profile 问题

#### 5.1 删除并重新生成
1. 在 Xcode 中选择 `jizhang` target
2. Signing & Capabilities → Signing Certificate
3. 如果显示 "Revoked" 或 "Expired"：
   - 点击 "Download Manual Profiles"
   - 或删除旧的 profile 文件：
     ```bash
     rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
     ```

#### 5.2 真机运行前
1. 在 Xcode 中清理项目：Product → Clean Build Folder (⇧⌘K)
2. 删除设备上的旧版本应用
3. 重新 Build and Run

### 6. ⚠️ CloudKit Dashboard 检查

#### 6.1 访问 CloudKit Dashboard
1. 打开 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. 选择 `iCloud.com.xxl.jizhang` 容器
3. 选择 **Development** 环境

#### 6.2 检查 Schema
- 查看是否自动创建了以下 Record Types：
  - `CD_Ledger`
  - `CD_Account`
  - `CD_Category`
  - `CD_Transaction`
  - `CD_Budget`
  - `CD_Tag`

**注意**: SwiftData + CloudKit 会自动创建 Schema，首次运行时可能需要几分钟。

### 7. ⚠️ 代码级诊断

#### 7.1 添加更详细的日志

在 `AppState.swift` 中，我已经添加了详细的错误日志：

```swift
// 第 138-146 行
print("⚠️ CloudKit模式失败")
print("📋 错误详情: \(error)")
print("📋 错误类型: \(type(of: error))")
if let nsError = error as NSError? {
    print("📋 NSError Domain: \(nsError.domain)")
    print("📋 NSError Code: \(nsError.code)")
    print("📋 NSError UserInfo: \(nsError.userInfo)")
}
```

#### 7.2 查看完整错误信息
在 Xcode 中运行时：
1. 打开 Console (⇧⌘C)
2. 过滤关键词：`CloudKit`、`SwiftData`、`NSError`
3. **将完整的错误日志发给我，包括 Domain、Code 和 UserInfo**

### 8. ⚠️ 常见错误代码

| 错误代码 | 含义 | 解决方案 |
|---------|------|---------|
| Domain: CKError, Code: 3 | 网络错误 | 检查真机网络连接 |
| Domain: CKError, Code: 9 | 无效参数 | 检查容器标识符 |
| Domain: CKError, Code: 11 | 容器未找到 | 在 Developer Portal 创建容器 |
| Domain: CKError, Code: 28 | 配额超限 | 等待或升级 iCloud 存储 |
| Domain: NSCocoaErrorDomain, Code: 134060 | Schema 不兼容 | 删除应用数据并重装 |

## 推荐操作步骤

### 方案 A: 完全重置（最可能解决问题）

```bash
# 1. 在 Xcode 中清理项目
# Product → Clean Build Folder (⇧⌘K)

# 2. 删除真机上的应用

# 3. 删除 Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData/jizhang-*

# 4. 在真机上：设置 → 通用 → iPhone 储存空间
#    找到「简记账」→ 删除应用

# 5. 在真机上：设置 → Apple ID → iCloud → 管理储存空间
#    找到「简记账」→ 删除数据（如果有）

# 6. 重新在 Xcode 中 Build and Run
```

### 方案 B: 检查 Apple Developer Portal

1. **创建 CloudKit 容器**（如果还没有）
   - 访问：https://developer.apple.com/account/resources/identifiers/list/cloudContainer
   - 点击 "+" 创建新容器
   - Identifier: `iCloud.com.xxl.jizhang`
   - Description: `简记账 CloudKit 容器`

2. **关联到 App ID**
   - 访问：https://developer.apple.com/account/resources/identifiers/list
   - 选择 `com.xxl.jizhang`
   - 点击 "Edit"
   - 勾选 iCloud → Edit
   - 在 CloudKit Containers 中选择 `iCloud.com.xxl.jizhang`
   - 保存

3. **重新生成 Provisioning Profile**
   - 在 Xcode 中：Signing & Capabilities → Download Manual Profiles

### 方案 C: 临时禁用 CloudKit（应急方案）

如果急需测试其他功能，可以暂时禁用 CloudKit：

```swift
// 在 AppState.swift 第 101 行修改：
let cloudKitConfig = ModelConfiguration(
    url: storeURL,
    cloudKitDatabase: .none  // 临时禁用 CloudKit
)
```

## 获取帮助

如果以上步骤都无法解决问题，请提供以下信息：

1. **完整的控制台错误日志**（包括 NSError Domain、Code、UserInfo）
2. **截图**：
   - Apple Developer Portal 中的 App ID 配置
   - Xcode Signing & Capabilities 页面
   - 真机设置 → iCloud 页面
3. **环境信息**：
   - iOS 版本
   - Xcode 版本
   - 是否使用个人 Apple Developer 账号（个人/团队/企业）

## 参考文档

- [Apple: Setting Up CloudKit](https://developer.apple.com/documentation/cloudkit/setting_up_cloudkit)
- [Apple: SwiftData with CloudKit](https://developer.apple.com/documentation/swiftdata/adding-swiftdata-to-cloudkit)
- [Apple: Diagnosing Issues Using Crash Reports](https://developer.apple.com/documentation/xcode/diagnosing-issues-using-crash-reports-and-device-logs)
