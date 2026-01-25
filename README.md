# Lumina 记账App - 阶段4极致体验

## 项目概述

Lumina是一款基于iOS 17+的原生记账应用，深度集成iOS生态，提供极致的用户体验。

### 核心特性

- ✅ **Widget桌面小组件** - 三种尺寸，实时显示财务数据
- ✅ **Live Activities灵动岛** - 购物模式实时追踪支出
- ✅ **Siri Shortcuts** - 语音记账和查询
- ✅ **CloudKit同步** - 多设备自动同步
- ✅ **预算管理** - 智能预算追踪和超支预警
- ✅ **报表统计** - Swift Charts数据可视化
- ✅ **多账本支持** - 数据隔离，场景分离

## 快速开始

### 环境要求

- macOS: Sonoma 14.0+
- Xcode: 15.0+
- iOS部署目标: iOS 17.0+
- 真机设备: iPhone (Widget和Live Activities需要真机测试)
- Apple Developer账号: 配置App Groups能力

### 安装步骤

1. **克隆项目**
```bash
cd /Users/xuxiaolong/OpenSource/jizhang_ios/jizhang
open jizhang.xcodeproj
```

2. **完成Xcode配置**

⚠️ **重要**: 阶段4功能需要手动配置Widget Extension。请参考:

📄 [**Xcode配置指南**](XCODE_CONFIGURATION_GUIDE.md)

详细的分步指南包括:
- 添加App Groups能力
- 创建Widget Extension Target
- 配置Target Membership
- 测试Widget和Live Activities

3. **编译和运行**
```bash
# 选择主App Scheme
# 选择真机设备
# 点击Run (⌘R)
```

## 项目结构

```
jizhang_ios/
├── jizhang/                       # 主App
│   ├── jizhang/
│   │   ├── App/                   # App入口和状态管理
│   │   ├── Models/                # 数据模型(SwiftData)
│   │   ├── Views/                 # SwiftUI视图
│   │   ├── ViewModels/            # MVVM ViewModels
│   │   ├── Services/              # 业务服务(CloudKit等)
│   │   ├── Utilities/             # 工具类
│   │   ├── ActivityKit/           # Live Activities实现
│   │   └── AppIntents/            # Siri Shortcuts实现
│   │
│   └── jizhangWidget/             # Widget Extension
│       ├── Views/                 # Widget UI(Small/Medium/Large)
│       ├── Providers/             # Timeline Provider
│       ├── Models/                # Widget数据模型
│       ├── Services/              # Widget数据服务
│       └── Intents/               # Widget交互Intent
│
├── docs/                          # 开发文档
├── STAGE4_COMPLETION_SUMMARY.md   # 阶段4完成总结
├── XCODE_CONFIGURATION_GUIDE.md   # Xcode配置指南
└── README.md                      # 本文件
```

## 功能说明

### 1. Widget桌面小组件

三种尺寸的Widget，提供不同的信息密度:

- **Small (小号)** - 今日支出和预算进度
- **Medium (中号)** - 今日支出 + 最近3笔交易
- **Large (大号)** - 本月概览 + 最近5笔交易 + 快速记账按钮

**使用方法:**
1. 长按主屏幕进入编辑模式
2. 点击左上角"+"按钮
3. 搜索"Lumina"
4. 选择尺寸并添加

### 2. Live Activities购物模式

实时追踪购物支出，显示在灵动岛和锁屏界面。

**功能特性:**
- 累计支出金额实时显示
- 预算进度追踪
- 最近交易列表
- 灵动岛紧凑/展开/最小化视图
- 锁屏卡片显示

**使用方法:**
1. 打开App首页
2. 点击右上角购物车图标
3. 可选设置预算限额
4. 点击"开始购物"
5. 正常记账，Activity自动更新
6. 结束后点击"结束购物"

### 3. Siri Shortcuts快捷指令

语音记账和查询，无需打开App。

**支持的指令:**
- "用Lumina记一笔30元" - 快速记账
- "今天花了多少钱" - 查询今日支出
- "本月预算还剩多少" - 查询预算使用情况

**使用方法:**
1. 首次需在快捷指令App中添加
2. 直接对Siri说出指令
3. Siri执行并语音反馈结果

## 技术架构

### 核心技术栈

- **UI框架**: SwiftUI
- **数据持久化**: SwiftData
- **云同步**: CloudKit
- **Widget**: WidgetKit
- **Live Activities**: ActivityKit
- **快捷指令**: App Intents
- **数据共享**: App Groups

### 架构设计

```
┌─────────────────────────────────────────┐
│           Main App (iOS 17+)            │
│  ┌───────────────────────────────────┐  │
│  │    SwiftUI Views (MVVM)          │  │
│  │    - HomeView                     │  │
│  │    - BudgetView                   │  │
│  │    - ReportView                   │  │
│  │    - ShoppingModeSheet            │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │    ViewModels                     │  │
│  │    - AddTransactionViewModel      │  │
│  │    - BudgetViewModel              │  │
│  │    - ReportViewModel              │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │    Services & Managers            │  │
│  │    - CloudKitService              │  │
│  │    - ShoppingActivityManager      │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │    SwiftData Models               │  │
│  │    + App Groups Storage           │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
┌──────────────┐ ┌──────────┐ ┌───────────────┐
│   Widget     │ │  Live    │ │ Siri Shortcuts│
│  Extension   │ │ Activity │ │  (AppIntents) │
│              │ │          │ │               │
│ -Timeline    │ │-灵动岛UI │ │-AddExpense    │
│ -3 Sizes     │ │-锁屏UI   │ │-GetToday      │
│ -Interactive │ │-实时更新 │ │-GetBudget     │
└──────────────┘ └──────────┘ └───────────────┘
        │           │           │
        └───────────┼───────────┘
                    │
            App Groups Container
         (Shared SwiftData + Config)
```

### 数据流

1. **主App → Widget**
   - 主App写入SwiftData (App Groups路径)
   - 调用`WidgetCenter.shared.reloadAllTimelines()`
   - Widget通过TimelineProvider读取数据
   - Widget UI更新

2. **主App → Live Activity**
   - 用户启动购物模式
   - ShoppingActivityManager创建Activity
   - 记账时调用`activity.update()`
   - 灵动岛和锁屏实时更新

3. **Siri → Intent → 主App**
   - 用户语音指令
   - Intent执行(后台访问SwiftData)
   - 返回结果给Siri
   - Siri语音播报

## 开发进度

### ✅ 阶段1: 项目初始化
- SwiftData模型设计
- 基础UI框架
- 导航结构

### ✅ 阶段2: 核心功能
- 快速记账
- 账户管理
- 分类管理
- 流水列表

### ✅ 阶段3: 高级功能
- 预算管理
- 报表统计
- 多账本支持
- CloudKit同步

### ✅ 阶段4: 极致体验 (当前)
- Widget桌面小组件 ✅
- Live Activities灵动岛 ✅
- Siri Shortcuts快捷指令 ✅
- 完整iOS生态集成 ✅

## 文档索引

### 开发文档
- 📘 [技术架构设计](docs/技术架构设计.md)
- 📘 [数据模型设计](docs/数据模型设计.md)
- 📘 [UI设计规范](docs/UI设计规范.md)
- 📘 [页面设计详解](docs/页面设计详解.md)
- 📘 [开发实施手册](docs/开发实施手册.md)
- 📘 [CloudKit同步方案](docs/CloudKit同步方案.md)
- 📘 [Widget开发指南](docs/Widget开发指南.md)

### 完成总结
- 📄 [阶段2完成总结](STAGE2_COMPLETION_SUMMARY.md)
- 📄 [阶段3完成总结](STAGE3_COMPLETION_SUMMARY.md)
- 📄 [阶段4完成总结](STAGE4_COMPLETION_SUMMARY.md)

### 配置指南
- ⚙️ [Xcode配置指南](XCODE_CONFIGURATION_GUIDE.md) ⭐️
- ⚙️ [CloudKit配置](CLOUDKIT_SETUP.md)

## 测试

### Widget测试
```bash
# 1. 编译Widget Extension
# Xcode: 选择jizhangWidget Scheme → Build

# 2. 运行主App到真机
# Xcode: 选择jizhang Scheme → Run

# 3. 添加Widget到主屏幕
# 长按主屏幕 → + → 搜索Lumina → 添加
```

### Live Activities测试
```bash
# 需要iPhone 14 Pro+测试灵动岛

# 1. 运行主App
# 2. 点击首页右上角购物车图标
# 3. 启动购物模式
# 4. 记录交易观察灵动岛更新
# 5. 锁屏查看Live Activity
```

### Siri Shortcuts测试
```bash
# 1. 运行主App到真机
# 2. 打开快捷指令App
# 3. 添加Lumina相关快捷指令
# 4. 对Siri说: "用Lumina记一笔30元"
```

## 性能指标

- Widget启动时间: <500ms
- Timeline Provider执行: <1秒
- Activity更新延迟: <500ms
- Intent执行时间: <2秒
- Widget刷新频率: 每30分钟
- Activity最长运行: 8小时

## 已知限制

1. **Widget刷新**
   - 系统限制每天刷新次数(约40-70次)
   - 非实时更新，有延迟

2. **Live Activities**
   - 需要iOS 16.1+
   - 最多运行8小时
   - 灵动岛需要iPhone 14 Pro+

3. **Siri Shortcuts**
   - 首次使用需用户授权
   - 语音识别准确性依赖系统

4. **App Groups**
   - 需要Apple Developer账号配置
   - 免费账号有限制

## 常见问题

### Q: Widget不显示数据?
A: 检查App Groups配置是否正确，主App和Widget是否使用相同的Group ID。

### Q: Live Activities无法启动?
A: 确认设备运行iOS 16.1+，检查Info.plist中的NSSupportsLiveActivities配置。

### Q: Siri无法识别指令?
A: 首次使用需在快捷指令App中添加，尝试不同的语音表达方式。

### Q: Widget刷新不及时?
A: Widget刷新由系统控制，30分钟Timeline已设置，系统可能限制刷新频率。

## 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 许可证

本项目仅供学习和研究使用。

## 联系方式

如有问题或建议，请创建Issue。

---

**最后更新**: 2026年1月24日
**版本**: v1.0.0 (阶段4完成)
**状态**: ✅ 开发完成，等待Xcode配置和测试
