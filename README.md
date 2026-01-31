# 📱 简记账

> 简洁优雅的个人记账应用

[![App Store](https://img.shields.io/badge/App%20Store-上线中-blue?style=flat-square&logo=apple)](https://apps.apple.com)
[![Platform](https://img.shields.io/badge/platform-iOS%2016.0%2B-lightgrey?style=flat-square)](https://www.apple.com/ios/)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange?style=flat-square)](https://developer.apple.com/xcode/swiftui/)

<p align="center">
  <img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.05_resized.png" width="200">
  <img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.13_resized.png" width="200">
  <img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.20_resized.png" width="200">
  <img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.28_resized.png" width="200">
</p>

## ✨ 特性

### 🎯 核心功能

- **⚡️ 快速记账** - 3秒记一笔账，流畅丝滑的记账体验
- **📊 智能统计** - 多维度数据统计，收支趋势一目了然
- **💰 预算管理** - 设置月度预算，实时进度提醒，避免超支
- **📚 多账本支持** - 工作、生活、旅行分开管理，灵活高效
- **☁️ iCloud 同步** - 数据自动同步，多设备无缝切换
- **🔒 隐私安全** - 所有数据存储在本地和 iCloud，完全私有

### 🌟 进阶功能

- **📱 桌面小组件** - 一眼查看今日支出和本月统计
- **🎤 Siri 快捷指令** - 语音快速记账，解放双手
- **🌙 深色模式** - 完美适配，护眼舒适
- **📤 数据导出** - 支持 CSV 和账本备份格式
- **🏷️ 标签系统** - 灵活分类，精细管理
- **📎 附件支持** - 保存消费凭证，记录更完整

## 📸 截图

<table>
  <tr>
    <td><img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.05_resized.png" width="200"/><br/><sub>首页概览</sub></td>
    <td><img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.13_resized.png" width="200"/><br/><sub>快速记账</sub></td>
    <td><img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.20_resized.png" width="200"/><br/><sub>统计报表</sub></td>
    <td><img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.28_resized.png" width="200"/><br/><sub>预算管理</sub></td>
  </tr>
  <tr>
    <td><img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.36_resized.png" width="200"/><br/><sub>账本管理</sub></td>
    <td><img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.43_resized.png" width="200"/><br/><sub>账户总览</sub></td>
    <td><img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.50.50_resized.png" width="200"/><br/><sub>分类统计</sub></td>
    <td><img src="jianjizhang_pages/Simulator Screenshot - iPhone 17 - 2026-01-31 at 22.51.32_resized.png" width="200"/><br/><sub>设置页面</sub></td>
  </tr>
</table>

## 🚀 快速开始

### 下载

<a href="https://apps.apple.com" target="_blank">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="50">
</a>

### 系统要求

- iOS 16.0 或更高版本
- iPhone / iPad
- iCloud 账号（可选，用于同步）

## 💎 订阅选项

| 方案 | 价格 | 特性 |
|------|------|------|
| **免费版** | ¥0 | 基础记账功能、3个账本、本地存储 |
| **月度订阅** | ¥6/月 | 无限账本、高级统计、数据导出 |
| **年度订阅** | ¥48/年 | 月度订阅所有功能，节省 33% |
| **终身买断** | ¥98 | 一次付费，永久使用所有功能 |

## 🔐 隐私承诺

我们深知隐私对您的重要性，因此：

- ✅ **不收集**任何个人信息
- ✅ **不上传**任何数据到我们的服务器
- ✅ **不使用**任何第三方分析或广告SDK
- ✅ 所有数据仅存储在**您的设备**和 **iCloud 私有容器**中
- ✅ 支持 **Face ID / Touch ID** 保护

查看完整的[隐私政策](pages/privacy-policy.html)

## 🛠️ 技术栈

- **语言：** Swift 5.0+
- **框架：** SwiftUI, SwiftData
- **架构：** MVVM
- **同步：** CloudKit
- **订阅：** StoreKit 2
- **小组件：** WidgetKit
- **快捷指令：** App Intents

## 📦 功能模块

```
jizhang/
├── Models/           # 数据模型
│   ├── Transaction   # 交易记录
│   ├── Ledger        # 账本
│   ├── Category      # 分类
│   ├── Account       # 账户
│   └── Budget        # 预算
├── ViewModels/       # 视图模型
├── Views/            # 视图层
│   ├── Home/         # 首页
│   ├── Transaction/  # 记账
│   ├── Report/       # 报表
│   ├── Budget/       # 预算
│   ├── Ledger/       # 账本
│   └── Settings/     # 设置
├── Services/         # 服务层
│   ├── CloudKitService           # iCloud同步
│   ├── SubscriptionManager       # 订阅管理
│   ├── DataManagementService     # 数据管理
│   └── SmartRecommendationService # 智能推荐
└── Utilities/        # 工具类
```

## 🎯 路线图

### v1.1（即将推出）
- [ ] Apple Watch 支持
- [ ] 更多图表类型
- [ ] 自定义主题
- [ ] 账单提醒

### v1.2
- [ ] 多语言支持（英文）
- [ ] iPad 优化
- [ ] 更多导出格式
- [ ] 账单扫描（OCR）

### v2.0
- [ ] 债务管理
- [ ] 定期账单
- [ ] 资产投资追踪
- [ ] 家庭共享账本

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 如何贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📝 反馈

如果您有任何问题、建议或反馈，欢迎通过以下方式联系我们：

- 📧 **邮箱：** [ailehuoquan@163.com](mailto:ailehuoquan@163.com)
- 🐛 **问题反馈：** [GitHub Issues](https://github.com/harrysxu/jizhang_ios/issues)
- 💬 **功能建议：** [GitHub Discussions](https://github.com/harrysxu/jizhang_ios/discussions)

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🌟 Star History

如果这个项目对您有帮助，请给一个 ⭐️ 支持一下！

[![Star History Chart](https://api.star-history.com/svg?repos=harrysxu/jizhang_ios&type=Date)](https://star-history.com/#harrysxu/jizhang_ios&Date)

## 💖 支持我们

如果您喜欢简记账，可以通过以下方式支持我们：

- ⭐️ 在 GitHub 上给我们一个 Star
- 📱 在 App Store 给我们五星好评
- 🗣 向朋友推荐简记账
- 💰 订阅高级功能（支持我们持续开发）

## 🙏 致谢

感谢所有支持和使用简记账的用户！

特别感谢：
- Apple 提供的优秀开发工具和框架
- SwiftUI 社区的开源贡献
- 所有提供反馈和建议的用户

---

<p align="center">
  <sub>使用 ❤️ 和 SwiftUI 构建</sub>
</p>

<p align="center">
  <sub>© 2026 简记账. 保留所有权利.</sub>
</p>
