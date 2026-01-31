# Siri 快捷指令使用指南

## 📱 修复说明

### 问题原因
"简记账还不支持此操作" 错误是因为：
1. Info.plist 缺少 Siri 权限配置
2. App Shortcuts 未正确注册到系统
3. AppShortcuts 数组格式错误

### 已修复内容

#### 1. Info.plist 配置
添加了以下配置：
- `NSSiriUsageDescription`: Siri 使用说明
- `NSUserActivityTypes`: 支持的用户活动类型
- `INIntentsSupported`: 支持的 Intent 列表
- `INIntentsRestrictedWhileLocked`: 锁屏限制（空数组表示不限制）
- `INIntentsRestrictedWhileProtectedDataUnavailable`: 数据保护限制

#### 2. jizhangApp.swift
添加了 App Shortcuts 初始化：
```swift
init() {
    if #available(iOS 16.0, *) {
        LuminaShortcuts.updateAppShortcutParameters()
    }
}
```

#### 3. AppShortcuts.swift
修复了数组格式问题，将多个 AppShortcut 正确放入数组中。

---

## 🚀 测试步骤

### 第一步：完全卸载旧版本
**重要！** 必须完全删除旧版本：
1. 长按 App 图标 → 删除 App
2. 在设置中搜索"简记账"，删除所有相关数据
3. 重启 iPhone（可选但推荐）

### 第二步：重新安装
1. 在 Xcode 中 Clean Build Folder (Cmd + Shift + K)
2. 重新 Build 并安装到真机
3. 首次打开 App，创建账本和账户

### 第三步：验证 Shortcuts 注册
1. 打开"快捷指令" App
2. 点击右上角"+"新建快捷指令
3. 搜索"简记账"，应该能看到三个动作：
   - ✅ 记一笔支出
   - ✅ 查询今日支出
   - ✅ 查询本月预算

### 第四步：测试 Siri
尝试以下命令：

#### 测试 1：记一笔支出
```
"Hey Siri，在简记账记一笔"
```
- Siri 会提示输入金额
- 可选择分类和备注
- 成功后会显示"已记录支出 ¥XX"

#### 测试 2：查看今日支出
```
"Hey Siri，在简记账查看今日支出"
或
"Hey Siri，简记账今天花了多少"
```
- Siri 会返回今日支出总额和笔数

#### 测试 3：查询预算
```
"Hey Siri，在简记账查看预算"
或
"Hey Siri，简记账预算情况"
```
- Siri 会返回本月预算使用情况

---

## 🔧 调试技巧

### 如果还是提示"不支持此操作"

1. **检查 iOS 版本**
   - 需要 iOS 16.0 或更高版本
   - App Intents 不支持 iOS 15 及以下

2. **检查 Xcode 控制台**
   ```
   // 查找 App Intents 相关日志
   ExtractAppIntentsMetadata
   appintentsmetadataprocessor
   ```

3. **检查 App Bundle**
   - 确认 `Metadata.appintents` 文件被正确生成
   - 路径：`jizhang.app/Metadata.appintents`

4. **重启设备**
   - 有时 iOS 系统缓存会导致问题
   - 完全重启可以刷新 Siri 索引

5. **检查隐私权限**
   - 设置 → Siri 与搜索
   - 找到"简记账"
   - 确保"从此 App 学习"已开启

### 查看 App Intents 日志
在 Xcode 控制台筛选以下关键词：
```
AppIntents
Intent
Shortcuts
Siri
```

### 手动触发 Shortcuts 更新
```swift
// 在 App 启动时手动更新
Task {
    await LuminaShortcuts.updateAppShortcutParameters()
}
```

---

## 📝 支持的语音命令

### 记账类
- "在简记账记一笔"
- "用简记账添加支出"
- "打开简记账记账"

### 查询类
- "在简记账查看今日支出"
- "用简记账查看今天花了多少"
- "简记账今日花费"
- "在简记账查看预算"
- "用简记账查询预算"
- "简记账预算情况"

---

## 🎯 进阶功能

### 创建自定义快捷指令
用户可以在"快捷指令" App 中：
1. 创建新快捷指令
2. 添加"记一笔支出"动作
3. 预设金额、分类、备注
4. 添加到主屏幕或设置自动化

### 示例：早餐快捷指令
1. 打开快捷指令 App
2. 新建快捷指令
3. 添加"记一笔支出"
   - 金额：30
   - 分类：餐饮
   - 备注：早餐
4. 命名为"记早餐"
5. 添加到主屏幕

以后只需说："Hey Siri，记早餐"，就会自动记录一笔 30 元的餐饮支出。

---

## ⚠️ 常见问题

### Q: 为什么 Siri 无法识别我的命令？
A: 
1. 确保使用完整的 App 名称"简记账"
2. 语音命令需要包含"在...记一笔"等固定格式
3. 如果识别率低，可以在快捷指令 App 中手动创建

### Q: 能否直接说"记一笔午饭 30 元"？
A: 
当前版本不支持完全自然语言解析。需要通过以下方式：
1. 说"在简记账记一笔"
2. Siri 提示输入金额时再说"30"
3. 或在快捷指令 App 中预设参数

### Q: 锁屏状态下能用吗？
A: 
可以！配置中已设置 `INIntentsRestrictedWhileLocked` 为空数组，允许锁屏使用。

### Q: 需要付费吗？
A: 
完全免费！App Intents 是 iOS 系统级功能，无需订阅或付费。

---

## 🔄 版本兼容性

| iOS 版本 | 支持状态 | 说明 |
|---------|---------|------|
| iOS 17+ | ✅ 完全支持 | 推荐版本 |
| iOS 16.0-16.6 | ✅ 完全支持 | 最低要求 |
| iOS 15 及以下 | ❌ 不支持 | 需要升级系统 |

---

## 📚 开发参考

- [Apple App Intents 文档](https://developer.apple.com/documentation/appintents)
- [App Shortcuts 指南](https://developer.apple.com/documentation/appintents/app-shortcuts)
- [Siri 最佳实践](https://developer.apple.com/design/human-interface-guidelines/siri)
