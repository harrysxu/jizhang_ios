# 📱 简记账

> 基于 SwiftUI + SwiftData 构建的现代化个人记账应用

[![Platform](https://img.shields.io/badge/platform-iOS%2017.6%2B-lightgrey?style=flat-square)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-blue?style=flat-square)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/SwiftData-1.0-green?style=flat-square)](https://developer.apple.com/xcode/swiftdata/)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

<p align="center">
  <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.05_resized.png" width="200">
  <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.13_resized.png" width="200">
  <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.20_resized.png" width="200">
  <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.28_resized.png" width="200">
</p>

---

## 📑 目录

- [简介](#简介)
- [✨ 核心特性](#-核心特性)
- [📸 应用截图](#-应用截图)
- [🏗️ 技术架构](#️-技术架构)
- [🚀 快速开始](#-快速开始)
- [📚 开发文档](#-开发文档)
- [🧪 测试](#-测试)
- [🔐 隐私与安全](#-隐私与安全)
- [🤝 贡献指南](#-贡献指南)
- [🎯 开发路线图](#-开发路线图)
- [📝 反馈与支持](#-反馈与支持)
- [📄 许可证](#-许可证)

---

## 简介

简记账是一款专为个人财务管理设计的 iOS 应用，采用现代化的 SwiftUI 框架和 SwiftData 持久化技术构建。应用秉承"简洁而不简单"的设计理念，提供快速记账、智能统计、预算管理等核心功能，同时注重用户隐私保护。

## ✨ 核心特性

### 📊 完整的财务管理体系

- **多账本管理** - 支持创建多个独立账本，工作、生活、旅行分开记账
- **多账户支持** - 现金、储蓄卡、信用卡、电子钱包、投资账户全覆盖
- **灵活分类系统** - 二级分类设计，预设常用分类，支持自定义扩展
- **标签标记** - 为交易添加多个标签，实现更细粒度的分类管理

### ⚡️ 快速记账体验

- **快捷记账入口** - 首页 FAB 浮动按钮，一键快速记账
- **智能分类推荐** - 基于历史记录智能推荐常用分类
- **快速金额输入** - 自定义计算器键盘，支持加减乘除运算
- **触觉反馈** - 全局触觉反馈，提升操作手感

### 📈 强大的数据统计

- **收支趋势分析** - 日、周、月、年多维度统计图表
- **分类占比分析** - 饼图直观展示各类支出占比
- **账户余额总览** - 实时查看各账户余额及净资产
- **排行榜统计** - Top N 分类/商家支出排行
- **对比分析** - 同比、环比数据对比分析

### 💰 预算管理系统

- **分类预算** - 为每个分类设置独立预算
- **多周期支持** - 日、周、月、季、年预算周期
- **预算结转** - 支持未用完的预算结转到下期
- **预警提醒** - 超支提醒，避免过度消费
- **进度可视化** - 实时展示预算使用进度

### ☁️ iCloud 云同步

- **自动同步** - 数据实时同步到 iCloud
- **多设备支持** - iPhone、iPad 数据无缝共享
- **冲突解决** - 智能处理数据冲突
- **离线优先** - 离线也能正常使用，联网后自动同步

### 🎤 Siri 快捷指令

- **语音记账** - "Hey Siri，记一笔支出"
- **语音查询** - "Hey Siri，今天花了多少钱"
- **快捷操作** - "Hey Siri，查看预算情况"

### 📱 桌面小组件

- **小号组件** - 显示今日支出金额
- **中号组件** - 显示今日支出 + 本月统计
- **大号组件** - 显示详细的收支数据

### 🔒 隐私与安全

- **本地优先** - 数据存储在设备和个人 iCloud
- **完全私有** - 不上传任何数据到第三方服务器
- **无广告追踪** - 不使用任何分析和广告 SDK
- **开源透明** - 源代码公开，欢迎审计

### 📤 数据导入导出

- **CSV 导出** - 导出交易记录为 CSV 格式
- **账本备份** - 完整备份账本数据（JSON 格式）
- **账本导入** - 从备份文件恢复数据

## 📸 应用截图

### iPhone

<table>
  <tr>
    <td align="center">
      <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.05_resized.png" width="200"/>
      <br/>
      <sub><b>首页概览</b></sub>
      <br/>
      <sub>净资产卡片 + 今日支出 + 7日趋势</sub>
    </td>
    <td align="center">
      <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.13_resized.png" width="200"/>
      <br/>
      <sub><b>快速记账</b></sub>
      <br/>
      <sub>图标化分类选择 + 计算器键盘</sub>
    </td>
    <td align="center">
      <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.20_resized.png" width="200"/>
      <br/>
      <sub><b>统计报表</b></sub>
      <br/>
      <sub>收支趋势图 + 分类饼图</sub>
    </td>
    <td align="center">
      <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.28_resized.png" width="200"/>
      <br/>
      <sub><b>预算管理</b></sub>
      <br/>
      <sub>预算进度 + 剩余可用金额</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.36_resized.png" width="200"/>
      <br/>
      <sub><b>账本管理</b></sub>
      <br/>
      <sub>多账本切换 + 账本设置</sub>
    </td>
    <td align="center">
      <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.43_resized.png" width="200"/>
      <br/>
      <sub><b>账户总览</b></sub>
      <br/>
      <sub>各账户余额 + 信用卡额度</sub>
    </td>
    <td align="center">
      <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.50_resized.png" width="200"/>
      <br/>
      <sub><b>分类统计</b></sub>
      <br/>
      <sub>Top N 分类排行</sub>
    </td>
    <td align="center">
      <img src="jianjizhang_pages/iphone/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.51.32_resized.png" width="200"/>
      <br/>
      <sub><b>设置页面</b></sub>
      <br/>
      <sub>账户/分类管理 + 数据导出</sub>
    </td>
  </tr>
</table>

### iPad

<table>
  <tr>
    <td align="center">
      <img src="jianjizhang_pages/ipad/Simulator Screenshot - iPad Air 13-inch (M3) - 2026-02-01 at 00.09.39.png" width="350"/>
      <br/>
      <sub><b>iPad 横屏视图</b></sub>
    </td>
    <td align="center">
      <img src="jianjizhang_pages/ipad/Simulator Screenshot - iPad Air 13-inch (M3) - 2026-02-01 at 00.10.04.png" width="350"/>
      <br/>
      <sub><b>iPad 统计报表</b></sub>
    </td>
  </tr>
</table>

## 🏗️ 技术架构

### 核心技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| **Swift** | 5.9+ | 主要编程语言 |
| **SwiftUI** | 5.0 | UI 框架 |
| **SwiftData** | 1.0 | 本地数据持久化 |
| **CloudKit** | - | iCloud 云同步 |
| **Charts** | iOS 16+ | 数据可视化 |
| **WidgetKit** | - | 桌面小组件 |
| **App Intents** | iOS 16+ | Siri 集成 |
| **StoreKit 2** | - | 订阅管理（未启用）|

### 架构设计

```
jizhang/
├── App/                    # 应用入口
│   ├── jizhangApp.swift    # App 主入口
│   └── AppState.swift      # 全局状态管理
│
├── Models/                 # 数据模型层 (SwiftData)
│   ├── Ledger.swift        # 账本模型
│   ├── Account.swift       # 账户模型
│   ├── Category.swift      # 分类模型
│   ├── Transaction.swift   # 交易模型
│   ├── Budget.swift        # 预算模型
│   └── Tag.swift           # 标签模型
│
├── Views/                  # 视图层 (SwiftUI)
│   ├── Home/               # 首页模块
│   ├── Transaction/        # 交易模块
│   ├── Report/             # 报表模块
│   ├── Budget/             # 预算模块
│   ├── Ledger/             # 账本模块
│   ├── Settings/           # 设置模块
│   └── Components/         # 通用组件
│
├── ViewModels/             # 视图模型层 (MVVM)
│   ├── HomeViewModel.swift
│   ├── ReportViewModel.swift
│   ├── LedgerViewModel.swift
│   └── AddTransactionViewModel.swift
│
├── Services/               # 业务服务层
│   ├── CloudKitService.swift              # iCloud 同步
│   ├── DataManagementService.swift        # 数据管理
│   ├── SmartRecommendationService.swift   # 智能推荐
│   ├── LedgerExportService.swift          # 数据导出
│   ├── LedgerImportService.swift          # 数据导入
│   ├── SubscriptionManager.swift          # 订阅管理
│   └── TestDataGenerator.swift            # 测试数据
│
├── AppIntents/             # Siri 快捷指令
│   ├── AddExpenseIntent.swift         # 添加支出
│   ├── GetTodayExpenseIntent.swift    # 查询今日支出
│   ├── GetBudgetIntent.swift          # 查询预算
│   └── AppShortcuts.swift             # 快捷指令注册
│
├── Utilities/              # 工具类
│   ├── Constants.swift         # 常量定义
│   ├── CategoryIconConfig.swift # 分类图标配置
│   ├── HapticManager.swift     # 触觉反馈
│   ├── DataInitializer.swift   # 数据初始化
│   ├── DataMigration.swift     # 数据迁移
│   └── Extensions/             # Swift 扩展
│
└── Tests/                  # 测试
    ├── jizhangTests/       # 单元测试
    └── jizhangUITests/     # UI 测试
```

### 设计模式

- **MVVM** - 视图和业务逻辑分离
- **Repository** - 数据访问层抽象
- **Dependency Injection** - 通过 `@Environment` 注入依赖
- **Observer** - SwiftData 自动观察数据变化
- **Singleton** - 全局服务实例管理

### 数据库设计

采用 SwiftData 框架实现对象关系映射（ORM），支持：

- 自动持久化和数据同步
- 关系型数据模型
- 级联删除和数据完整性约束
- 查询优化和索引
- 数据迁移和版本管理

详细设计参见：[数据模型设计文档](docs/数据模型设计.md)

## 🚀 快速开始

### 系统要求

- **iOS** 17.6 或更高版本
- **设备** iPhone、iPad
- **Xcode** 15.0+（用于编译）
- **iCloud 账号**（可选，用于云同步）

### 从源码构建

1. **克隆仓库**

```bash
git clone https://github.com/harrysxu/jizhang_ios.git
cd jizhang_ios/jizhang
```

2. **打开项目**

```bash
open jizhang.xcodeproj
```

3. **配置签名**

- 在 Xcode 中选择 `jizhang` target
- 前往 `Signing & Capabilities`
- 选择你的开发团队
- 确保以下 Capabilities 已启用：
  - ✅ App Groups (`group.com.xxl.jizhang`)
  - ✅ iCloud (CloudKit)
  - ✅ Siri
  - ✅ Push Notifications

4. **运行项目**

- 选择目标设备（模拟器或真机）
- 按 `⌘ + R` 运行

更多详细说明请参考：[编译指南](docs/编译指南.md)

### 快速体验

**首次启动时**，应用会自动创建一个默认账本和预设分类。你可以：

1. 点击首页的 ➕ 按钮快速添加一笔交易
2. 在"报表"标签查看统计图表
3. 在"预算"标签设置月度预算
4. 在"设置"中导入测试数据体验完整功能

### 小组件配置

1. 长按 iPhone 主屏幕进入编辑模式
2. 点击左上角 ➕ 添加小组件
3. 搜索"简记账"
4. 选择小号/中号/大号小组件
5. 点击"添加小组件"

### Siri 集成

**语音记账**

"Hey Siri，在简记账记一笔支出"

**查询支出**

"Hey Siri，在简记账查看今日支出"

**查看预算**

"Hey Siri，在简记账查看预算"

更多 Siri 使用说明：[Siri 集成指南](docs/Siri集成指南.md)

## 📚 开发文档

完整的开发文档位于 [`docs/`](docs/) 目录：

### 核心文档

| 文档 | 说明 |
|------|------|
| [技术架构设计](docs/技术架构设计.md) | 整体架构、技术选型、模块划分 |
| [数据模型设计](docs/数据模型设计.md) | SwiftData 模型、关系设计、查询优化 |
| [业务逻辑实现](docs/业务逻辑实现.md) | 核心业务流程和算法实现 |
| [UI 设计指南](docs/UI设计指南.md) | 设计规范、组件库、动画效果 |

### 功能指南

| 文档 | 说明 |
|------|------|
| [CloudKit 集成指南](docs/CloudKit集成指南.md) | iCloud 同步配置和实现 |
| [Siri 集成指南](docs/Siri集成指南.md) | App Intents 配置和调试 |
| [小组件开发指南](docs/小组件开发指南.md) | WidgetKit 开发和数据共享 |
| [订阅功能指南](docs/订阅功能指南.md) | StoreKit 2 订阅系统（未启用）|

### 开发和测试

| 文档 | 说明 |
|------|------|
| [编译指南](docs/编译指南.md) | Xcode 编译配置和问题排查 |
| [真机部署指南](docs/真机部署指南.md) | 真机调试和证书配置 |
| [测试指南](docs/测试指南.md) | 单元测试、UI 测试、集成测试 |
| [开发实施手册](docs/开发实施手册.md) | 完整的开发流程和规范 |

### 发布和运维

| 文档 | 说明 |
|------|------|
| [App 发布指南](docs/App发布指南.md) | App Store 上架流程和注意事项 |

## 🧪 测试

### 运行测试

```bash
# 运行单元测试
xcodebuild test -scheme jizhang -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# 或在 Xcode 中按 ⌘ + U
```

### 测试覆盖

- ✅ **模型层测试** - 数据模型逻辑和关系验证
- ✅ **ViewModel 测试** - 业务逻辑和状态管理
- ✅ **集成测试** - 账户余额一致性、预算追踪
- ✅ **UI 测试** - 交易流程端到端测试
- ⬜ 性能测试（计划中）

详细测试说明：[测试指南](docs/测试指南.md)

## 🔐 隐私与安全

### 隐私承诺

- ✅ **零服务器** - 不运行任何后端服务器
- ✅ **零追踪** - 不使用任何分析或广告 SDK
- ✅ **零上传** - 数据仅存储在设备和个人 iCloud
- ✅ **开源透明** - 源代码公开，欢迎审计
- ✅ **完全离线** - 离线状态下完整可用

### 数据存储

- **本地数据库** - 使用 SwiftData 加密存储在设备
- **iCloud 私有容器** - 数据仅在你的 iCloud 账户中
- **App Group** - 主应用和小组件/快捷指令共享数据

### 权限说明

| 权限 | 用途 |
|------|------|
| **Siri** | 支持语音快捷指令 |
| **iCloud** | 可选的数据云同步 |
| **通知** | 预算超支提醒（可选）|

查看完整的[隐私政策](pages/privacy-policy.html)

## 🤝 贡献指南

欢迎为简记账贡献代码、报告问题或提出改进建议！

### 如何贡献

1. **Fork 本仓库**

```bash
# 点击页面右上角的 Fork 按钮
```

2. **克隆到本地**

```bash
git clone https://github.com/YOUR_USERNAME/jizhang_ios.git
cd jizhang_ios
```

3. **创建特性分支**

```bash
git checkout -b feature/amazing-feature
# 或
git checkout -b fix/bug-description
```

4. **提交更改**

```bash
git add .
git commit -m "feat: 添加某个功能" 
# 或
git commit -m "fix: 修复某个问题"
```

提交信息规范：
- `feat:` 新功能
- `fix:` 问题修复
- `docs:` 文档更新
- `style:` 代码格式调整
- `refactor:` 代码重构
- `test:` 测试相关
- `chore:` 构建/工具相关

5. **推送到远程**

```bash
git push origin feature/amazing-feature
```

6. **创建 Pull Request**

- 前往 GitHub 仓库页面
- 点击 "New Pull Request"
- 填写 PR 描述和改动说明
- 等待代码审查

### 代码规范

- 遵循 Swift 官方代码风格
- 使用有意义的变量和函数命名
- 添加必要的注释和文档
- 保持代码简洁可读
- 编写单元测试覆盖新功能

### 报告问题

如果你发现了 Bug 或有功能建议：

1. 查看 [Issues](https://github.com/harrysxu/jizhang_ios/issues) 确认问题未被报告
2. 创建新 Issue，使用合适的模板
3. 提供详细的复现步骤、截图和日志
4. 标注你的 iOS 版本和设备型号

### 功能建议

如果你有新功能的想法：

1. 前往 [Discussions](https://github.com/harrysxu/jizhang_ios/discussions)
2. 在 "Ideas" 分类下发起讨论
3. 描述功能的使用场景和预期效果
4. 参与社区投票和讨论

## 🎯 开发路线图

### v1.0（当前版本）

- ✅ 基础记账功能
- ✅ 多账本/账户管理
- ✅ 预算系统
- ✅ 数据统计图表
- ✅ iCloud 同步
- ✅ Siri 快捷指令
- ✅ 桌面小组件
- ✅ 数据导入导出

### v1.1（计划中）

- [ ] Apple Watch 支持
- [ ] 更多图表类型（瀑布图、日历热力图）
- [ ] 自定义主题和配色
- [ ] 账单到期提醒
- [ ] 图片/凭证附件支持
- [ ] 搜索和筛选优化

### v1.2（规划中）

- [ ] 多语言支持（英文）
- [ ] iPad 横屏优化
- [ ] 更多导出格式（Excel、PDF）
- [ ] 账单扫描（OCR）
- [ ] 定期账单/重复交易
- [ ] 分期付款管理

### v2.0（愿景）

- [ ] 债务/借贷管理
- [ ] 投资组合追踪
- [ ] 家庭共享账本
- [ ] 财务报告生成
- [ ] 数据分析和洞察
- [ ] AI 智能记账助手

想要优先看到某个功能？前往 [Discussions](https://github.com/harrysxu/jizhang_ios/discussions) 投票！

## 📝 反馈与支持

如果您有任何问题、建议或反馈，欢迎通过以下方式联系：

- 📧 **邮箱：** [ailehuoquan@163.com](mailto:ailehuoquan@163.com)
- 🐛 **问题反馈：** [GitHub Issues](https://github.com/harrysxu/jizhang_ios/issues)
- 💬 **功能建议：** [GitHub Discussions](https://github.com/harrysxu/jizhang_ios/discussions)

## 📄 许可证

本项目采用 MIT 许可证开源 - 查看 [LICENSE](LICENSE) 文件了解详情。

## ⭐ Star History

如果这个项目对你有帮助，请给一个 ⭐️ 支持一下！

[![Star History Chart](https://api.star-history.com/svg?repos=harrysxu/jizhang_ios&type=Date)](https://star-history.com/#harrysxu/jizhang_ios&Date)

## 💖 支持项目

如果你喜欢简记账，可以通过以下方式支持我们：

- ⭐️ 给项目一个 Star
- 🔀 Fork 并贡献代码
- 🐛 报告问题和建议
- 📢 向朋友推荐
- 📝 撰写使用教程或博客

## 🙏 致谢

感谢所有支持和使用简记账的用户！

**特别感谢：**

- [Apple](https://www.apple.com) - 提供优秀的开发工具和框架
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) 社区 - 丰富的学习资源
- 所有贡献者 - 让项目变得更好
- 所有提供反馈的用户 - 帮助我们持续改进

## 🔗 相关链接

- [GitHub 仓库](https://github.com/harrysxu/jizhang_ios)
- [问题反馈](https://github.com/harrysxu/jizhang_ios/issues)
- [功能讨论](https://github.com/harrysxu/jizhang_ios/discussions)
- [更新日志](CHANGELOG.md)

---

<p align="center">
  <sub>使用 ❤️ 和 SwiftUI 构建</sub>
  <br/>
  <sub>© 2026 简记账. 保留所有权利.</sub>
</p>

<p align="center">
  <a href="#-简记账">回到顶部 ↑</a>
</p>
