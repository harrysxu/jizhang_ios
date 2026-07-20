# 2.0 升级测试基线（2026-07-18）

本报告记录 TestFlight 覆盖升级前的旧版数据基线。旧版 App 未卸载后重新建库，保留了设备 App Group 中的历史数据；因此该基线反映真实存量设备的兼容场景。

## 设备与安装版本

| 设备 | 设备标识 | Bundle ID | 版本 | 构建 |
| --- | --- | --- | --- | --- |
| iPhone 14 | `872D5BDE-38D9-53CA-B731-76A6B76F066B` | `com.xxl.jizhang` | `1.0.1` | `1` |
| iPad（第 6 代） | `A8824F92-2080-5BB8-8151-2C30D681F7B7` | `com.xxl.jizhang` | `1.0.1` | `1` |

## 数据数量

| 项目 | iPhone 14 | iPad（第 6 代） |
| --- | ---: | ---: |
| 账本 | 10 | 8 |
| 账户 | 38 | 29 |
| 分类 | 550 | 440 |
| 预算 | 35 | 26 |
| 标签 | 2 | 1 |
| 交易 | 23,420 | 16,154 |
| 其中：支出 | 19,909 | 13,734 |
| 其中：收入 | 2,381 | 1,628 |
| 其中：转账 | 1,130 | 792 |

两台设备的测试权限字段均为 `premiumAccess=true`，订阅状态字段仍为“免费版”。这是仅用于生成压力数据的 Debug 测试开关，不代表真实 Apple 购买记录。

## 压力数据

- iPhone 压力账本 `升级压力账本-iphone`：7,266 笔交易。
- iPad 压力账本 `升级压力账本-ipad`：7,337 笔交易。
- iPhone 同时已看到 iPad 压力账本；iPad 当前尚未看到 iPhone 压力账本，需在升级后继续观察 CloudKit 同步，不能把该差异误判为本地迁移丢失。

## 完整快照

快照 JSON 包含每个实体的持久化 ID、关系、金额、日期、枚举、余额、预算周期和当前账本：

- `/tmp/jizhang-upgrade-detail-iphone.json`
  - SHA-256：`69aabebf534e0c50e4b2c8ca06a2341cc49ec48a9e2ef262ed9b821c055f6ede`
- `/tmp/jizhang-upgrade-detail-ipad.json`
  - SHA-256：`0f7c596bbca915fd70c09516bb94c25d83f392a53746dff5f9a0a08a7e4d0347`

## 升级前崩溃观察

在 iPad 旧版压力数据生成和重新启动期间，系统记录了旧版 `1.0.1 (1)` 的崩溃报告；这些报告来自 iPadOS 17.7.11，不是 `devicectl` 查询错误：

- `08:34:00`：`SIGKILL`，`scene-update watchdog`，旧版流水页在大数据量下主线程过滤流水超过 10 秒。
- `08:39:07` 至 `08:39:34`：多次 `SIGABRT`，栈落在 `HomeView.createDefaultLedger()` → `NSManagedObjectContext.insertObject`，与 CloudKit 首次拉取/默认账本竞争有关。
- `08:47:22`：同类 `SIGABRT`。
- `08:54:07`、`08:56:35`：再次出现 `scene-update/scene-create watchdog`，分别约 21 秒和 36 秒 CPU 时间。
- `09:20:25`、`09:20:50`：用户再次启动旧版后仍触发 `scene-create watchdog`；崩溃栈明确落在 `HomeView` → `SevenDayExpenseChart.generateData(from:)` → `Transaction.date`，约 39.6 秒、93% CPU。

崩溃后重新从 iPad 拉取 `/Documents/upgrade-detail-ipad.json`，SHA-256 仍为 `0f7c596bbca915fd70c09516bb94c25d83f392a53746dff5f9a0a08a7e4d0347`，未发现数据减少或文件被覆盖。

这些是旧版的已知基线缺陷，不能标记为 2.0 回归；但在 2.0 TestFlight 覆盖升级后，必须重新拉取两台设备的 `jizhang-*.ips`，验收标准为：升级启动和打开首页/流水页期间不新增 `SIGABRT`、`0x8BADF00D` watchdog 或空库恢复页。升级后的高数据量页面还要验证主线程不再持续占用导致系统终止。

升级验收必须满足：

1. 两台设备均从 `1.0.1` 直接覆盖到 TestFlight `2.0.0`，不卸载、不清理 App Group。
2. 账本、账户、分类、预算、标签和交易的数量不减少。
3. 所有原有 ID、金额、日期、类型、账户关系和预算周期保持一致；兼容修复只能增加明确的新关系，不能批量清空历史关系。
4. 当前账本、账户余额、首页/洞察统计与快照可重算结果一致。
5. 启动无恢复页误判、无崩溃、无空库覆盖；升级后新增、编辑、删除、撤销和转账操作均能保存并再次读取。

## iPhone 本地签名 2.0 覆盖升级结果

2026-07-18 使用同 Bundle ID 的本地 Xcode 签名 `2.0.0 (200)` 对 iPhone 14 原位覆盖安装，未卸载 App、未清理 App Group、未重置账本。该轮不是 TestFlight 2.0，但可验证持久库和 2.0 业务内核兼容性。

`升级压力账本-iphone` 的 2.0 导出为：

- `~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/升级压力账本-iphone_20260718_195123.jizhang`
- 原始文件 SHA-256：`bd35d2c5df304e47fee6018313fbe83a887e5bb3baf702ae6cc966b5a489848a`
- 规范化快照：`/tmp/jizhang-testflight-20260718/iphone/upgrade-run/new-2.0.0/normalized-after-upgrade.json`
- 规范化 SHA-256：`3794f71881f47a7520c1952fc9276e7f498638ec995e1c480308f753e15d4270`

新导出格式为 `2.0`，manifest 为 8 个账户、55 个分类、7,266 笔交易、9 个预算、1 个标签，文件 checksum 独立重算一致。去除预期的格式版本字段后，旧版基线与 2.0 快照的 SHA-256 均为 `760ab08794e6adcf6ca0b0cf6dc14962e09826b9a3a8ab67d15e6a0b048de0ba`，证明所有持久化 ID、字段和关系逐项一致。

账户余额合计仍为 `219,344`；交易仍为支出 6,175 笔、收入 753 笔、转账 338 笔。升级后首页、流水、洞察、预算、导入/导出、沙盒订阅和恢复购买均可操作，临时测试流水已删除。真机系统崩溃域未新增 2.0 报告，仅保留升级前旧版 `1.0.1 (1)` 的 CPU resource 报告。
