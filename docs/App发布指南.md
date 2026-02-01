# 📱 简记账 iOS App 发布详细步骤指南

## 目录
1. [准备工作](#准备工作)
2. [创建必需文件](#创建必需文件)
3. [配置 App Store Connect](#配置-app-store-connect)
4. [配置订阅产品](#配置订阅产品)
5. [准备审核材料](#准备审核材料)
6. [构建和上传](#构建和上传)
7. [提交审核](#提交审核)
8. [审核跟踪](#审核跟踪)

---

## 准备工作

### 1. 确认开发者账号

**访问：** https://developer.apple.com/account

**检查项：**
- ✅ Apple Developer Program 已激活
- ✅ 年费已缴纳（$99/年 个人，$299/年 企业）
- ✅ 协议条款已同意
- ✅ 银行/税务信息已填写（用于订阅收入）

**如果还没有账号：**
1. 访问 https://developer.apple.com/programs/enroll/
2. 选择账号类型（个人或企业）
3. 支付年费
4. 等待审核（1-2个工作日）

### 2. 准备资料

**必需信息：**
- [ ] App 名称（30字符以内）：简记账
- [ ] Bundle ID（已有）：com.xxl.jizhang
- [ ] 技术支持邮箱：________@________
- [ ] 技术支持网址（可选）：________
- [ ] 隐私政策网址：________ （见下文如何创建）

---

## 创建必需文件

### 步骤 1: 创建隐私清单文件 ✨

**文件路径：** `jizhang/jizhang/PrivacyInfo.xcprivacy`

**创建方法：**

1. **在 Xcode 中创建：**
   - File → New → File
   - 选择 "App Privacy File"
   - 命名为 `PrivacyInfo.xcprivacy`
   - 保存到 `jizhang/jizhang/` 目录

2. **编辑内容：**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 不进行追踪 -->
    <key>NSPrivacyTracking</key>
    <false/>
    
    <!-- 不使用追踪域名 -->
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    
    <!-- 不收集数据 -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    
    <!-- 使用的系统API -->
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- 文件时间戳访问 -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string> <!-- 用于SwiftData/CoreData -->
            </array>
        </dict>
        
        <!-- UserDefaults访问 -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string> <!-- 访问App自己的UserDefaults -->
            </array>
        </dict>
        
        <!-- 系统启动时间（如果使用） -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>35F9.1</string> <!-- 测量时间 -->
            </array>
        </dict>
    </array>
</dict>
</plist>
```

3. **添加到项目：**
   - 在 Project Navigator 中确认文件已添加
   - 勾选 "jizhang" target
   - ⚠️ 不要勾选 "jizhangWidget" target

### 步骤 2: 创建 StoreKit 配置文件

**文件路径：** `jizhang/Products.storekit`

**创建方法：**

1. **在 Xcode 中创建：**
   - File → New → File
   - 搜索并选择 "StoreKit Configuration File"
   - 命名为 `Products.storekit`
   - 保存到 `jizhang/` 目录（与 xcodeproj 同级）

2. **配置订阅产品：**

在 Xcode 中打开 `Products.storekit`，点击 "+" 添加产品：

**产品 1: 月度订阅**
- Product ID: `jizhang_monthly`
- Product Type: Auto-Renewable Subscription
- Reference Name: 月度订阅
- Price: ¥6.00
- Subscription Duration: 1 Month
- Localization (zh-Hans):
  - Display Name: 月度订阅
  - Description: 解锁所有高级功能，按月订阅

**产品 2: 年度订阅**
- Product ID: `jizhang_yearly`
- Product Type: Auto-Renewable Subscription
- Reference Name: 年度订阅
- Price: ¥48.00
- Subscription Duration: 1 Year
- Localization (zh-Hans):
  - Display Name: 年度订阅
  - Description: 解锁所有高级功能，按年订阅，节省33%

**产品 3: 终身买断（可选）**
- Product ID: `jizhang_lifetime`
- Product Type: Non-Consumable
- Reference Name: 终身版
- Price: ¥98.00
- Localization (zh-Hans):
  - Display Name: 终身买断
  - Description: 一次购买，永久使用所有功能

⚠️ **重要：** Product ID 必须与代码中 `SubscriptionManager.swift` 里的完全一致！

### 步骤 3: 准备 App 图标

**必需尺寸：** 1024x1024 像素

**设计要求：**
- 无圆角（苹果会自动添加）
- 无透明度
- RGB 色彩空间
- PNG 格式

**创建方法：**

1. **设计图标：**
   - 使用 Sketch、Figma 或 Photoshop
   - 主题：记账、账本、金钱相关
   - 颜色：建议使用品牌色

2. **生成所有尺寸：**
   - 访问 https://www.appicon.co
   - 上传 1024x1024 图标
   - 下载生成的 .zip 文件

3. **导入 Xcode：**
   - 打开 `Assets.xcassets`
   - 选择 `AppIcon`
   - 拖拽所有尺寸的图标到对应位置
   - 确保 1024x1024 图标在 "App Store iOS" 位置

### 步骤 4: 准备截图

**必需截图尺寸：**

| 设备 | 尺寸 (像素) | 数量 |
|------|------------|------|
| 6.9" Display (iPhone 16 Pro Max) | 1320 x 2868 | 3-10 |
| 6.7" Display (iPhone 15 Pro Max) | 1290 x 2796 | 3-10 |
| 6.5" Display (iPhone 11 Pro Max) | 1242 x 2688 | 3-10 |
| 5.5" Display (iPhone 8 Plus) | 1242 x 2208 | 3-10 |

**截图内容建议：**

📱 **截图 1: 首页**
- 展示毛玻璃卡片效果
- 显示净资产和今日支出
- 展示账本切换功能

📱 **截图 2: 添加记账**
- 展示分类选择界面
- 显示计算器键盘
- 展示输入金额过程

📱 **截图 3: 统计报表**
- 展示饼图或柱状图
- 显示分类统计
- 展示时间范围选择

📱 **截图 4: 预算管理**
- 展示预算设置
- 显示预算进度
- 展示预警状态

📱 **截图 5: 账本管理**
- 展示多账本列表
- 显示账本切换
- 展示账本统计

**制作截图：**

1. **在模拟器中截图：**
   ```bash
   # 在 Xcode 中运行对应设备的模拟器
   # 使用 Cmd + S 截图
   # 或使用 xcrun simctl io booted screenshot screenshot.png
   ```

2. **添加边框和背景（可选）：**
   - 使用 [Screely](https://screely.com)
   - 使用 [Screenshots.pro](https://screenshots.pro)

3. **添加文字说明（可选）：**
   - 使用 Figma 或 Sketch
   - 添加简短的功能说明文字

### 步骤 5: 创建隐私政策页面

**方法 1: 使用 GitHub Pages（免费）**

1. **创建仓库：**
   - 创建新的 public 仓库: `jizhang-privacy`

2. **创建 index.html：**

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>简记账 - 隐私政策</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            line-height: 1.6;
            color: #333;
        }
        h1 { color: #007AFF; }
        h2 { margin-top: 30px; color: #555; }
        .updated { color: #999; font-size: 14px; }
    </style>
</head>
<body>
    <h1>简记账 - 隐私政策</h1>
    <p class="updated">最后更新：2026年1月31日</p>
    
    <h2>1. 信息收集</h2>
    <p>简记账（以下简称"我们"或"本应用"）承诺保护您的隐私。我们不会收集、存储或分享任何个人身份信息。</p>
    
    <h2>2. 数据存储</h2>
    <p>所有记账数据存储在您的设备本地。如果您选择启用 iCloud 同步功能，数据将存储在您的私人 iCloud 账户中，我们无法访问这些数据。</p>
    
    <h2>3. 数据使用</h2>
    <p>您的记账数据仅用于本应用的功能实现，包括：</p>
    <ul>
        <li>记录和展示收支记录</li>
        <li>生成统计报表</li>
        <li>预算管理和提醒</li>
        <li>在您的多个设备间同步（如果启用 iCloud）</li>
    </ul>
    
    <h2>4. 数据分享</h2>
    <p>我们不会向任何第三方分享、出售或出租您的数据。</p>
    
    <h2>5. iCloud 同步</h2>
    <p>如果您选择启用 iCloud 同步：</p>
    <ul>
        <li>数据通过 Apple 的 iCloud 服务加密传输和存储</li>
        <li>数据仅存储在您的私人 iCloud 账户中</li>
        <li>我们无法访问您的 iCloud 数据</li>
        <li>您可以随时关闭 iCloud 同步</li>
    </ul>
    
    <h2>6. 数据安全</h2>
    <p>我们采取合理的安全措施保护您的数据，包括：</p>
    <ul>
        <li>本地数据加密存储</li>
        <li>iCloud 数据加密传输</li>
        <li>定期安全更新</li>
    </ul>
    
    <h2>7. 儿童隐私</h2>
    <p>本应用不针对13岁以下的儿童。我们不会故意收集13岁以下儿童的个人信息。</p>
    
    <h2>8. 您的权利</h2>
    <p>您拥有以下权利：</p>
    <ul>
        <li>随时导出您的所有数据</li>
        <li>随时删除您的所有数据</li>
        <li>关闭 iCloud 同步</li>
        <li>删除应用及所有相关数据</li>
    </ul>
    
    <h2>9. 政策更新</h2>
    <p>我们可能会不定期更新本隐私政策。更新后的政策将在本页面发布，并在应用中通知您。</p>
    
    <h2>10. 联系我们</h2>
    <p>如果您对本隐私政策有任何疑问或建议，请联系我们：</p>
    <p>邮箱：your-email@example.com</p>
    
    <hr>
    <p style="text-align: center; color: #999; margin-top: 40px;">
        © 2026 简记账. 保留所有权利.
    </p>
</body>
</html>
```

3. **启用 GitHub Pages：**
   - 仓库设置 → Pages
   - Source: Deploy from a branch
   - Branch: main / root
   - 保存后获得URL: `https://yourusername.github.io/jizhang-privacy/`

**方法 2: 使用 Notion（免费）**
- 在 Notion 创建页面
- 填写隐私政策内容
- 点击"Share" → "Share to web"
- 获取公开链接

### 步骤 6: 修改生产环境配置

**修改 Entitlements：**

打开 `jizhang/jizhang/jizhang.entitlements`，修改：

```xml
<key>aps-environment</key>
<string>production</string>
```

或在 Xcode 中：
1. 选择 jizhang target
2. Signing & Capabilities 标签
3. Push Notifications
4. Environment: Production

---

## 配置 App Store Connect

### 步骤 1: 登录并创建 App

1. **访问：** https://appstoreconnect.apple.com

2. **创建新 App：**
   - 点击"我的App" → "+" → "新建App"
   - 填写信息：
     - 平台：iOS
     - 名称：简记账
     - 主要语言：简体中文
     - 套装ID：com.xxl.jizhang
     - SKU：jizhang_ios_001（自定义，但必须唯一）
     - 用户访问权限：完全访问权限

### 步骤 2: 填写 App 信息

**1. App 信息（左侧菜单）：**

- **名称：** 简记账
- **副标题：** 简洁优雅的记账工具
- **隐私政策URL：** https://yourusername.github.io/jizhang-privacy/

**2. 价格与销售范围：**

- **价格：** 免费
- **销售范围：** 所有地区（或选择特定地区）

**3. App Store 信息：**

**类别：**
- 主要类别：财务
- 次要类别：效率（可选）

**App Store 展示：**

*描述（最多4000字符）：*
```
简记账 - 简洁优雅的记账工具

【核心功能】
✓ 快速记账 - 简洁的界面，快速记录每笔收支
✓ 智能分类 - 丰富的分类图标，个性化定制
✓ 多账本管理 - 工作、生活分开记账，互不干扰
✓ 预算管理 - 设置预算目标，实时监控支出
✓ 统计报表 - 可视化图表，了解消费趋势
✓ iCloud 同步 - 多设备无缝同步，数据永不丢失
✓ 小组件支持 - 桌面一览，快速查看今日支出
✓ Siri 快捷指令 - 语音记账，解放双手

【设计理念】
现代毛玻璃设计风格，优雅而不失实用。我们相信，记账应该是一件轻松愉悦的事情。

【隐私保护】
✓ 所有数据存储在您的设备和私人 iCloud 中
✓ 我们不会收集任何个人信息
✓ 不含广告，不追踪用户行为
✓ 完全离线可用

【高级功能】（需要订阅）
✓ 自定义账户管理
✓ 自定义分类管理
✓ 数据导入导出
✓ 对比分析报表
✓ 趋势分析报表
✓ 账户统计

【订阅说明】
• 月度订阅：¥6/月
• 年度订阅：¥48/年（节省33%）
• 终身买断：¥98（一次购买，永久使用）

【联系我们】
如有任何问题或建议，欢迎通过 App 内的反馈功能联系我们。

让记账变得简单而优雅。
```

*关键词（最多100字符，逗号分隔）：*
```
记账,账本,预算,理财,支出,收入,财务,管理,统计,账单
```

*技术支持网址：* （选填）
```
https://github.com/yourusername/jizhang_ios
```

*营销网址：* （选填）

**4. 年龄分级：**

点击"编辑" → 完成问卷

一般答案：
- 不频繁/强烈的卡通或幻想暴力：无
- 不频繁/强烈的现实暴力：无
- 不频繁/强烈的性暗示或裸露内容：无
- 亵渎或粗俗幽默：无
- 酒精、烟草或毒品：无
- 赌博与竞赛：无
- 恐怖/惊悚主题：无
- 医疗/治疗信息：无

结果一般是：4+

**5. App 预览和截图：**

- 上传步骤4准备的截图（每个尺寸至少3张）
- 可选：上传 App 预览视频

---

## 配置订阅产品

### 步骤 1: 创建订阅群组

1. **进入：** App Store Connect → 您的App → 功能 → App内购买项目

2. **创建订阅群组：**
   - 点击 "+" → "订阅群组"
   - 参考名称：简记账高级版
   - 群组显示名称（zh-Hans）：高级版订阅

### 步骤 2: 添加订阅产品

**产品 1: 月度订阅**

1. 点击订阅群组 → "+" → "创建订阅"
2. 填写信息：
   - **产品ID：** `jizhang_monthly`（必须与代码一致！）
   - **参考名称：** 月度订阅
   - **订阅时长：** 1个月
3. 订阅价格：
   - 点击 "+"
   - 选择价格：¥6.00（或选择价格段）
4. 本地化信息（zh-Hans）：
   - **显示名称：** 月度订阅
   - **描述：** 解锁所有高级功能，按月自动续订

**产品 2: 年度订阅**

重复上述步骤：
- **产品ID：** `jizhang_yearly`
- **订阅时长：** 1年
- **价格：** ¥48.00
- **显示名称：** 年度订阅
- **描述：** 解锁所有高级功能，按年自动续订，节省33%

**产品 3: 终身买断（可选）**

⚠️ 注意：终身买断是"非消耗型项目"，不是订阅

1. 返回"App内购买项目"页面
2. 点击 "+" → "非消耗型"
3. 填写信息：
   - **产品ID：** `jizhang_lifetime`
   - **参考名称：** 终身版
   - **价格：** ¥98.00
   - **显示名称：** 终身买断
   - **描述：** 一次购买，永久使用所有高级功能

### 步骤 3: 配置订阅定价

**设置优惠价格（可选）：**
- 首次订阅优惠
- 推广优惠
- 优惠代码

**设置家庭共享（可选）：**
- 勾选"家庭共享"
- 允许家庭成员共享订阅

---

## 准备审核材料

### 审核信息

**1. 登录信息（如果需要）：**
- 演示账号：demo@example.com
- 演示密码：demo123456
- 说明：无需登录，App 本地运行

**2. 联系信息：**
- 姓名：您的姓名
- 电话：+86 138xxxx8888
- 邮箱：your-email@example.com

**3. 备注（可选但推荐）：**

```
审核说明：

1. 核心功能
   - App 为本地记账工具，无需注册登录
   - 所有数据存储在设备本地和用户的 iCloud 中
   - 首次启动会创建默认账本

2. 订阅功能
   - 基础记账功能免费
   - 高级功能（自定义分类、账户、导出等）需要订阅
   - 在沙盒环境测试时，请使用测试账号购买
   - 订阅产品ID：jizhang_monthly, jizhang_yearly

3. iCloud 功能
   - 需要在设置中启用 iCloud 同步
   - 需要登录 iCloud 账号
   - 同步功能需要网络连接

4. Siri 快捷指令
   - 在"快捷指令" App 中搜索"简记账"
   - 可添加"添加支出"、"查询今日支出"等快捷指令
   - 需要授予 Siri 权限

5. 小组件
   - 在主屏幕长按，选择"简记账"小组件
   - 提供 Small、Medium、Large 三种尺寸

感谢审核！
```

---

## 构建和上传

### 步骤 1: 清理和构建

1. **清理项目：**
   - Product → Clean Build Folder（⌘ + Shift + K）

2. **选择目标：**
   - 顶部选择 "Any iOS Device (arm64)"
   - 确保不是模拟器

3. **编译：**
   - Product → Build（⌘ + B）
   - 确保无错误

### 步骤 2: Archive

1. **创建 Archive：**
   - Product → Archive
   - 等待编译完成（可能需要几分钟）

2. **检查 Archive：**
   - 编译成功后会自动打开 Organizer
   - 查看新创建的 Archive
   - 确认版本号和构建号正确

### 步骤 3: 上传到 App Store Connect

1. **在 Organizer 中：**
   - 选择刚创建的 Archive
   - 点击 "Distribute App"

2. **选择发布方式：**
   - 选择 "App Store Connect"
   - 点击 "Next"

3. **选择发布选项：**
   - 选择 "Upload"
   - 点击 "Next"

4. **发布选项：**
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number（自动管理版本号）
   - 点击 "Next"

5. **代码签名：**
   - 选择 "Automatically manage signing"
   - 点击 "Next"

6. **审核构建信息：**
   - 确认所有信息正确
   - 点击 "Upload"

7. **等待上传：**
   - 上传可能需要5-20分钟
   - 保持网络连接
   - 上传完成后会收到邮件通知

### 步骤 4: 等待处理

1. **回到 App Store Connect：**
   - App → TestFlight（或App Store）标签
   - 查看构建版本状态

2. **构建版本处理状态：**
   - 正在处理：⏳ 通常需要 10-30 分钟
   - 准备提交：✅ 可以提交审核了
   - 无效二进制文件：❌ 需要修复问题后重新上传

3. **检查处理警告：**
   - 如果收到邮件警告，查看并修复
   - 常见警告：缺少截图、隐私信息等

---

## 提交审核

### 步骤 1: 选择构建版本

1. **返回 App Store Connect**
2. **进入：** 您的App → App Store 标签
3. **点击：** "+" 或 "准备提交"
4. **版本信息：**
   - 版本号：1.0.0
   - 此版本中的新功能：
     ```
     首次发布！

     【主要功能】
     • 快速记账：简洁易用的记账界面
     • 智能分类：丰富的图标和自定义分类
     • 多账本管理：工作生活分开记账
     • 预算管理：设置预算，控制支出
     • 统计报表：可视化图表分析
     • iCloud 同步：多设备无缝同步
     • 小组件：桌面快速查看
     • Siri 快捷指令：语音记账

     感谢您的下载和使用！
     ```

5. **选择构建版本：**
   - 点击 "构建版本" 旁的 "+"
   - 选择刚上传的构建版本
   - 点击 "完成"

### 步骤 2: 填写审核信息

**1. 版权：**
```
2026 Your Name
```

**2. 路由 App 覆盖文件：** 不适用

**3. 登录信息：** 
- 如果不需要登录，选择"否"

**4. 联系信息：**
- 填写真实的联系方式
- 审核团队可能会联系您

**5. 备注：**
- 粘贴之前准备的审核说明

**6. 版本发布：**
- 推荐：批准后自动发布
- 或：批准后手动发布

### 步骤 3: 回答问卷

**1. 广告标识符 (IDFA)：**
- 问：此App使用广告标识符吗？
- 答：否（如果您没有集成广告）

**2. 内容权利：**
- 确认您拥有 App 中所有内容的权利

**3. 出口合规性：**
- 问：您的 App 使用加密吗？
- 答：否（使用系统标准加密）
- 或：是 → 选择"仅使用 Apple 提供的加密"

### 步骤 4: 提交审核

1. **最终检查：**
   - ✅ 所有必填项已填写
   - ✅ 构建版本已选择
   - ✅ 截图已上传
   - ✅ 描述完整准确
   - ✅ 订阅产品已配置

2. **点击：** 右上角 "提交审核"

3. **确认提交：**
   - 阅读并同意条款
   - 点击 "提交"

4. **等待审核：**
   - 状态变为"正在等待审核"
   - 通常 1-3 个工作日进入审核
   - 审核时间通常 24-48 小时

---

## 审核跟踪

### 审核状态说明

**1. 正在等待审核（Waiting For Review）**
- App 已提交，等待审核团队处理
- 这个阶段可能持续几小时到几天

**2. 正在审核（In Review）**
- 审核团队正在测试您的 App
- 通常持续 24-48 小时
- 这个阶段不要修改 App Store Connect 的信息

**3. 待开发者发布（Pending Developer Release）**
- ✅ 审核通过！
- 如果选择了"手动发布"，需要手动点击发布
- 如果选择了"自动发布"，将在几小时内上架

**4. 被拒绝（Rejected）**
- ❌ 审核未通过
- 查看拒绝原因
- 修复问题后重新提交

**5. 开发者已移除（Developer Removed from Sale）**
- 您主动撤回了提交
- 可以修改后重新提交

### 常见被拒原因及解决方案

**1. 崩溃或严重Bug**
- **原因：** 审核时 App 崩溃
- **解决：** 充分测试，修复 Bug 后重新提交

**2. 功能不完整**
- **原因：** 某些功能无法使用或显示"即将推出"
- **解决：** 确保所有展示的功能都可用

**3. 元数据不准确**
- **原因：** 描述或截图与实际功能不符
- **解决：** 确保描述和截图准确反映 App

**4. 订阅说明不清**
- **原因：** 未清楚说明订阅功能和费用
- **解决：** 在 App 内和描述中清楚说明订阅详情

**5. 隐私政策问题**
- **原因：** 隐私政策缺失或不符合要求
- **解决：** 提供完整准确的隐私政策

**6. 性能问题**
- **原因：** App 启动慢或界面卡顿
- **解决：** 优化性能

### 审核沟通

**如果被拒绝：**

1. **仔细阅读拒绝原因：**
   - 在 App Store Connect 查看详细说明
   - 通常会提供截图和具体问题

2. **修复问题：**
   - 根据反馈修复所有问题
   - 重新测试确保问题已解决

3. **回复审核团队：**
   - 在"解决方案中心"回复
   - 说明您做了哪些修复
   - 如有疑问，可以请求澄清

4. **重新提交：**
   - 如果需要修改代码，上传新的构建版本
   - 如果只是说明问题，可以直接回复并重新提交

**紧急审核申请：**
- 如果有紧急bug修复，可以申请加急审核
- 在"版本信息"页面申请
- 说明紧急原因

---

## 🎉 发布成功后

### 上架后的工作

**1. 监控反馈：**
- 每天查看 App Store 评价
- 及时回复用户评论
- 收集功能建议

**2. 跟踪数据：**
- App Store Connect Analytics
- 下载量、销售额、用户留存率
- 崩溃和错误报告

**3. 准备更新：**
- 修复用户反馈的问题
- 添加新功能
- 优化性能

**4. 营销推广：**
- 社交媒体宣传
- Product Hunt 发布
- 开发者社区分享
- App Store 关键词优化（ASO）

**5. 用户支持：**
- 及时回复用户邮件
- 提供使用指南
- 建立用户社群

### 版本更新流程

**准备更新：**
1. 修改代码
2. 更新版本号（如 1.0.1）
3. 递增构建号（如 2）
4. 测试新版本
5. Archive 并上传
6. 填写"此版本中的新功能"
7. 提交审核

**更新说明示例：**
```
版本 1.0.1 更新内容：

【修复】
• 修复了某些情况下数据同步失败的问题
• 修复了预算进度显示不准确的问题
• 优化了 App 启动速度

【改进】
• 优化了统计图表的显示效果
• 改进了小组件的数据更新机制

感谢您的支持和反馈！
```

---

## 📞 寻求帮助

### 官方资源

- **App Store Connect 帮助：** https://help.apple.com/app-store-connect/
- **App Store 审核指南：** https://developer.apple.com/app-store/review/guidelines/
- **开发者论坛：** https://developer.apple.com/forums/
- **技术支持：** https://developer.apple.com/contact/

### 常见问题

**Q: 审核需要多久？**
A: 通常 1-3 天，但可能更快或更慢。节假日可能延长。

**Q: 可以撤回提交吗？**
A: 在"正在等待审核"状态时可以撤回。一旦进入"正在审核"状态，无法撤回。

**Q: 被拒后重新提交需要多久？**
A: 修复问题后立即可以重新提交，审核队列优先级不变。

**Q: 可以修改价格吗？**
A: 可以，在 App Store Connect 的"价格与销售范围"中修改，生效需要 24 小时。

**Q: 如何处理用户差评？**
A: 礼貌回复，解释问题并说明改进措施。可以请求用户在问题解决后修改评价。

---

## ✅ 最终核对清单

**发布前最后检查：**

- [ ] ✅ 开发者账号有效
- [ ] ✅ App Store Connect App 已创建
- [ ] ✅ App 图标已准备（1024x1024）
- [ ] ✅ 截图已准备（所有尺寸）
- [ ] ✅ 隐私政策URL已准备
- [ ] ✅ 隐私清单文件已创建
- [ ] ✅ StoreKit 配置已创建
- [ ] ✅ 订阅产品已配置
- [ ] ✅ aps-environment 改为 production
- [ ] ✅ 所有功能测试通过
- [ ] ✅ 无崩溃或严重bug
- [ ] ✅ App 描述和关键词已填写
- [ ] ✅ 审核说明已准备
- [ ] ✅ 联系信息已填写
- [ ] ✅ Archive 已创建并上传
- [ ] ✅ 构建版本处理完成
- [ ] ✅ 所有必填信息已完成
- [ ] ✅ 最终检查无误

**全部完成后 → 点击"提交审核"**

---

**祝您发布顺利！** 🚀🎉

如有任何问题，请参考本文档或联系 Apple Developer Support。
