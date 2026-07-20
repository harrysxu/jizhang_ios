# 简记账 · 简迹 2.0 全面测试报告

测试日期：2026-07-11 至 2026-07-12

测试版本：`2.0.0 (200)`
结论：自动化质量门槛、旧版模拟器覆盖升级和真实 iPhone local-only 覆盖升级门槛通过，可进入生产脱敏旧库和内部 TestFlight 验收；当前不满足直接提交 App Store 的条件。

## 1. 测试环境

| 项目 | 环境 |
| --- | --- |
| 开发工具 | Xcode 26.6，iOS 26.5 Simulator SDK |
| macOS | 26.5.1 |
| iPhone | iPhone 17 Pro，iOS 26.5 |
| iPad | iPad Pro 13-inch (M5)，iPadOS 26.5 |
| 真实设备 | iPhone 14（`iPhone14,7`），iOS 26.5，有线连接、Developer Mode 开启 |
| 数据 | UI 用例使用独立 store；升级专项使用 1.0.1 本地 store 和内置测试数据生成器，不连接真实 CloudKit |
| 升级设备 | iPhone SE、iPhone 17 Pro、iPhone 17 Pro Max，iOS 26.5 |
| 签名 | 常规自动化使用 Simulator 构建；模拟器覆盖升级使用 `Sign to Run Locally`，真机使用 Apple Development 自动签名 |

## 2. 最终结果

| 测试层 | 结果 | 证据 |
| --- | --- | --- |
| 单元/集成 | 154 通过，0 失败，0 跳过 | `/tmp/jizhang-upgrade-new-signed-build/Logs/Test/Test-jizhang-2026.07.12_11-16-44-+0800.xcresult` |
| iPhone UI/产品 | 19 个声明用例；18 通过，1 个 iPad 专属用例按预期跳过；Light/Dark 动态执行共 19 次通过 | `/tmp/jizhang-final-ui-2/Logs/Test/Test-jizhang-2026.07.11_22-43-35-+0800.xcresult` |
| iPad 专项 | 默认、Light、Dark 各 1 次通过，0 失败 | `/tmp/jizhang-final-ipad-2/Logs/Test/Test-jizhang-2026.07.11_22-49-46-+0800.xcresult`、`/tmp/jizhang-final-ipad-light/Logs/Test/Test-jizhang-2026.07.11_23-15-36-+0800.xcresult`、`/tmp/jizhang-final-ipad-dark/Logs/Test/Test-jizhang-2026.07.11_23-17-11-+0800.xcresult` |
| AX5 组合无障碍 | 1 通过，覆盖四个核心页面 | `/tmp/jizhang-final-ax5-combined/Logs/Test/Test-jizhang-2026.07.11_21-21-53-+0800.xcresult` |
| 1.0.1 → 2.0 覆盖升级 | 4 轮通过，77/78/568/4140 笔；升级前后规范化 JSON 完全相等 | `/tmp/upgrade-baseline-*.json`、`/tmp/upgrade-upgraded-*.json`、`/tmp/upgrade-selectionfix-small.json` |
| 升级后生产 Store 操作 | small/medium/large 各重复 2 轮，共 6 轮、96 项断言通过 | `/tmp/upgrade-postoperations-*-rerun.json`、`/tmp/upgrade-postoperations-*-second.json` |
| 真实 iPhone 覆盖升级 | 1.0.1 的 88 笔数据覆盖安装 2.0.0，实体、关系、逐账户余额和 checksum 完全一致；升级后操作重复 2 轮通过 | `/tmp/jizhang-physical-baseline.json`、`/tmp/jizhang-physical-upgraded.json`、`/tmp/jizhang-physical-postoperations-*.json` |
| 真实 iPhone UI/产品回归 | 最终连续 9 项通过，0 失败；含严格核心页面无障碍审计 | `/tmp/jizhang-physical-device-build/Logs/Test/Test-jizhang-2026.07.12_13-40-49-+0800.xcresult` |
| App 构建 | 通过 | `/tmp/jizhang-final-build-app-2` |
| Widget 构建 | 通过 | `/tmp/jizhang-final-build-widget-2` |

## 3. 单元与集成覆盖

- 交易：支出、收入、转账、余额调整、legacy income、编辑差额、删除、撤销、跨账本拒绝、保存失败 rollback 和余额一致性。
- 预算：月度、年度、自定义周期、跨月、时区、父子分类、未覆盖支出、安全日均、免费单预算限制，以及 App/Widget/Siri 统一口径。
- 备份与导入：1.0 兼容、2.0 manifest/checksum、未知版本、损坏校验和、缺失/跨账本引用、失败回滚、无损往返。
- CSV：RFC 4180、POSIX 金额、CRLF、特殊字符和公式注入防护。
- 权益：免费、订阅、终身、高级功能判断和基础 iCloud 免费策略。
- 启动环境：in-memory、UI test、recovery store、依赖注入和 store 打开失败路径。
- 启动选择：上次使用账本优先恢复；目标账本被归档时回退默认账本。

## 4. 覆盖升级专项

使用主干旧版 `1.0.1` 正常安装到三台独立模拟器，通过旧版内置 `TestDataGenerator` 生成不同规模数据，并补充 legacy income、孤立支出、调整交易、标签、年度/自定义预算、归档账户/账本和特殊字符。保存旧版审计后，使用相同 Bundle ID 覆盖安装 `2.0.0`，未卸载 App、未复制或替换 Store 文件。

| 轮次 | 流水 | 账本/账户/分类/预算/标签 | 升级结果 |
| --- | ---: | --- | --- |
| small | 78 | 3 / 4 / 110 / 4 / 1 | 全内容 checksum、逐账户余额、类型和关系分布完全一致 |
| medium | 568 | 4 / 8 / 165 / 9 / 1 | 全内容 checksum、逐账户余额、类型和关系分布完全一致 |
| large | 4140 | 5 / 16 / 220 / 18 / 1 | 全内容 checksum、逐账户余额、类型和关系分布完全一致 |
| small 独立复测 | 77 | 3 / 4 / 110 / 4 / 1 | 数据完全一致，并恢复升级前最后使用的账本 |
| 真实 iPhone 14 | 88 | 3 / 4 / 110 / 4 / 1 | 1.0.1 原位覆盖到 2.0.0；checksum `a83f114c…3925d4`、逐账户余额、哨兵和关系分布完全一致 |

每份升级 Store 上均通过正式 `TransactionService` 执行：新增 `19.99` 后撤销、新增 `31.25`、编辑为 `62.50`、删除后撤销，并调用正式 `BudgetCalculator`。最终仅保留 1 笔 `62.50` 支出；目标账户精确减少 `62.50`，其他账户和全部原始交易不变，legacy income 可通过 `toAccount ?? fromAccount` 正确解析。完整流程再次重复后结果相同，没有累积重复流水。

真实 iPhone 使用 Debug-only `--upgrade-local-only`，旧版和新版只访问 App Group 内的 `upgrade-test.sqlite`，CloudKit 禁用，生产 `jizhang.sqlite` 未被测试数据触碰。UI 回归完成后再次审计该库：89 笔流水、总余额 `25197.83`，相对 88 笔升级基线精确减少 `62.50`；4 类哨兵计数和关系问题分布保持不变，证明 UI 独立 store 未污染升级 store。

## 5. 页面与产品流程覆盖

| 区域 | 已验证行为 |
| --- | --- |
| 启动/升级 | 老用户 2.0 更新摘要、新用户三步设置、首笔记账、独立 UI store、启动性能 |
| 恢复 | store 打开失败页、重试、恢复包入口、诊断信息、无障碍审计 |
| 首页 | 预算入口、今日状态、最近流水、行动建议、净资产入口、底部导航 |
| 记账 | 支出、收入、转账、金额键盘与完成按钮、建议金额、分类、日期、备注、编辑 42→84、删除和撤销 |
| 流水 | 搜索、类型筛选、空状态、详情、编辑、删除、撤销、交易行稳定标识 |
| 洞察 | 结论、周期、汇总、空图表、会员 Tab、预算入口、AX5 自适应布局 |
| 预算 | 空状态、创建入口、免费第一个预算、预算页无障碍 |
| 设置 | 免费 iCloud、导入会员墙、会员导入页面、权益文案和数据管理入口 |
| iPad | `NavigationSplitView` 侧栏、预算入口、记一笔入口、详情区导航及 Light/Dark 截图 |
| 外观/辅助功能 | Light、Dark、AX5、增强对比度、减弱动态效果、减弱透明度、`performAccessibilityAudit` |

## 6. 测试中发现并修复的问题

1. 交易 UI 缺少稳定标识，自动化无法可靠选择金额、账户、分类和流水行；已补齐 accessibility identifier/label。
2. 金额键盘缺少“完成”，建议金额和“上一笔”在聚焦时不同步；已修复。
3. 编辑金额没有可靠替换旧值；现已覆盖 `42 → 84` 回归。
4. iCloud 和免费预算权益文案错误；已改为基础 iCloud 免费、免费 1 个预算、会员无限及高级预算。
5. UI 测试曾创建真实 CloudKit 容器并导致未签名模拟器崩溃；现使用独立测试环境。
6. 首页、洞察、设置存在点击区域、对比度、装饰图标朗读和 Tab Bar 遮挡问题；已修复并通过审计。
7. AX5 下洞察导航、结论和三列汇总被横向撑出屏幕；现改为标题分行和汇总纵向布局。
8. 首页建议父级合并导致对比度审计错误归因；现隐藏装饰图标并让建议文字独立朗读。
9. 洞察选中 Tab 在深色模式使用浅翡翠背景配白字，对比不足；现使用固定深翡翠 `#0B6E4F`。
10. 记账表单在键盘出现后不可滚动，小屏操作空间不足；现将字段区改为可滚动内容并固定保存动作。
11. iPhone 声明支持横屏但窗口不能正确旋转；2.0 收窄为 iPhone 竖屏，iPad 继续支持四方向。
12. 升级后 Store 数据完整但启动总是优先选择默认账本，忽略旧用户最后使用的账本，容易造成“数据为空”的误解；现改为上次账本优先，并通过单元测试和独立覆盖升级截图验证。
13. 首轮升级写操作脚本把“删除后撤销”误当作“撤销新增”，导致测试数据多保留一笔；已修正测试语义并连续两轮通过，未归因到产品逻辑。
14. 真机编辑金额时，输入框覆盖层会截获清空按钮点击，且 iOS 26 数字键盘不稳定展示 SwiftUI keyboard toolbar；现改为同层 44pt 清空/收起键盘按钮，并通过 `42 → 84` 完整保存验证。
15. 真机深色模式暴露设置页底栏边缘和高级文字徽章对比度问题；设置审计改为完整滚动到数据管理区域，高级标识改为带 VoiceOver 标签的高对比皇冠图标，核心四页严格审计通过。
16. 连续 UI 回归会恢复不同的默认转出账户，固定选择“工行储蓄卡”的用例可能选择到被排除账户；账户按钮增加稳定标识，转账改为选择当前首个合法目标，单项及整组回归均通过。

## 7. 无障碍审计说明

核心审计对所有带可定位元素的问题保持严格失败。仅过滤 Xcode 26 的两类无可操作节点问题：

- `contrast` 且 `issue.element == nil`；
- `dynamicType`、`issue.element == nil` 且描述为 `partially unsupported`。

设置页已有一组已知的系统审计误报：明确使用动态 `.body` 字体的设置行仍被报告为 `partially unsupported`。这些行已通过 AX5 截图人工检查，具体元素以外的问题不做宽泛忽略。

## 8. 已知残余风险

- iOS 26.5 Simulator 和 iPhone 14 真机在金额键盘自动聚焦时均可能记录一次 SwiftUI `Invalid frame dimension (negative or non-finite)`。警告没有可符号化栈，不影响交易流程和保存结果，仍需在 TestFlight 继续观察。
- Xcode 26 测试日志反复输出 `DebuggerVersionStore` 的无调试器版本提示，不影响构建或测试。
- 模拟器缺失系统 haptic pattern library 的日志属于 Simulator 环境限制。
- 升级专项已覆盖由旧版 App 真实写入的 local-only 模拟器和 iPhone Store，能验证持久化兼容和业务操作，但不能替代生产/TestFlight 脱敏库与 CloudKit 服务端状态验证。

## 9. 发布阻塞项

1. 旧版生成的 local-only 模拟器与真实 iPhone 覆盖升级已通过，但尚未提供生产旧版/TestFlight 脱敏 local-only 与 CloudKit store fixture；生产数据形态和 CloudKit 服务端记录仍需同样核对。
2. 尚未完成真实 iCloud 账号、多设备、离线、弱网和冲突收敛测试；UI 自动化使用的是注入服务。
3. 当前编译使用的 AppIcon 仍需确认无 alpha，并补齐合格的 Light、Dark、Tinted 三套资产。
4. StoreKit Configuration 的过期、退款、恢复购买仍需通过 Transaction Manager 和沙盒账号人工切换。
5. “简记账 - 简迹”展示名的 App Store 重名和商标检查未完成。

## 10. 发布建议

- 当前可进入内部 TestFlight，不可直接提交 App Store。
- 生产旧库 fixture、真实 iCloud、多状态 StoreKit 和图标资产全部通过后，再开放小范围外部 TestFlight。
- 灰度期间任何空账本、实体减少、余额突变、重复流水、迁移崩溃或恢复失败都应立即停止发布。
