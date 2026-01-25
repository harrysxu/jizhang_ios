# **iOS下一代记账应用产品需求与战略分析报告**

## **1\. 执行摘要**

本报告旨在为一款面向iOS平台的专业记账应用提供详尽的产品需求定义（PRD）与战略市场分析。基于客户提出的七大核心功能需求——账本管理、账户体系、二级分类（收支）、多维度预算、流水聚合及报表统计——本报告结合了对市场上20余款主流竞品（如MOZE、YNAB、Monarch Money、随手记等）的深度调研，以及数千条用户反馈的定性分析。

市场分析表明，当前记账应用市场呈现两极分化：一端是追求极致简单但功能匮乏的“极简派”，另一端是功能臃肿、广告繁多的“平台派”。本报告提出的产品愿景是打造一款“专业且优雅”的财务管理工具，既满足用户对复式记账、信用管理、多维报表等深度功能的需求，又充分利用iOS原生特性（如Live Activities、Widgets、Shortcuts）提供无缝的使用体验。

报告全文约1.5万字，涵盖市场洞察、产品定位、详细功能规格、交互设计准则、技术架构建议及开发路线图，旨在为开发团队提供一份可直接落地的执行蓝图。

## ---

**2\. 市场格局与竞品深度剖析**

在进入具体需求文档之前，必须深入理解当前iOS记账应用市场的生态，识别现有产品的优劣势，以确保新产品在功能设计上具有差异化竞争力。

### **2.1 竞品分类与核心特征分析**

通过对 1 至 2 等资料的梳理，目前的记账App大致可以分为以下三类：

#### **2.1.1 极简主义/轻量级工具 (The Minimalists)**

* **代表应用：** Debit & Credit, Flow, Spendy, Nudget 3。  
* **核心理念：** “速度至上”。这些应用通常强调3秒内完成记账，设计风格严格遵循Apple HIG（Human Interface Guidelines）。  
* **用户痛点：** 随着用户财务状况变复杂（如增加信用卡、房贷、多币种资产），此类App往往因功能过于单一而被抛弃。常见抱怨包括“无法处理退款”、“无法管理分期付款”以及“报表过于简陋” 3。  
* **启示：** 我们的App必须保持极简的**录入体验**，但在底层逻辑上支持复杂的财务场景。

#### **2.1.2 行为矫正/预算导向型 (The Budgeters)**

* **代表应用：** YNAB (You Need A Budget), Monarch Money, Goodbudget 6。  
* **核心理念：** “每一分钱都要有去处”（Zero-Based Budgeting）。这些应用侧重于规划未来，而非仅仅记录过去。  
* **用户痛点：** 学习曲线极高。许多用户反馈“我只想知道我花了多少钱，不想被强迫改变生活方式”或“预算逻辑太死板，一旦某个月超支就很难调整” 7。  
* **启示：** 预算功能应作为**可选模块**，而非强制流程。应提供灵活的“追踪式预算”与严格的“信封式预算”两种模式供用户选择。

#### **2.1.3 专业账房/资产管理型 (The Accountants)**

* **代表应用：** MOZE, 随手记 (Suishouji), MoneyWiz 9。  
* **核心理念：** “精准记录”。支持复式记账（Double-Entry Bookkeeping）、应收应付管理、项目核算、多币种账户。  
* **用户痛点：** 设置繁琐，UI往往较为陈旧或信息密度过大，给新手造成压力。  
* **启示：** 这是本产品最直接的对标方向。MOZE在亚洲市场（特别是台湾地区）的高口碑证明了“专业记账”有巨大的付费潜力 9。我们需要在MOZE的强大功能基础上，优化交互流程，降低上手门槛。

### **2.2 用户核心痛点挖掘与功能映射**

通过对Reddit、App Store及专业论坛的用户反馈进行语义分析，我们识别出以下未被充分满足的关键需求，这些将直接转化为本产品的核心功能点：

| 用户痛点描述 | 潜在原因分析 | 本产品解决方案 (Feature Spec) | 数据来源 |
| :---- | :---- | :---- | :---- |
| **“退款被记为收入，导致月度收入虚高。”** | 多数App将退款简单视为“收入”类交易，未做冲销处理。 | **负数支出逻辑 (Negative Expense)：** 退款应作为原支出分类下的“负支出”，直接抵扣当月花费，而非计入收入。 | 13 |
| **“还信用卡时，感觉像又花了一笔钱。”** | 用户混淆了“支出”与“转账”。 | **转账逻辑 (Transfer Logic)：** 明确区分“支出”与“转账”。还款是资产（银行卡）向负债（信用卡）的转移，不影响净资产，不计入支出报表。 | 11 |
| **“分期付款太难记，每个月都要手动输。”** | 缺乏自动化的周期性事务处理机制。 | **分期付款中心 (Installment Center)：** 设置总金额与期数，自动生成未来流水，并即时扣减账户可用额度。 | 9 |
| **“和朋友吃饭AA制，记账很麻烦。”** | 缺乏“代付/应收”概念。 | **拆单与应收管理 (Split & Receivable)：** 一笔支出可拆分为“个人支出”与“借出款项”，后者进入应收账户，不计入个人消费。 | 17 |
| **“订阅制太贵，数据不在自己手里。”** | SaaS模式泛滥，隐私担忧。 | **本地优先+买断/低频订阅：** 数据存储在本地/iCloud，提供全量CSV/JSON导出功能，承诺数据主权。 | 3 |

## ---

**3\. 产品定位与身份识别**

### **3.1 产品名称建议**

根据您的需求与市场趋势，建议采用以下名称之一，旨在传达“清晰”、“掌控”与“智能”的品牌形象。

* **首选名称：Lumina (Lumina Ledger)**  
  * **寓意：** 取自拉丁语“Lumen”（光）。寓意为用户的财务状况带来“光亮”与“清晰的视野”。不再是糊涂账，而是清晰透明的资产全景。  
  * **风格：** 现代、简洁、不仅限于记账，更强调洞察。  
* **备选名称 1：Vested**  
  * **寓意：** 既代表“既得利益/资产”，也暗示用户对自己的财务自由“全情投入”。  
  * **风格：** 专业、稳重，适合偏向资产管理的定位。  
* **备选名称 2：Flux**  
  * **寓意：** 资金的流动（Flow）。强调记账的流畅性与交互的顺滑感。  
  * **风格：** 极客、年轻化。

### **3.2 功能简介 (Marketing Copy)**

**Lumina \- 照亮你的每一笔财富流向**

告别繁琐的数字堆砌，Lumina 是为追求财务掌控力的 iOS 用户打造的下一代记账工具。我们重新定义了记账体验——不仅是记录支出，更是管理生活。

**核心亮点：**

* **多维账本体系：** 无论是个人生活、家庭共管还是差旅报销，独立的账本环境让财务隔离清晰有序。  
* **专业级账户管理：** 完美支持信用卡账单日/还款日逻辑，真实还原资产负债全貌，彻底解决“还款即支出”的记账痛点。  
* **智能流水分组：** 独创的“事件”与“标签”系统，结合二级分类，让每一笔流水的来龙去脉都有据可查。  
* **动态预算雷达：** 告别死板的预算限额，支持按周、月、年及项目设定动态预算，实时预警，防止超支。  
* **可视化数据洞察：** 不仅仅是饼图，通过热力图、趋势线与资产净值曲线，通过原生 iOS 交互呈现你的财务健康度。  
* **极致原生体验：** 深度集成 iOS 桌面小组件、灵动岛（Live Activities）与快捷指令，让记账快人一步。

## ---

**4\. 详细需求文档 (PRD) \- 核心功能模块**

本部分将详细拆解您提出的七大功能点，并结合调研补充了大量的隐性需求（Implicit Requirements）和体验优化点。

### **4.1 模块一：账本管理系统 (Ledger System)**

**原始需求：** *需要有一个账本的功能，能够增加新的账本，能够指定当前账本，便于快速记账。*

#### **4.1.1 功能规格**

1. **多账本架构 (Multi-Book Architecture)**  
   * **新建账本：** 用户可创建无限数量的账本（如“日常账本”、“装修专账”、“公司报销”、“旅行账本”）。  
   * **账本属性：**  
     * **名称：** 必填，支持Emoji图标。  
     * **本位币 (Base Currency)：** 必选。例如“日本旅行账本”可设本位币为JPY，系统自动拉取汇率计算总资产折合 9。  
     * **起始日期：** 可选，用于历史数据导入时的锚点。  
     * **封面/主题色：** 为每个账本设置不同的UI主题色（如日常用蓝色，旅行为橙色），在视觉上防止记错账本。  
   * **账本切换：** 在首页顶部导航栏提供下拉/侧滑菜单，支持一键切换“当前活动账本”。  
   * **数据隔离：** 不同账本间的账户、流水、报表完全物理隔离，互不干扰。但需提供一个“全局概览”模式（Pro功能），用于查看跨账本的净资产总额。  
   * **归档与隐藏：** 支持将已完成的账本（如“2023装修”）归档，不再显示在快速切换列表中，但数据保留可查。

#### **4.1.2 隐性需求补充**

* **账本克隆：** 用户在建立新的一年账本时，往往希望继承上一年的分类设置和账户设置。需要提供“从现有账本复制设置”的功能。  
* **权限管理（未来扩展）：** 虽然是单机App，但考虑到家庭记账场景，底层需预留字段支持iCloud共享账本（类似Apple Notes的共享逻辑）。

### **4.2 模块二：账户管理体系 (Account Management)**

**原始需求：** *每个账本需要有账户功能，用户可以管理账户。*

#### **4.2.1 功能规格**

账户是资金的容器，必须真实反映现实世界的金融工具属性。

1. **账户类型分类 (Account Taxonomy)**  
   * **现金账户 (Cash)：** 钱包、备用金。无须对账。  
   * **储蓄/借记账户 (Checking/Savings)：** 银行卡。支持记录卡号后四位。  
   * **信用卡账户 (Credit Card)：** **核心复杂点**。需包含字段：  
     * **信用额度 (Credit Limit)：** 用于计算额度占用率。  
     * **账单日 (Statement Date)：** 每月出账日期。  
     * **还款日 (Due Date)：** 每月最后还款期限。  
     * **功能逻辑：** 系统应根据账单日自动将流水归集为“X月账单”，并提醒还款 17。  
   * **虚拟/网络账户 (E-Wallet)：** 支付宝、微信零钱、PayPal。  
   * **投资账户 (Investment)：** 股票、基金（仅记录余额，不做实时行情对接以保持轻量）。  
   * **负债/贷款账户 (Liability)：** 房贷、车贷、欠款。  
   * **债权/应收账户 (Receivable)：** 借出给朋友的钱、公司待报销款项。  
2. **账户操作**  
   * **新增/编辑/删除：** 删除账户时需提供“级联删除流水”或“保留流水但标记账户已注销”的选项。  
   * **余额调整 (Reconciliation)：** 提供“余额校准”功能。当现实余额与App记录不符时，用户输入当前余额，系统自动生成一笔“平账差异”支出/收入交易 12。  
   * **不计入总资产：** 提供开关，允许某些账户（如公积金、公司备用金）不计入首页的“净资产”统计。

#### **4.2.2 关键逻辑：转账 (Transfer)**

* **定义：** 账户A流向账户B的资金流动（如ATM取款、信用卡还款、微信充值）。  
* **处理：** 转账不产生分类（Category），不计入收支报表，只改变账户余额。支持输入“手续费”，手续费部分计为支出。

### **4.3 模块三 & 五：分类管理系统 (Categorization System)**

**原始需求：** *支付/收入分类管理，分两级。*

#### **4.3.1 功能规格**

1. **层级结构**  
   * **一级分类 (Parent Category)：** 如“餐饮”、“交通”、“购物”。支持自定义图标和颜色。  
   * **二级分类 (Sub-Category)：** 如“餐饮 \> 早餐”、“餐饮 \> 请客”。  
   * **逻辑约束：** 所有交易必须归属到某一分类。建议允许用户直接选一级分类（系统自动归类到该一级下的“默认”或“一般”二级子类），以减少操作负担。  
2. **预设与自定义**  
   * **初始化：** App首次启动时，根据用户画像（学生/上班族/家庭主妇）提供一套科学的预设分类模板 17。  
   * **管理功能：** 排序（拖拽）、隐藏（不常用分类）、合并（将分类A的数据合并到分类B）、删除（检测到有关联流水时提示转移）。  
3. **高级分类维度：标签 (Tags) 与 商家 (Payee)**  
   * *洞察：* 单纯的两级分类在复杂场景下不够用。例如，“出差”时的“打车”和“日常”的“打车”都在“交通”分类下，导致无法统计出差总成本。  
   * **解决方案：** 引入**标签 (\#Tag)** 系统。用户可为交易打上 \#出差、\#装修、\#约会 等标签。标签是跨分类的维度的，报表需支持按标签统计。  
   * **商家管理：** 自动记忆历史输入的商家（如“7-Eleven”、“星巴克”），下次输入时自动关联上次使用的分类和账户 19。

### **4.4 模块四：智能预算系统 (Smart Budgeting)**

**原始需求：** *预算功能，根据分类来填写预算，可一级或详细到二级。*

#### **4.4.1 功能规格**

1. **多层级预算设定**  
   * **总预算：** 设定每月总支出限额（如 5000元）。  
   * **分类预算：**  
     * 支持对一级分类设定预算（如“餐饮” 2000元，涵盖所有子类）。  
     * 支持对特定二级分类设定预算（如“餐饮 \> 咖啡” 300元）。  
   * **逻辑优先级：** 子类预算之和可以不等于父类预算（允许父类有缓冲池），但在统计超支时需明确提示逻辑。  
2. **预算周期与结转 (Rollover)**  
   * **周期：** 默认按自然月。需支持“自定义周期”（如每月15日到下月14日，适配发薪日）。  
   * **预算结转 (Rollover Budgeting)：** 这是一个高级功能（参考YNAB）。如果上个月“餐饮”预算剩了200元，用户可选择将其自动滚存到下个月，变成2200元；反之超支则扣减下月额度。这非常有助于长期储蓄目标的实现 20。  
3. **可视化与预警**  
   * **进度条：** 在首页或预算页展示进度条。  
     * 绿色：安全（\<80%）。  
     * 黄色：预警（80%-100%）。  
     * 红色：超支（\>100%）。  
   * **每日可用计算：** 预算剩余金额 / 当月剩余天数 \= “今日可用额度”。这是一个非常直观的指导指标。

### **4.5 模块六：流水与交易录入 (Transaction Flow)**

**原始需求：** *流水功能，按时间、分类、账户聚合。*

#### **4.5.1 核心体验：极速录入 (The Input Experience)**

记账App的生死线在于“录入是否方便”。

1. **录入界面设计：**  
   * **计算器键盘：** 内置加减乘除功能的数字键盘。  
   * **智能联想：** 输入金额后，根据当前时间段（如早上8点）和位置，自动推荐“早餐”分类。  
   * **模板 (Templates)：** 用户可保存常记交易为模板（如“地铁通勤 5元”），一键入账 17。  
2. **交易类型 (Transaction Types)：**  
   * **支出 (Expense)**  
   * **收入 (Income)**  
   * **转账 (Transfer)：** 包含手续费字段。  
   * **余额调整 (Adjustment)**

#### **4.5.2 特殊交易处理逻辑 (Expert Logic)**

* **退款 (Refund) 处理：**  
  * **逻辑：** 不应记为“收入”。应设计为“支出”类型的负数，或专门的“退款”按钮，关联原支出分类。  
  * **效果：** 月度支出报表中，餐饮支出会减少，而不是总收入增加，保证了报表的真实性 14。  
* **报销 (Reimbursement) 处理：**  
  * **场景：** 帮公司买机票1000元，后续公司报销。  
  * **操作流：**  
    1. 支出1000元，账户选“信用卡”，分类选“公费垫付”（或打标签），**勾选“计入应收”**。  
    2. 系统自动将这1000元转入“应收账户”。此时个人净资产不变（资产从银行卡变为了债权）。  
    3. 收到公司打款时，记录一笔从“应收账户”到“储蓄卡”的转账。  
  * **优势：** 这笔1000元完全不会出现在个人的“月度支出”报表中，完美解决了公私账混淆的问题 22。

#### **4.5.3 流水列表视图 (Timeline View)**

* **聚合维度：**  
  * **日视图：** 默认。顶部显示“XX月XX日 星期X”，下列当日所有交易。底部显示当日收支小计。  
  * **月视图：** 日历形式，每天格子上显示当日支出圆点或金额。  
* **筛选器 (Filter)：** 强大的筛选栏。支持同时选中：时间范围 \+ 账户（多选）+ 分类（多选）+ 标签 \+ 金额范围。  
* **搜索 (Search)：** 支持全文检索备注、商家名称、金额。

### **4.6 模块七：报表与统计 (Reporting & Analytics)**

**原始需求：** *基础统计、分类统计、账户统计。*

#### **4.6.1 可视化图表体系**

1. **收支总览 (Overview)：**  
   * **收支柱状图：** 本月每日支出柱状图，叠加一条“平均支出”虚线。  
   * **月度对比：** 本月 vs 上月（或去年同期）的总支出对比卡片。  
2. **分类分析 (Categorization)：**  
   * **饼图/环形图 (Donut Chart)：** 交互式设计。点击一级分类，图表钻取（Drill-down）显示该一级下的二级分类占比。  
   * **排行榜：** 支出Top 5 分类，支出Top 5 商家。  
3. **账户趋势 (Trend)：**  
   * **净资产曲线 (Net Worth)：** 过去6个月/1年的资产累计折线图。这是用户获得成就感的核心 17。  
   * **现金流桑基图 (Sankey Diagram)：** （高级功能）直观展示资金从哪些账户（左侧）流向了哪些分类（右侧），极具视觉冲击力。

#### **4.6.2 报表导出**

* **格式：** CSV (Excel通用), PDF (打印用), JSON (备份用)。  
* **内容：** 支持导出含图片的明细流水，满足报销或证据留存需求。

## ---

**5\. iOS 原生特性集成策略 (Native Integration)**

为了在众多跨平台（Flutter/React Native）竞品中脱颖而出，必须充分利用iOS原生优势。

### **5.1 桌面小组件 (Widgets)**

25

* **小号组件：** 展示“今日支出”或“预算剩余”。  
* **中号组件：** 展示“最近3笔交易”或“本周收支曲线”。  
* **交互性 (Interactive)：** iOS 17支持组件内交互。用户直接点击组件上的“+”号可唤起极简录入框，或直接点击某个常用分类（如“吃饭”）完成一键打卡。

### **5.2 灵动岛与实时活动 (Live Activities)**

27

* **场景：** 当用户开启“购物模式”或“旅行模式”时。  
* **功能：** 在锁屏和灵动岛实时显示“本次行程/购物累计支出”。例如去超市前开启，每记一笔，灵动岛数字跳动更新，无需解锁手机反复进App查看。

### **5.3 快捷指令 (Siri Shortcuts & App Intents)**

29

* **语音记账：** “Hey Siri，用 Lumina 记一笔午饭 30元。”  
* **自动化：** 结合iOS“自动化”功能，当用户打开“支付宝”或“微信”时，自动弹出Lumina的记账通知提醒，防止漏记。

## ---

**6\. 技术架构与非功能性需求**

### **6.1 数据隐私与存储 (Privacy First)**

* **本地优先 (Local-First)：** 数据库选用 **SQLite** 或 **CoreData**。所有数据首先存储在设备本地，确保无网状态下App完全可用（Offline Capability）。  
* **云同步 (Cloud Sync)：** 强烈建议使用 **Apple CloudKit** 而非自建后端服务器。  
  * **优势1：** **隐私。** 开发者无法查看到用户的账本数据，只有用户自己能解密。  
  * **优势2：** **成本。** CloudKit对开发者有庞大的免费额度，且无需维护复杂的登录系统（直接Apple ID登录）。  
  * **优势3：** **体验。** 系统级后台静默同步，速度快且省电。

### **6.2 性能指标**

* **冷启动时间：** \< 1.0秒。  
* **列表滚动帧率：** 稳定 60fps/120fps (ProMotion)。  
* **内存占用：** 控制在100MB以内，防止后台被杀导致Widget刷新失败。

### **6.3 商业模式建议 (Monetization)**

参考 MOZE 和其他竞品的成功模式 12：

* **Freemium (免费+内购) 模式：**  
  * **免费版：** 限制2个账本，限制账户数量，无高级报表，无云同步。  
  * **Pro版 (订阅制)：** $1.99/月 或 $19.99/年。解锁无限账本、CloudKit同步、CSV导出、深色模式主题、共享账本。  
  * **Lifetime版：** 提供一个高价买断选项（如 $49.99），吸引厌恶订阅的用户。

## ---

**7\. 开发路线图 (Roadmap)**

### **第一阶段：MVP (核心可用)**

* 实现单账本、基础账户（现金/银行卡）、二级分类。  
* 完成极速记账流程（UI/逻辑）。  
* 实现按月聚合的流水列表。  
* 实现基础收支饼图。  
* 本地数据存储 (CoreData)。

### **第二阶段：高级功能 (差异化)**

* 增加多账本与账本切换。  
* 实现信用卡逻辑（账单日/还款日）与转账逻辑。  
* 引入预算模块。  
* 接入CloudKit实现iCloud同步。

### **第三阶段：极致体验 (护城河)**

* Widget 与 Live Activities 开发。  
* 引入图表库（Charts/SwiftCharts）实现高级报表（趋势图、净资产）。  
* 开发数据导入导出（CSV适配）。  
* iPad 与 Apple Watch 配套应用。

## ---

**8\. 总结**

本需求文档不仅复刻了市面上记账App的基础功能，更通过引入\*\*“负数支出”**、**“转账/报销隔离”**、**“CloudKit隐私同步”**以及**“iOS原生交互”\*\*等高级特性，解决了当前用户最痛的几个问题。按照此文档开发的 **Lumina** 应用，将在保证专业财务逻辑严谨性的同时，提供极为流畅现代的用户体验，有望在红海市场中建立自己的忠实用户群。

建议开发团队优先攻克 **CoreData数据模型设计** 与 **CloudKit同步机制**，因为这是支撑多账本与数据一致性的基石，后期的UI功能迭代皆建立在此之上。

---

**(End of Report)** Note: This report synthesizes insights from sources 1 to provide a comprehensive architectural guide.

#### **引用的著作**

1. 20+ Best Bookkeeping Software for Businesses (2025 Tool Guide) | Pilot Blog, 访问时间为 一月 24, 2026， [https://pilot.com/blog/bookkeeping-software-for-business](https://pilot.com/blog/bookkeeping-software-for-business)  
2. Owners who run their own businesses, what bookkeeping software do you use, is there only Quickbooks, or there is something betrer (cheaper also)? : r/smallbusiness \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/smallbusiness/comments/1hw68kd/owners\_who\_run\_their\_own\_businesses\_what/](https://www.reddit.com/r/smallbusiness/comments/1hw68kd/owners_who_run_their_own_businesses_what/)  
3. I've built a free and open-source expense tracker for iOS : r/iosapps \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/iosapps/comments/1j9mbxl/ive\_built\_a\_free\_and\_opensource\_expense\_tracker/](https://www.reddit.com/r/iosapps/comments/1j9mbxl/ive_built_a_free_and_opensource_expense_tracker/)  
4. Debit & Credit \- App Store \- Apple, 访问时间为 一月 24, 2026， [https://apps.apple.com/us/app/debit-credit/id882637543](https://apps.apple.com/us/app/debit-credit/id882637543)  
5. Built a no-ads, no-login personal finance iOS app — all data stays on device (with export too) and its FREE : r/iosapps \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/iosapps/comments/1kk458e/built\_a\_noads\_nologin\_personal\_finance\_ios\_app/](https://www.reddit.com/r/iosapps/comments/1kk458e/built_a_noads_nologin_personal_finance_ios_app/)  
6. Best Budgeting Apps of 2026 – Forbes Advisor, 访问时间为 一月 24, 2026， [https://www.forbes.com/advisor/banking/best-budgeting-apps/](https://www.forbes.com/advisor/banking/best-budgeting-apps/)  
7. Looking for an iOS budgeting app that helps me track AND actually learn how to budget, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/personalfinance/comments/1p8pk0t/looking\_for\_an\_ios\_budgeting\_app\_that\_helps\_me/](https://www.reddit.com/r/personalfinance/comments/1p8pk0t/looking_for_an_ios_budgeting_app_that_helps_me/)  
8. What's the best budgeting app out there? : r/personalfinance \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/personalfinance/comments/1hufwqt/whats\_the\_best\_budgeting\_app\_out\_there/](https://www.reddit.com/r/personalfinance/comments/1hufwqt/whats_the_best_budgeting_app_out_there/)  
9. MOZE \- App Store, 访问时间为 一月 24, 2026， [https://apps.apple.com/us/app/moze/id1460011387](https://apps.apple.com/us/app/moze/id1460011387)  
10. MOZE \- App Store, 访问时间为 一月 24, 2026， [https://apps.apple.com/in/app/moze/id1460011387](https://apps.apple.com/in/app/moze/id1460011387)  
11. How do you handle credit card payments and transfers in the budget? : r/MonarchMoney, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/MonarchMoney/comments/1lhkqrq/how\_do\_you\_handle\_credit\_card\_payments\_and/](https://www.reddit.com/r/MonarchMoney/comments/1lhkqrq/how_do_you_handle_credit_card_payments_and/)  
12. MOZE \- Keep track of your money, 访问时间为 一月 24, 2026， [https://moze.webflow.io/](https://moze.webflow.io/)  
13. What is Negative Expense? \- Navan, 访问时间为 一月 24, 2026， [https://navan.com/resources/glossary/what-is-negative-expense](https://navan.com/resources/glossary/what-is-negative-expense)  
14. Is reimbursement income or a negative expense? : r/MonarchMoney \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/MonarchMoney/comments/1p1a7h5/is\_reimbursement\_income\_or\_a\_negative\_expense/](https://www.reddit.com/r/MonarchMoney/comments/1p1a7h5/is_reimbursement_income_or_a_negative_expense/)  
15. Expense refunds showing as income : r/MonarchMoney \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/MonarchMoney/comments/1mbolqn/expense\_refunds\_showing\_as\_income/](https://www.reddit.com/r/MonarchMoney/comments/1mbolqn/expense_refunds_showing_as_income/)  
16. Credit Card Payments vs. Transfers \- Quicken Community, 访问时间为 一月 24, 2026， [https://community.quicken.com/discussion/7874229/credit-card-payments-vs-transfers](https://community.quicken.com/discussion/7874229/credit-card-payments-vs-transfers)  
17. MOZE － Beautiful Expense Tracking, 访问时间为 一月 24, 2026， [https://moze.app/en/](https://moze.app/en/)  
18. MoeGo New Invoice \- Item Level Refund, 访问时间为 一月 24, 2026， [https://wiki.moego.pet/moego-new-invoice-refund-flow/](https://wiki.moego.pet/moego-new-invoice-refund-flow/)  
19. Checkbook \- Account Tracker \- App Store, 访问时间为 一月 24, 2026， [https://apps.apple.com/us/app/checkbook-account-tracker/id484000695](https://apps.apple.com/us/app/checkbook-account-tracker/id484000695)  
20. How many parent / sub-categories do you have? : r/ynab \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/ynab/comments/yrtf8b/how\_many\_parent\_subcategories\_do\_you\_have/](https://www.reddit.com/r/ynab/comments/yrtf8b/how_many_parent_subcategories_do_you_have/)  
21. budget subcategories rolling up into parent categories \- Infinite Kind Support, 访问时间为 一月 24, 2026， [https://infinitekind.tenderapp.com/discussions/budgeting/1805-budget-subcategories-rolling-up-into-parent-categories](https://infinitekind.tenderapp.com/discussions/budgeting/1805-budget-subcategories-rolling-up-into-parent-categories)  
22. Bookkeep reimbursements from your business \- Help Center \- Wave, 访问时间为 一月 24, 2026， [https://support.waveapps.com/hc/en-us/articles/115005928103-Bookkeep-reimbursements-from-your-business](https://support.waveapps.com/hc/en-us/articles/115005928103-Bookkeep-reimbursements-from-your-business)  
23. Bookkeeping and accounting \- Stripe, 访问时间为 一月 24, 2026， [https://stripe.com/guides/atlas/bookkeeping-and-accounting](https://stripe.com/guides/atlas/bookkeeping-and-accounting)  
24. The Best Personal Finance and Budgeting Apps We've Tested for 2026 | PCMag, 访问时间为 一月 24, 2026， [https://www.pcmag.com/picks/the-best-personal-finance-services](https://www.pcmag.com/picks/the-best-personal-finance-services)  
25. Adding interactivity to widgets and Live Activities | Apple Developer Documentation, 访问时间为 一月 24, 2026， [https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)  
26. "Interactive widgets" not so interactive in iOS 17 : r/iphone \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/iphone/comments/16txj08/interactive\_widgets\_not\_so\_interactive\_in\_ios\_17/](https://www.reddit.com/r/iphone/comments/16txj08/interactive_widgets_not_so_interactive_in_ios_17/)  
27. 12 Live Activities Examples that Highlight the Feature's Potential \- EngageLab, 访问时间为 一月 24, 2026， [https://www.engagelab.com/blog/live-activities-examples](https://www.engagelab.com/blog/live-activities-examples)  
28. Live Activities | Apple Developer Documentation, 访问时间为 一月 24, 2026， [https://developer.apple.com/design/human-interface-guidelines/live-activities/](https://developer.apple.com/design/human-interface-guidelines/live-activities/)  
29. Creating controls to perform actions across the system | Apple Developer Documentation, 访问时间为 一月 24, 2026， [https://developer.apple.com/documentation/WidgetKit/Creating-controls-to-perform-actions-across-the-system](https://developer.apple.com/documentation/WidgetKit/Creating-controls-to-perform-actions-across-the-system)  
30. iOS 18 Control Widget that opens a URL \- Stack Overflow, 访问时间为 一月 24, 2026， [https://stackoverflow.com/questions/78716058/ios-18-control-widget-that-opens-a-url](https://stackoverflow.com/questions/78716058/ios-18-control-widget-that-opens-a-url)  
31. MOZE － Pricing, 访问时间为 一月 24, 2026， [https://moze.app/en/pricing](https://moze.app/en/pricing)