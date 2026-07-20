# 简记账 · 简迹 2.0 实施与发布门槛状态

更新时间：2026-07-12

## 当前结论

`2.0.0 (200)` 的兼容内核、核心业务修复、主要 UI/UX、测试宿主和发布配置已落地。模拟器 App/Widget 构建、154 个单元/集成测试、完整 iPhone 产品/UI 套件、iPad 侧栏专项、AX5 组合无障碍审计、4 轮模拟器及 1 轮真实 iPhone `1.0.1 → 2.0.0` 覆盖升级通过。完整证据见 `APP_2.0_COMPREHENSIVE_TEST_REPORT_2026-07-11.md`。

当前状态适合继续做生产脱敏旧库回归和 TestFlight 验证，不满足直接提交 App Store 的条件。

## 已完成

- 生产 store 打开失败不再删库、删 WAL/SHM、重试建空库或 `fatalError`；进入恢复界面，可重试和导出原始恢复包。
- production、in-memory、UI test、recovery store 已隔离；CloudKit、StoreKit、时钟、Widget 刷新器和恢复服务可注入。
- 只有新 store 创建默认账本；旧数据、CloudKit 初次拉取和孤立关系不再按固定延时自动修复。
- App、Siri 和原 HomeViewModel 的交易写入统一通过 `TransactionService`；Widget 交互仍只负责打开 App。
- 支出、收入、转账和有符号余额调整使用差额账户影响；legacy income 使用 `toAccount ?? fromAccount`。
- 新收入同时保留 `fromAccount` 和 `toAccount` 兼容关系，但余额只增加一次。
- 创建、编辑、删除和撤销失败执行 rollback；删除和新增均提供 5 秒跨页面撤销。
- 账户编辑不再直接覆盖余额，改为生成调整交易；用户主动重置账本仍按原会员功能执行。
- `BudgetCalculator` 统一 App、Widget 和 Siri 口径，支持父子分类、年度和跨月自定义周期、未纳入预算支出与安全日均。
- 免费用户可创建 1 个预算；会员保留无限预算和结转能力。基础 iCloud 已从会员功能枚举中移除。
- 备份 2.0 增加 manifest、SHA-256、枚举和引用预检；继续读取 1.0；导入使用独立 context 并在失败时回滚。
- CSV 使用 RFC 4180、POSIX 金额、CRLF 和公式注入防护；`.jizhang` 系统文件打开入口已接入原会员墙。
- iPhone 保留四 Tab 和中心记账动作，“报表”已更名“洞察”；首页、记账、流水和洞察主流程已重排。
- iPad 使用 `NavigationSplitView`，侧栏包含预算和记账入口，支持 `Command-1...4` 与 `Command-N`。
- 新用户使用币种、默认账户、首笔记账三步流程；老用户只显示一次可关闭的 2.0 更新摘要。
- 老用户升级后优先恢复最后使用且未归档的账本；不可用时才回退默认账本，避免升级后误入空账本。
- 品牌语义色支持深浅模式和对比度；Reduced Motion、Reduce Transparency 与 AX5 四个核心页面已验证。
- 真机金额输入提供独立 44pt 清空和收起键盘按钮；高级入口使用带 VoiceOver 标签的高对比皇冠标识。
- AX5 下洞察导航和汇总使用自适应单列布局；记账字段区在键盘出现时可滚动。
- iPhone 收窄为竖屏支持，避免旧方向声明下的横屏窗口异常；iPad 继续支持四方向和多栏布局。
- StoreKit Configuration 和 iOS CI workflow 已加入；App 与 Widget 版本和构建号一致。

## 自动验证

- Simulator App + Widget build：通过。
- 全部单元/集成测试：154 个通过。
- 兼容专项：交易 9 个、预算 6 个、备份/CSV 6 个、订阅 3 个通过。
- iPhone UI/产品：19 个声明用例中 18 个通过，1 个 iPad 专属用例按预期跳过；Light/Dark 动态执行共 19 次通过。
- iPad：侧栏、预算和记账入口专项通过。
- `performAccessibilityAudit`：新用户、恢复页、预算页及首页/流水/洞察/设置通过。
- 组合验收：AX5 + Dark + Increase Contrast + Reduce Motion + Reduce Transparency 通过。
- 视觉截图：iPhone Light/Dark、AX5 核心页面和 iPad Light/Dark 多栏布局均已检查。
- 覆盖升级：77/78/568/4140 笔四轮旧版 Store 的实体、关系、逐账户余额和全内容 checksum 在升级前后完全一致。
- 升级后操作：small/medium/large 各重复 2 轮新增、编辑、删除、撤销、legacy income 和预算汇总，共 96 项断言通过。
- 真实 iPhone 14：1.0.1 的 88 笔 local-only 数据原位覆盖到 2.0.0，checksum、实体、关系和余额完全一致；升级后操作重复 2 轮通过。
- 真实 iPhone UI/产品：最终连续 9 项全部通过，覆盖老用户更新、新用户首笔、预算、免费 iCloud、数据会员墙、支出、转账、编辑、删除撤销及核心页面无障碍。
- UI 回归后升级 store 复核：89 笔、总余额 `25197.83`，与升级后操作预期完全一致，哨兵和关系分布未变化。

## 禁止发布门槛

1. 旧版 App 生成的 local-only 模拟器及真实 iPhone Store 已完成覆盖升级，但仓库仍没有生产旧版/TestFlight 脱敏 local-only 与 CloudKit store fixture。必须用生产 fixture 验证实体计数、余额、关系和 CloudKit 事件后才可进入外部 TestFlight。
2. 当前 AppIcon 是旧资产，1024px 但带 alpha，且没有合格的 Light、Dark、Tinted 账本意象版本。本次会话未提供内置图像生成工具，按 imagegen 规范未使用 CLI 降级或覆盖旧图标。
3. StoreKit Configuration 已建立，但退款、过期和恢复购买仍需在 Xcode StoreKit Transaction Manager 与沙盒账号上做人工状态切换验收。
4. App Store 展示名“简记账 - 简迹”的重名和商标检查必须在 App Store Connect 提交前完成。

## TestFlight 准入顺序

1. 导入生产脱敏旧库 fixture，复用现有审计入口记录升级前后每个实体数量、各账户余额和重复交易检查结果。
2. 在登录与未登录 iCloud、弱网、离线和多设备条件下验证最近 CloudKit 事件与数据收敛。
3. 补齐并校验三套无 alpha 图标资产，在 Light、Dark、Tinted 主屏分别截图。
4. 真机自动 UI 与核心页面审计已通过；仍需补充 VoiceOver/Voice Control 手工任务、Reduce Motion、Reduce Transparency 与 iPad 多窗口回归。
5. 内部 TestFlight 全绿后再开放小范围外部 TestFlight；任何空账本、数量减少、余额突变、重复流水或恢复失败立即停止灰度。
