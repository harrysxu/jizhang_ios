# 简记账 App 升级审计与路线图

| 审计信息 | 内容 |
|---|---|
| 日期 | 2026-07-11 |
| 分支 | `codex/app-upgrade-20260711` |
| 基线 | `origin/main` @ `c96e38c` |
| 范围 | SwiftUI、SwiftData、CloudKit、StoreKit、Widget、App Intents、测试、隐私合规、UI/UX、App Store 增长 |
| 外部页面访问日期 | 2026-07-11 |

## 1. 结论

当前项目已经具备账本、账户、分类、预算、报表、iCloud、小组件、Siri 和订阅等完整功能骨架，视觉完成度也高于普通原型。但它目前不应直接进入功能扩张或大规模推广，发布判断应为 **NO-GO**。

原因不是功能少，而是记账产品最重要的三项基础还不可靠：

1. **账目不能丢**：CloudKit/store 初始化失败时的启动容错路径会删除数据库，交易、导入和删除流程也缺少失败回滚。
2. **数字必须对**：收入账户关系、预算口径、自定义预算、净资产历史、Widget/Siri 预算均存在已确认错误。
3. **承诺必须真实**：界面会在没有真实同步完成信号时显示“已同步”，订阅只锁住同步 UI 而没有锁住实际同步，隐私政策也包含当前实现不具备的能力。

正确的升级顺序是：

`数据可信 -> 录入效率 -> 预算与复盘闭环 -> Apple 平台体验 -> 付费与增长`

建议的市场位置不是“功能最多的记账 App”，而是：

> **无广告、无追踪、Apple 原生的轻记账：几秒完成记录，每笔可撤销，账本可验证备份。**

“不丢账”应作为内部质量目标，不宜在尚未建立迁移、备份和恢复验证前作为绝对营销承诺。

## 2. 已执行验证

| 检查 | 结果 | 说明 |
|---|---|---|
| 远端主干同步 | 通过 | 已执行 `git fetch origin --prune`，新分支直接基于最新 `origin/main` |
| 模拟器构建 | 通过但有警告 | 主 App `1.0.1`，Widget `1.0.0`，Xcode 明确警告扩展版本必须与宿主一致 |
| 单元测试 | 失败，0 个测试真正执行 | 测试宿主在 `CloudKitService.init()` 创建 `CKContainer` 时 `SIGTRAP`，见 `CloudKitService.swift:84` |
| App 图标 | 风险已确认 | 源图和编译后的 AppIcon 都带 alpha；仍需用 Release Archive 的 Validate App 做最终判定 |
| 无障碍实现 | 缺失 | 主工程搜索不到任何 `.accessibility...` 修饰；没有图表可访问描述 |
| iPad 自适应 | 缺失 | 没有 `NavigationSplitView`、size class 或自适应侧栏；现有截图是手机单列的全宽拉伸 |
| CI | 缺失 | GitHub Actions 只有 Pages 发布，没有 build/test/release validation |

测试失败不是“测试不稳定”。崩溃栈明确经过：

`jizhangApp.init -> AppState.init -> CloudKitService.init -> CKContainer(identifier:)`

这意味着仓库虽然已有大量测试文件，但当前主干没有可用的自动回归门禁。

## 3. 发布前阻断项

### P0-1 启动错误处理会删除用户数据库

证据：

- `jizhang/jizhang/App/AppState.swift:89-98`：清库开关会直接删除 SQLite、WAL、SHM；当 App Group `UserDefaults` 初始化失败时，`?? true` 会进入清库路径。正常创建 suite 但键不存在时，`bool(forKey:)` 返回 `false`，代码注释中的“默认 true”并不准确。
- `jizhang/jizhang/App/AppState.swift:137-187`：CloudKit `ModelContainer` 初始化失败后会删除数据库并重试；再次失败时还会先删库再回退到本地 store。

影响：CloudKit store/schema 配置错误或 App Group defaults 异常可能被放大为不可逆数据丢失。

必须改为：

- 使用 `VersionedSchema` 和 `SchemaMigrationPlan`。
- 升级前生成可校验备份，迁移成功后再切换。
- 失败时保留原库，进入只读恢复/导出界面。
- 删除数据库只能是用户明确确认的开发/测试操作，不能是生产容错策略。

### P0-2 交易领域规则互相冲突

证据：

- `AddTransactionViewModel.swift:227-248` 对所有交易设置 `fromAccount`。
- 同文件 `277-281` 收入也修改 `fromAccount`。
- `Transaction.swift:178-181` 的正式模型逻辑却规定收入使用 `toAccount`。
- `TransactionDetailView.swift:114-169` 和 `452-478` 又复制了另一套编辑/删除余额逻辑。

影响：收入账户统计、详情、CSV、编辑、删除和模型测试使用不同语义。新增、编辑、删除还会先改余额再保存，保存失败后没有 `rollback()`，脏数据可能被后续操作提交。

必须改为：

- 建立唯一的 `TransactionService`/账务引擎，所有 App、Widget、Intent 入口共用。
- 明确定义支出、收入、转账、调整、退款/报销的账户影响。
- 新增、编辑、删除必须原子化；失败回滚并向用户显示错误。
- 为已有“收入挂在 fromAccount”的数据提供一次性迁移和校验报告。
- 删除先支持短时撤销，随后演进为软删除/回收站。

### P0-3 多设备余额结构存在覆盖风险

`Account.balance` 是持久化可变快照，每次交易都执行读-改-写；交易和账户又同时通过 CloudKit 同步。两台设备从同一个旧余额各自记账时，两笔交易可以同时存在，但余额记录可能发生最后写入覆盖。

短期方案：

- 每次远程导入后从交易重算并对账。
- 为余额缓存增加 revision、校验和及修复日志。
- 做双 context、双设备、离线后合并的冲突测试。

长期方案：

- 账户保存 `openingBalance`。
- 交易保存不可变分录，转账保存成一组关联 posting。
- `balance` 只作为可重建缓存，不作为唯一事实来源。

### P0-4 预算会跨账本并且自定义周期无效

证据：

- `BudgetFormSheet.swift:38-45` 使用无排序的 `ledgers.first`，分类没有按当前账本过滤。
- `BudgetFormSheet.swift:108-110` 接收了自定义结束日期，但 `167-195` 保存时没有传递。
- `Budget.swift:91-92` 对 custom 直接设置 `endDate = startDate`。

影响：可产生“账本 A + 账本 B 分类”的关系；自定义预算是零长度周期，永远不会正确统计。

修复要求：

- 只接收 `appState.currentLedger`，查询分类时带 ledger predicate。
- 保存并校验 `endDate > startDate`。
- 对月度、年度、自定义、跨月、跨时区、结转和多账本隔离建立测试。
- 首页、预算页、Widget、Siri 共用同一预算计算器，禁止各自实现一套口径。

### P0-5 备份、导入、导出和破坏性操作不可信

已确认问题：

- `DataManagementService.swift:36-64` 删除账本前没有备份。
- `LedgerImportService.swift:61-159` 不校验格式版本，失败不回滚。
- 未知账户/分类/交易类型会静默降级；缺失关系和预算会被静默跳过。
- `BudgetDTO.endDate` 导出后没有恢复。
- `CSVExporter.swift:27-30` 使用带千位分隔符的金额但未按 RFC 4180 引号转义，`1,234.56` 会破坏列结构。
- 备份类型注册为系统 Editor，但 `jizhangApp.onOpenURL` 拒绝非 `jizhang://` URL，从“文件”打开备份不能进入导入。

修复要求：

- 删除、重置、schema 迁移前自动创建本地备份。
- 导入先在 staging context 完整验证版本、引用、计数、金额和校验和，再原子提交。
- 导入结束给出“导入/跳过/修复”摘要，不能静默丢字段。
- CSV 使用结构化 writer、POSIX 数字格式、公式注入防护。
- 建立“当前版本 -> 导出 -> 清库 -> 导入 -> 全量校验”的往返测试。
- 基础备份与导出不应放在会员墙后，这是数据所有权和信任能力。

### P0-6 CloudKit 状态、付费和隐私承诺不一致

证据：

- `CloudKitService.swift:140-147` 只等待 3 秒就显示“已同步”，没有真实 export/import 成功事件。
- `CloudKitService.swift:174` 监听的通知 raw value 不正确，远程变更回调不会按预期触发。
- `AppState.swift:100-104,191-192` 的 store 选择不检查订阅权益；已登录 iCloud 的用户会在读取订阅缓存前启用 CloudKit store。
- `CloudSyncStatusView.swift:48-53` 仅用付费状态隐藏界面；已登录 iCloud 的免费用户仍会使用 CloudKit store。
- `pages/privacy-policy.html:155-192` 声称用户选择启用、可随时关闭且同步采用端到端加密；当前没有同步开关，而且端到端加密取决于用户是否启用 Advanced Data Protection。Face ID/Touch ID 文案也容易被理解为 App 锁，但当前没有 App 内生物识别控制。

产品建议：**把 iCloud 同步作为免费安全能力**。如果坚持收费，必须设计明确的本地/云端两种 store、显式 opt-in 和购买后的无损迁移，不能只遮住入口。

界面只能展示从真实 persistent CloudKit import/export 事件得到的状态。无法强制同步时，应移除“立即同步”按钮，而不是模拟成功。

隐私文案应采用 Apple 的准确表述：第三方 App 数据始终在传输和服务器端加密；只有用户启用 Advanced Data Protection 后，CloudKit 的加密字段和资产才是端到端加密。

### P0-7 发布配置和质量门禁不完整

必须修复：

- 将 App 与 Widget 的 `MARKETING_VERSION`、`CURRENT_PROJECT_VERSION` 统一。
- 让 `CloudKitService`、`SubscriptionManager` 和 store 配置可依赖注入，单元测试不能启动真实 CKContainer。
- UI 测试使用独立数据库并真正处理 `--uitesting --reset`。
- 添加 StoreKit Configuration 和免费/订阅/买断/退款/撤销测试。
- 添加 build + unit + selected UI smoke CI。
- AppIcon asset 当前只配置一个带 alpha 的 1024 图，Dark/Tinted 文件没有加入 asset；改用不透明 raster 或 Icon Composer 正确分层，并执行 Archive Validate。
- README 截图路径缺少 `docs/`，页面当前会破图；README 声明 MIT 但仓库没有 `LICENSE`。
- 官网根页不应只跳隐私政策，应提供产品价值、支持、隐私、条款和下载入口。

## 4. 其他已确认的正确性问题

| 优先级 | 问题 | 证据/影响 |
|---|---|---|
| P1 | 首页预算分子分母不同口径 | `HomeView.swift:38-50` 只汇总已设预算分类的预算，却用全部今日支出相除；会误报超支 |
| P1 | 新设备可能创建重复默认账本 | `DataMigration.swift:41-71` 固定等 2 秒后建账本，但项目自己承认 CloudKit 首次同步可能需数分钟 |
| P1 | Siri 预算范围错误 | `GetBudgetIntent.swift:75-82` 只按账本筛选，历史、未来、年度和自定义预算都会被计入“本月预算” |
| P1 | Widget 预算周期算法错误 | `WidgetDataService.swift:103-108,274-285` 会过滤当前有效预算，但把年度/自定义预算金额也按本月天数平摊 |
| P1 | 历史净资产错误 | `ChartDataProcessor.swift:157` 从当前余额倒推，但只拿选定区间交易，且未排除 excludeFromTotal 账户 |
| P1 | 手工编辑余额破坏审计链 | `AccountFormSheet.swift:154` 直接覆盖余额，不产生可逆调整分录 |
| P1 | 订阅过期可继续访问 | `SubscriptionStatus.isPremium` 不实时检查过期；回前台也不刷新权益 |
| P1 | Debug 永远是高级版 | `SubscriptionStatus.isPremium` 在 DEBUG 无条件 true，使免费路径实际无法测试 |
| P2 | Widget 快捷记账不完整 | Large Widget 的 intent 不导航到记账页；无预算且 0 支出时 Small Widget 会显示超支 |
| P2 | 全表查询会随数据增长变慢 | 首页、流水、报表、Widget 都先取全量再内存过滤；聚合大量运行在 MainActor |
| P2 | 多币种只是模型层能力 | 页面、预算、Siri、Widget 大量硬编码 `¥`、`CNY`、`zh_CN` |
| 待真机验证 | 锁屏财务信息泄露 | Intents 没有认证策略，Info.plist 没有限制锁屏执行；Widget 也没有 privacySensitive |
| 待双机验证 | CloudKit 暂态关系污染 | 迁移会把暂时没有 ledger 关系的对象挂到第一个账本，可能把同步延迟误判为孤立数据 |

## 5. 市场与竞品证据

以下 App Store 数字会随地区和时间变化，仅代表访问日可见信息。

| 产品 | 公开信号 | 对本项目的启示 |
|---|---|---|
| [鲨鱼记账](https://apps.apple.com/cn/app/id1079718756) | 4.9 分、230 万评分、财务榜 #31、197.9 MB；主打 3 秒记账、提醒、小组件、趋势和云同步；包含广告/追踪 | “快”是最强心智。简记账可用无广告、隐私、轻量和无障碍形成反差，但必须先把速度量化 |
| [钱迹](https://apps.apple.com/cn/app/id1473785373) | 4.9 分、2.1 万评分、62.9 MB，公开称 600 万用户；无开屏/信息流/理财推荐，支持买断、家庭、周期账、存钱计划、AI、导入导出和多端 | 最直接对标。仅“无广告”不够，必须在 Apple 原生入口、录入速度和数据可信度上胜出 |
| [随手记](https://apps.apple.com/cn/app/id372353614) | 4.9 分、67 万评分、299.8 MB；功能极全，但精选评论抱怨广告、社区、花哨和复杂 | 不要走信息流、理财推荐和功能堆叠路线 |
| [咔皮记账](https://apps.apple.com/cn/app/id6738811698) | AI 文本/图片/语音和复盘受欢迎；评论也出现日期误判、余额错误和历史账目丢失信号 | AI 只能“建议 + 预览 + 确认”，绝不能静默改写财务事实 |
| [YNAB](https://apps.apple.com/us/app/ynab/id1010865877) | 高价订阅仍有大量用户，核心售卖的是方法、目标和减少财务焦虑，而不是图表数量 | 用户愿为明确结果付费；月度复盘应给一条可执行建议 |
| [Copilot Money](https://apps.apple.com/us/app/copilot-track-budget-money/id1447330651) | 原生设计、自动分类、订阅识别和克制洞察形成高端体验 | “自动但可编辑”和原生质感有价值，不需要复制银行/投资全聚合 |

市场共同痛点是：

- 功能越来越多，记一笔却越来越慢。
- 自动化误判后难以纠正。
- 同步状态不透明，重复、缺失或余额不一致。
- 历史数据被产品绑定，导出和迁移困难。
- 订阅墙太早、广告和推荐破坏信任。

因此本项目不应优先追赶银行自动同步、投资行情、社区或大模型聊天。先把“极快、极净、可信、原生”做透，市场位置反而更清楚。

## 6. Apple 平台变化带来的机会

### iOS 26 已经是主流，不是前瞻

Apple 以 2026-06-07 的 App Store 活跃设备统计：

- 79% 的全部 iPhone 使用 iOS 26；近四年设备为 86%。
- 68% 的全部 iPad 使用 iPadOS 26；近四年设备为 79%。

这意味着 Liquid Glass 和新的平台导航应进入当前路线，而不是“以后再说”。但不需要从零重画：Apple 明确建议现有 App 先使用标准 SwiftUI 组件自动获得新外观，减少自定义导航背景和自制玻璃效果。

具体建议：

- 用系统 `TabView`、`NavigationStack`、`toolbar`、Sheet 取代自定义 TabBar/导航栏。
- iPad 使用 `NavigationSplitView` 或自适应 sidebar，不再全宽拉伸手机单列。
- Liquid Glass 只用于顶层导航和关键控件，内容和账目本身保持清晰、安静。
- 测试 Reduce Transparency、Reduce Motion、高对比度和各种 Dynamic Type。

### App Intents 是本项目最有价值的平台优势

现有 Siri/Widget 是好基础，但所有入口必须复用同一个账务引擎。建议按顺序补齐：

1. 新增账单。
2. 重复上一笔。
3. 查询本月支出/剩余预算。
4. 打开指定账本或分类。
5. Spotlight 索引账本和分类。
6. Action Button、Control Center、Widget 复用同一 Intent。

Intent 必须有稳定跨设备 ID、幂等保护和 AppIntentsTesting 回归测试。

### 端侧 AI 只适合作为增强

Apple Foundation Models 在 iOS 26+ 支持结构化输出、实体抽取、图像理解和工具调用，适合做：

- “午饭 38 微信”自然语言转账单草稿。
- 小票图片抽取金额、日期、商家和候选分类。
- 月度消费摘要。

但它只在支持 Apple Intelligence 的设备上可用，部分新 API 仍为 Beta，不能成为基本记账路径。任何 AI 结果都必须展示预览、置信度和修改入口，由用户确认后保存。

## 7. 目标体验

### 首次使用

遵循 Apple HIG：快速、可跳过、通过操作学习，而不是长教程。

建议不超过三步：

1. 选择常用币种和一个默认账户。
2. 直接完成第一笔真实或练习账单。
3. 在成功后用上下文提示介绍预算、Widget/Siri。

目标：首次会话记账率可衡量，首笔记账中位时间小于 60 秒。

### 日常记账

当前记账页已经有最近账户、快速分类和推荐服务的代码基础，但推荐金额没有显示，分类推荐也没有真正接入。

目标流程：

1. 打开即聚焦金额。
2. 显示支出/收入/转账分段控件。
3. 默认带出最近或预测账户、分类。
4. 显示“重复上一笔”、常用金额和常用备注。
5. 日期、时间、标签、备注收进“更多”，不占据主任务。
6. 保存后出现“已记 ¥X · 撤销”，不弹成功对话框。
7. 支持连续记账。

目标：常规支出不超过 3 次点击，记一笔中位时间小于 8 秒。

### 首页

现有首页第一屏被大号净资产、今日支出和 7 日图表占满，最近流水接近底栏且不可点击。建议改为：

- 顶部：本月可花/预算余量，净资产作为可隐藏次要信息。
- 主区：今日状态和一条明确行动，例如“餐饮预算剩余 18%”。
- 最近流水：可点击查看、编辑和撤销。
- 快捷动作：记一笔、重复上一笔、搜索。
- 无预算时直接提供“创建第一个预算”，而不是被动文字。

### 预算与洞察

预算应从“设置”移到核心信息架构。免费用户至少可以体验 1 个总预算或分类预算，Pro 再提供无限预算、结转、预测和提醒。

首页应区分：

- 预算覆盖分类支出。
- 未纳入预算支出。
- 本月剩余预算。
- 按剩余天数计算的安全日均，而不是简单把原预算平均到每一天。

“报表”建议升级为“洞察”：先回答哪里变化、为什么、下一步做什么，再让用户下钻图表。图表需提供文字摘要、可访问描述和数据表替代。

### iPad 与无障碍

当前项目有 286 处固定尺寸/字号布局，没有显式 accessibility 修饰。

必须达到：

- iPad 侧栏 + 列表/详情双栏，支持横竖屏和多窗口。
- VoiceOver 可以完成新增、查看、编辑、删除/撤销全流程。
- AX5 字号无截断，点击区域至少 44pt。
- 正负和预算状态不能只依赖红/绿颜色。
- 图表提供摘要、Audio Graph/ChartDescriptor 或表格替代。
- 设置中提供金额隐私、App 锁和 Widget 隐私选项。
- 完成后在 App Store 发布 Accessibility Nutrition Labels。

## 8. 付费模型建议

商品加载失败时，页面会以禁用态展示 ¥3 / ¥28 / ¥38 兜底价；正常路径使用 StoreKit 的 `displayPrice`，因此真实价格和价差必须在 App Store Connect 核对。无论真实价格如何，年订阅仍硬编码“每月 ¥2.3，节省 23%”并固定标记为推荐，在其他币种或价格调整后会成为错误元数据。

建议原则：

- 免费核心账本长期可用，不强制注册、不首启付费墙。
- iCloud 基础同步、基本备份/导出、删除和数据所有权能力免费。
- 免费提供一个预算，让用户先体验价值。
- 一次性买断作为与“纯净可信”定位最一致的主方案。
- 只有持续提供价值或产生成本的功能才适合订阅，例如家庭实时协作、持续 AI/PCC、持续更新的高级洞察。
- 若保留年费和买断，需在 App Store Connect 核对价格间距并通过真实转化数据验证，不要在代码里写死折扣。
- 使用 StoreKit 原生视图或至少完整支持恢复购买、管理订阅、退款帮助和本地 StoreKit 测试。
- 终身产品 CTA 必须写“购买终身版”，不能写“立即订阅”。

Apple 审核规则要求自动续订提供持续价值并跨用户设备可用。仅将静态本地功能切成月费，不利于审核解释，也不利于口碑。

## 9. 分阶段路线图

### 阶段 0：可信发布基线（建议 2-3 周）

目标：任何推广前先达到可恢复、可测试、数字一致。

- 移除所有自动删库逻辑，建立 VersionedSchema/MigrationPlan。
- 统一交易服务，修复收入关系和失败回滚，迁移已有错误数据。
- 修复预算跨账本、自定义周期和首页口径。
- 修复导入、备份、CSV、文件打开流程。
- 用真实事件展示 CloudKit 状态，决定同步免费或实现真正的付费 store。
- 修复测试宿主、版本号、图标、隐私政策和 CI。
- 给生产迁移准备旧库 fixture 和恢复演练。

验收门槛：

- build 无 warning。
- unit/integration 全绿，关键 UI smoke 全绿。
- 当前线上/测试旧库迁移成功率 100%。
- 导出导入往返字段和余额误差为 0。
- 保存失败不留下交易或余额变化。
- 双设备离线合并后交易数、余额和预算一致。
- 破坏性操作都有备份或撤销。

### 阶段 1：首笔与日常效率（建议 2-3 周）

- 交互式首次使用。
- 金额优先的快速记账、推荐分类/金额、重复上一笔。
- 保存后的可见确认、撤销和连续记账。
- 首页压缩净资产，最近流水可进入详情。
- 修复 Widget deep link，扩展 App Intents。

核心指标：首笔时间、首次会话记账率、记一笔中位时间、点击数、保存失败率、分类二次修改率。

### 阶段 2：留存闭环（建议 3-4 周）

- 免费首个预算，正确的本月余量和安全日均。
- 可选的 80%/100% 预算提醒和每周回顾。
- 周期账、退款/报销、订阅识别、批量编辑和强搜索。
- 第 7 笔成功记账或首次月度复盘后请求系统评分。
- 设置增加帮助、反馈、隐私、安全和数据归属。

核心指标：首周预算创建率、每周有效记账天数、D7/D30 留存、提醒到记账转化、评分率、通知关闭率。

### 阶段 3：平台体验和增长（建议 3-4 周）

- 标准系统导航、iOS 26 Liquid Glass、iPad 双栏/多窗口。
- Dynamic Type、VoiceOver、Reduced Motion、无障碍标签。
- 统一币种/Locale，建立 String Catalog。
- 重做产品官网、README 和 App Store 素材。
- 优化上下文付费墙、StoreKit 视图和价格结构。

核心指标：产品页转化、自然搜索占比、iPad 活跃、VoiceOver 核心流程成功率、付费页到购买、退款和取消率。

## 10. 增长执行

### 商店页

Apple 明确指出搜索结果优先看到前 1-3 张截图。建议第一组素材只讲三件事：

1. 几秒记一笔。
2. 本月还能花多少。
3. 无广告、无追踪、本地优先。

后续展示 Widget/Siri、可验证备份、iPad/深色模式。不要把功能列表截图当首屏。

使用 Product Page Optimization 同时测试最多 3 组图标/截图/预览；用 Custom Product Pages 分别承接“极简无广告”“系统快捷记账”“预算习惯”人群。Apple 公布 CPP 平均可提升约 2.5 个百分点，但仍需以本 App 实际数据为准。

### 品牌与可发现性

“简记账/极简记账”搜索结果高度拥挤，且对 bundle ID 的精确公开搜索没有出现可确认的本 App 商店页。是否已经上架需在 App Store Connect 核对；无论是否上架，都应建立更独特、可记忆、可搜索的品牌词，功能价值放在副标题而不是继续堆进名称。

官网应从“隐私政策跳转器”升级为真实产品页，并提供：

- 明确的一句话价值。
- 真实 App 截图和 30 秒内预览。
- App Store 下载入口。
- 支持、反馈、隐私、条款、版本记录。
- 针对搜索引擎的标题、描述和结构化元数据。

### 评分和反馈

遵循 Apple HIG：只在用户已经成功获得价值的自然停顿点请求评分，例如第 7 笔成功记录或第一次完成月度复盘；首次启动、同步失败、刚删除或刚遇到错误时不请求。使用系统 `RequestReviewAction`，并及时回复 App Store 评论。

### 衡量与隐私

项目当前承诺不收集行为数据。不能为了增长悄悄加入第三方分析 SDK。

建议分两层：

- 先使用 App Store Connect 的曝光、产品页转化、下载、留存、崩溃和订阅数据，加上 TestFlight 访谈。
- 若确实需要自定义漏斗，先做产品和隐私决策，采用明确披露、最小化、匿名聚合或用户自愿分享诊断；同步更新隐私政策和 App Privacy Details。

## 11. 暂不建议做

- 银行卡自动同步和投资行情聚合。
- 社区、信息流、理财产品推荐或广告变现。
- 强制注册后才能记账。
- AI 自动静默入账或自动修改历史数据。
- 在数据安全修复前大规模重做视觉。
- 为追 Liquid Glass 给每个卡片叠加玻璃材质。
- 仅靠隐藏 UI 给 CloudKit 做会员权限。
- 以 iOS 27/Beta API 作为基本记账依赖。

## 12. 建议立即实施的第一个开发包

第一个代码包应严格限定为“数据安全与可发布性”，不夹带视觉重构：

1. `AppState` 安全启动、独立 UI Test store、VersionedSchema/MigrationPlan。
2. 统一交易服务、收入迁移、原子新增/编辑/删除、撤销。
3. 预算账本隔离、自定义结束日期和统一预算计算器。
4. 版本化导入、自动备份、RFC 4180 CSV。
5. 真实 CloudKit 状态和明确同步产品策略。
6. 测试依赖注入、StoreKit config、CI。
7. 版本号、AppIcon、隐私政策、README/LICENSE 修复。

完成这批后，再开始快速记账和首页升级。否则新交互只会把更多用户带到不可靠的数据层上。

## 13. 主要外部来源

### Apple 官方

- [App Store iOS/iPadOS usage](https://developer.apple.com/support/app-store/)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Human Interface Guidelines: Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)
- [Human Interface Guidelines: Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- [Human Interface Guidelines: In-app purchase](https://developer.apple.com/design/human-interface-guidelines/in-app-purchase)
- [Human Interface Guidelines: Ratings and reviews](https://developer.apple.com/design/human-interface-guidelines/ratings-and-reviews)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Creating your product page](https://developer.apple.com/app-store/product-page/)
- [Product Page Optimization](https://developer.apple.com/app-store/product-page-optimization/)
- [Custom Product Pages](https://developer.apple.com/app-store/custom-product-pages/)
- [Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)
- [SwiftData SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)
- [CloudKit](https://developer.apple.com/icloud/cloudkit/)
- [iCloud data security overview](https://support.apple.com/en-us/102651)
- [WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [Foundation Models](https://developer.apple.com/documentation/FoundationModels)
- [WWDC26: Principles of great design](https://developer.apple.com/videos/play/wwdc2026/250/)
- [WWDC26: App Intents](https://developer.apple.com/videos/play/wwdc2026/345/)
- [WWDC26: AppIntentsTesting](https://developer.apple.com/videos/play/wwdc2026/295/)

### 竞品与问题信号

- [鲨鱼记账 App Store](https://apps.apple.com/cn/app/id1079718756)
- [钱迹 App Store](https://apps.apple.com/cn/app/id1473785373)
- [随手记 App Store](https://apps.apple.com/cn/app/id372353614)
- [咔皮记账 App Store](https://apps.apple.com/cn/app/id6738811698)
- [YNAB App Store](https://apps.apple.com/us/app/ynab/id1010865877)
- [YNAB Pricing](https://www.ynab.com/pricing)
- [Copilot Money App Store](https://apps.apple.com/us/app/copilot-track-budget-money/id1447330651)
- [Monarch: Troubleshooting Duplicate Transactions](https://help.monarch.com/hc/en-us/articles/32110313427604-Troubleshooting-Duplicate-Transactions)
- [Copilot: Improving Connections Performance](https://help.copilot.money/en/articles/9899887-improving-connections-performance)

## 14. 说明

- 竞品单条评论只作为问题发现信号，不代表问题发生率。
- App Store 评分、排名、版本和价格均为动态数据。
- 本报告没有访问 App Store Connect，因此无法确认当前上架状态、真实转化、留存和收入。
- 多设备余额覆盖、锁屏信息可见性和图标上传结果已标记为需要专项验证的项目，未当作已经复现的线上事故。
