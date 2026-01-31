# 📱 简记账 iOS App 发布准备清单

## 📋 发布前检查状态

根据代码分析，当前项目状态如下：

### ✅ 已完成项

#### 1. 基础配置
- ✅ Bundle ID: `com.xxl.jizhang`
- ✅ 版本号: `1.0.0` (MARKETING_VERSION)
- ✅ 构建号: `1` (CURRENT_PROJECT_VERSION)
- ✅ Info.plist 配置完整
- ✅ Entitlements 配置完整

#### 2. 核心功能
- ✅ 记账核心功能
- ✅ 账本管理（支持多账本）
- ✅ 分类管理
- ✅ 账户管理
- ✅ 预算管理
- ✅ 统计报表
- ✅ 标签系统
- ✅ 数据导入/导出

#### 3. iCloud 同步
- ✅ CloudKit 集成
- ✅ 容器ID配置: `iCloud.com.xxl.jizhang`
- ✅ App Group: `group.com.xxl.jizhang`
- ✅ 推送通知配置
- ✅ 同步状态显示

#### 4. Widget 小组件
- ✅ 小组件实现（Small、Medium、Large）
- ✅ 数据共享配置
- ✅ Widget Extension配置

#### 5. Siri 快捷指令
- ✅ App Intents 实现
  - AddExpenseIntent (添加支出)
  - GetTodayExpenseIntent (查询今日支出)
  - GetBudgetIntent (查询预算)
- ✅ Siri 权限配置
- ✅ NSUserActivityTypes 配置

#### 6. 订阅系统
- ✅ StoreKit 2 集成
- ✅ 订阅管理器实现
- ✅ 功能权限控制
- ✅ 订阅状态UI

#### 7. 测试
- ✅ 单元测试框架
- ✅ UI测试框架
- ✅ 模型测试
- ✅ 真机测试通过

---

## ⚠️ 需要处理的事项

### 🔴 必须处理（发布前必做）

#### 1. Apple Developer 账号准备

**操作步骤：**
1. 登录 [Apple Developer](https://developer.apple.com)
2. 确认开发者账号状态
   - [ ] 个人账号 ($99/年) 或企业账号 ($299/年)
   - [ ] 账号已激活且付费有效
   - [ ] 同意最新的协议条款

#### 2. App Store Connect 配置

**创建 App 记录：**
1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 点击"我的App" → "+" → "新建App"
3. 填写基本信息：
   - [ ] **平台**: iOS
   - [ ] **名称**: 简记账（或您想要的App名称）
   - [ ] **主要语言**: 简体中文
   - [ ] **套装ID**: `com.xxl.jizhang`
   - [ ] **SKU**: `jizhang_ios_001`（唯一标识，可自定义）

#### 3. App 图标（AppIcon）

**问题：** 根据git状态，删除了两个图标文件：
- AppIcon-Dark.png
- AppIcon-Tinted.png

**需要准备：**
- [ ] 1024x1024 App Store 用图标
- [ ] 所有尺寸的 App 图标（Xcode会自动生成，但建议准备完整）
- [ ] 确保图标符合苹果设计规范

**创建图标：**
1. 设计1024x1024的App图标
2. 使用 [App Icon Generator](https://appicon.co) 生成所有尺寸
3. 在 Xcode 中导入到 `Assets.xcassets/AppIcon.appiconset/`

#### 4. App 截图和预览

**必需的截图尺寸：**
- [ ] **6.9英寸显示屏** (iPhone 16 Pro Max): 1320 x 2868 像素
- [ ] **6.7英寸显示屏** (iPhone 15 Pro Max): 1290 x 2796 像素
- [ ] **6.5英寸显示屏** (iPhone 11 Pro Max): 1242 x 2688 像素
- [ ] **5.5英寸显示屏** (iPhone 8 Plus): 1242 x 2208 像素

**截图内容建议：**（每个尺寸至少3张，最多10张）
1. 首页 - 展示毛玻璃卡片和记账界面
2. 添加记账 - 展示计算器键盘和分类选择
3. 统计报表 - 展示图表和数据
4. 账本管理 - 展示多账本功能
5. 预算管理 - 展示预算设置和进度

**App 预览视频**（可选但推荐）：
- [ ] 15-30秒的App演示视频
- [ ] 竖屏录制
- [ ] 展示核心功能

#### 5. App Store 商品信息

**必填信息：**
- [ ] **App名称**: 简记账（30个字符以内）
- [ ] **副标题**: 简洁易用的记账工具（30个字符以内）
- [ ] **描述**: 详细的App描述（最多4000字符）
- [ ] **关键词**: 记账,账本,预算,理财,支出,收入（最多100字符，逗号分隔）
- [ ] **技术支持网址**: 您的网站或GitHub地址
- [ ] **营销网址**: 可选

**分类：**
- [ ] **主要类别**: 财务
- [ ] **次要类别**: 效率（可选）

**年龄分级：**
- [ ] 完成年龄分级问卷（一般选择"4+"）

#### 6. 隐私政策

**必须提供：**
- [ ] 隐私政策URL（必填）
- [ ] 数据收集说明

**建议内容：**
```
简记账隐私政策

1. 数据收集
   - 我们不收集任何个人信息
   - 所有记账数据存储在您的设备本地
   - 如果启用iCloud同步，数据存储在您的私人iCloud账户中

2. 数据使用
   - 数据仅用于App功能
   - 不与第三方共享
   - 不用于广告或分析

3. 数据安全
   - 数据通过iCloud加密传输和存储
   - 您可以随时删除所有数据

联系方式：[您的邮箱]
```

#### 7. 隐私清单文件（Privacy Manifest）

**⚠️ 重要：iOS 17+要求**

**需要创建：** `PrivacyInfo.xcprivacy`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

#### 8. StoreKit 配置文件

**需要创建：** StoreKit Configuration 文件

**操作步骤：**
1. 在 Xcode 中: File → New → File
2. 选择"StoreKit Configuration File"
3. 命名为 `Products.storekit`
4. 配置订阅产品（与 App Store Connect 中的产品ID一致）

**订阅产品建议：**
```
产品1: 月度订阅
- Product ID: jizhang_monthly
- 价格: ¥6/月
- 功能: 所有高级功能

产品2: 年度订阅
- Product ID: jizhang_yearly  
- 价格: ¥48/年（相当于¥4/月，节省33%）
- 功能: 所有高级功能

产品3: 终身买断（可选）
- Product ID: jizhang_lifetime
- 价格: ¥98 一次性购买
- 功能: 所有高级功能，永久使用
```

#### 9. 代码签名和证书

**操作步骤：**
1. 在 Xcode 中打开项目
2. 选择 jizhang target
3. Signing & Capabilities 标签
   - [ ] 勾选"Automatically manage signing"
   - [ ] 选择您的 Team（开发者账号）
   - [ ] 验证 Provisioning Profile 生成成功

**检查所有 Targets：**
- [ ] jizhang (主应用)
- [ ] jizhangWidget (小组件)
- [ ] jizhangTests (测试，不需要发布)
- [ ] jizhangUITests (UI测试，不需要发布)

#### 10. 生产环境配置

**修改 Entitlements：**

当前 `jizhang.entitlements` 中有：
```xml
<key>aps-environment</key>
<string>development</string>
```

**发布前需要改为：**
```xml
<key>aps-environment</key>
<string>production</string>
```

或者在 Xcode 的 Signing & Capabilities 中：
- Push Notifications → Environment → Production

#### 11. 版本号更新

**当前版本：**
- Version: 1.0.0
- Build: 1

**建议：**
首次发布保持 1.0.0，后续更新递增：
- 主要更新: 2.0.0
- 功能更新: 1.1.0
- Bug修复: 1.0.1
- Build号每次提交递增: 1, 2, 3...

#### 12. App Store Connect 中配置订阅

**创建订阅群组：**
1. App Store Connect → 您的App → 功能 → App内购买项目
2. 创建订阅群组: "简记账高级版"
3. 添加订阅产品（与代码中的Product ID一致）:
   - `jizhang_monthly` - 月度订阅
   - `jizhang_yearly` - 年度订阅
   - `jizhang_lifetime` - 终身版（一次性购买，需要创建为"非消耗型项目"）

**配置每个产品：**
- [ ] 产品ID（必须与代码中完全一致）
- [ ] 参考名称
- [ ] 订阅价格
- [ ] 产品描述
- [ ] App Store 本地化信息

### 🟡 建议处理（提升用户体验）

#### 1. 本地化（多语言支持）

**当前状态：** 仅支持简体中文

**建议添加：**
- [ ] 英语（拓展国际市场）
- [ ] 繁体中文（港澳台市场）

**操作步骤：**
1. Xcode → Project → Localizations
2. 添加新语言
3. 导出本地化字符串: Editor → Export for Localization
4. 翻译 .xliff 文件
5. 导入翻译: Editor → Import Localizations

#### 2. 深色模式适配

**检查项：**
- [ ] 所有界面支持深色模式
- [ ] 颜色在深色模式下清晰可读
- [ ] 图标在深色模式下显示正常

#### 3. iPad 适配

**当前状态：** 主要为 iPhone 设计

**建议：**
- [ ] 适配 iPad 布局
- [ ] 提供 iPad 截图
- [ ] 支持多任务处理

#### 4. 可访问性（Accessibility）

**建议添加：**
- [ ] VoiceOver 标签
- [ ] 动态字体支持
- [ ] 增强对比度支持
- [ ] 减少动画选项

#### 5. 性能优化

**测试项：**
- [ ] App启动时间 < 2秒
- [ ] 界面滑动流畅（60fps）
- [ ] 大量数据加载性能
- [ ] 内存占用合理

#### 6. 崩溃和错误监控

**建议集成：**
- [ ] Crashlytics（Firebase）
- [ ] 或其他崩溃分析工具

#### 7. App 推广素材

**准备：**
- [ ] App 宣传图（可用于社交媒体）
- [ ] 功能介绍视频
- [ ] 新闻稿或博客文章
- [ ] App Store 推广代码

### 🟢 可选项（长期规划）

#### 1. TestFlight 内测

**好处：**
- 收集真实用户反馈
- 发现潜在问题
- 提高首发质量

**步骤：**
1. 上传构建版本到 App Store Connect
2. 提交到 TestFlight
3. 邀请测试用户（最多10000人）
4. 收集反馈并改进

#### 2. App 审核准备

**常见被拒原因：**
- 崩溃或严重bug
- 功能不完整或无法使用
- 隐私政策缺失或不当
- 订阅价格描述不清
- 元数据（描述、截图）误导

**规避建议：**
- 充分测试
- 准备完整的审核说明
- 提供测试账号（如有需要）
- 清晰说明订阅功能

#### 3. App 分析

**建议配置：**
- [ ] App Store Connect 分析
- [ ] 自定义事件追踪（合规前提下）

#### 4. 营销计划

**考虑：**
- Product Hunt 发布
- 社交媒体推广
- App Store 关键词优化（ASO）
- 用户评价和评分策略

---

## 📝 发布前最终核对清单

### 代码层面
- [ ] 所有功能正常工作
- [ ] 没有测试/调试代码残留
- [ ] 没有控制台警告或错误
- [ ] 通过所有单元测试
- [ ] 真机测试通过
- [ ] aps-environment 改为 production
- [ ] 版本号和构建号正确

### 资源层面
- [ ] App 图标完整
- [ ] 所有必需的截图已准备
- [ ] 隐私清单文件已创建
- [ ] StoreKit 配置文件已创建
- [ ] 所有资源文件已添加到项目

### App Store Connect
- [ ] App 记录已创建
- [ ] 商品信息已完整填写
- [ ] 截图和描述已上传
- [ ] 订阅产品已配置
- [ ] 隐私政策URL已填写
- [ ] 年龄分级已完成
- [ ] App 分类已选择

### 证书和签名
- [ ] 开发者账号有效
- [ ] 代码签名配置正确
- [ ] Push Notifications 证书已配置（生产环境）
- [ ] 所有 Capabilities 已启用

### 审核准备
- [ ] 审核说明已准备
- [ ] 测试账号已准备（如需要）
- [ ] 联系方式有效
- [ ] 准备好快速响应审核团队

---

## ⏭️ 下一步行动

建议按以下顺序处理：

1. **立即处理（今天）**
   - 创建隐私清单文件
   - 设计并导入 App 图标
   - 准备隐私政策页面

2. **本周完成**
   - 截图所有必需尺寸
   - 填写 App Store Connect 信息
   - 配置订阅产品
   - 修改 aps-environment 为 production

3. **下周完成**
   - TestFlight 内测（可选）
   - 根据反馈优化
   - 准备审核材料

4. **提交审核**
   - 最终测试
   - 上传构建版本
   - 提交审核

---

## 📞 技术支持联系

如果在发布过程中遇到问题，可以：
- 查看 [Apple Developer 文档](https://developer.apple.com/documentation/)
- 访问 [Apple Developer 论坛](https://developer.apple.com/forums/)
- 联系 Apple Developer Support

---

**预计时间线：** 如果全力准备，约需 1-2 周完成所有必需项，2-4 周包含内测和优化。

**祝发布顺利！** 🚀
