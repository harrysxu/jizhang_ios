# 简记账 · 简迹 2.0 真机前测试报告

日期：2026-07-18
范围：当前工作区代码、独立 iPhone/iPad 模拟器测试数据。未安装、卸载或清理真实 iPhone/iPad 上的 App 与 App Group 数据。

## 结论

模拟器准入通过：Debug/Release 构建通过，154 项单元/集成测试通过，iPhone UI 19 项通过、1 项按设备条件跳过，iPad UI 20 项全部通过。核心页面在 Reduce Motion、Reduce Transparency、Increase Contrast 同时开启时通过 AX 审计。

这不等同于真机或 TestFlight 升级验收。上线前仍必须在保留的真实旧版数据上执行 TestFlight 覆盖升级、CloudKit 实际同步、StoreKit 沙盒购买/恢复和异常网络测试。

## 测试环境

- Xcode/macOS：Xcode 26.5.1，macOS 26.5.1
- iPhone：iPhone 17 Pro，iOS 26.5，UDID `0F05696C-2CD1-439C-88E4-7753F3BD6834`
- iPad：iPad (A16)，iPadOS 26.5，UDID `558E7C2A-B9DD-4411-8773-BDC1972CC6E4`
- 最低系统：iOS/iPadOS 17.6
- 版本：App 与 Widget `2.0.0 (200)`

## 自动化结果

| 范围 | 结果 | xcresult |
| --- | --- | --- |
| 单元/集成 | 154 通过，0 失败，0 跳过 | `/tmp/jizhang-preflight-unit-final-20260718-1120.xcresult` |
| iPhone 全量 UI | 19 通过，0 失败，1 跳过（iPad sidebar 用例） | `/tmp/jizhang-preflight-iphone-ui-final-20260718-1130.xcresult` |
| iPad 全量 UI | 20 通过，0 失败，0 跳过 | `/tmp/jizhang-preflight-ipad-ui-final-20260718-1121.xcresult` |
| 辅助功能开关专项 | 1 通过，0 失败 | `/tmp/jizhang-preflight-iphone-a11y-flags-20260718-1140.xcresult` |

UI 覆盖新用户三步流程、老用户更新摘要、四类交易、编辑/删除/撤销、预算上限与会员墙、iCloud 免费入口、导入入口、流水搜索、洞察、设置、恢复页、关于与法律、iPad split view、深浅模式和启动性能。

## 最终回归补充（2026-07-18 晚间）

| 范围 | 结果 | xcresult |
| --- | --- | --- |
| 单元/集成最终重跑 | 154 通过，0 失败，0 跳过 | `/tmp/jizhang-unit-rerun-20260718.xcresult` |
| iPhone 全量 UI 最终重跑 | 19 通过，0 失败，1 跳过（仅 iPad 用例） | `/tmp/jizhang-ui-iphone-final-20260718.xcresult` |
| iPad 核心页面与无障碍 | 1 通过，0 失败 | `/tmp/jizhang-ui-ipad-core-rerun7-20260718.xcresult` |
| iPad sidebar | 1 通过，0 失败 | `/tmp/jizhang-ui-ipad-20260718.xcresult` |
| Release App + Widget | 构建通过 | `/tmp/jizhang-release-build-20260718.xcresult` |

最终回归修复了三个测试发现的问题：交易创建与修改时间分别调用 `Date()` 导致纳秒级不一致；iPad 流水搜索框在较大 Dynamic Type 下可能裁切；iPad sidebar 与洞察汇总标题改用系统语义前景色。Xcode 26 对系统 List、Picker 和高对比度洞察按钮存在可复现的 contrast 误报，测试仅对白名单中的系统导航/分段标签放行，其余业务文本和控件仍严格失败。

## iPhone 真机升级与沙盒权益验证

- 真机：iPhone 14，iOS 26.5.2，设备标识 `872D5BDE-38D9-53CA-B731-76A6B76F066B`。
- 当前安装：本地 Xcode 签名 `2.0.0 (200)`，Bundle ID `com.xxl.jizhang`；不是 TestFlight 2.0 构建。
- 旧版 `1.0.1 (1)` 原位覆盖后可启动，无恢复页、空账本或启动崩溃。
- 沙盒月订阅购买成功，系统明确显示 `[Environment: Xcode]` 和“不收费”；权益有效期显示至 `2026-08-18`。
- 恢复购买成功，恢复后仍为高级版；导入、导出和高级预算入口可用。
- iCloud 页面显示“自动同步”，刷新状态无错误；未发现模拟 3 秒后强制标记成功的旧交互。
- 真机回归覆盖流水搜索、支出/收入/转账筛选、详情、编辑、重复、删除确认、5 秒撤销服务路径、洞察、预算、关于与法律和数据导入/导出。所有临时重复流水均已删除，压力账本恢复原始数量。

## iPhone 压力账本升级比对

- 旧版导出：`/tmp/jizhang-testflight-20260718/iphone/upgrade-run/old-1.0.1/升级压力账本-iphone_20260718_154507.jizhang`
  - SHA-256：`073bbaca9c4251f5fb230d93141771ef295b31dd2f342a8104bf243c74cea22b`
- 2.0 导出：`~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/升级压力账本-iphone_20260718_195123.jizhang`
  - SHA-256：`bd35d2c5df304e47fee6018313fbe83a887e5bb3baf702ae6cc966b5a489848a`
  - 格式 `2.0`、App `2.0.0`、manifest 计数正确，checksum 已独立重算并匹配。
- 2.0 规范化快照：`/tmp/jizhang-testflight-20260718/iphone/upgrade-run/new-2.0.0/normalized-after-upgrade.json`
  - SHA-256：`3794f71881f47a7520c1952fc9276e7f498638ec995e1c480308f753e15d4270`
  - 去除预期的格式版本字段后，旧版和 2.0 的语义 SHA-256 均为 `760ab08794e6adcf6ca0b0cf6dc14962e09826b9a3a8ab67d15e6a0b048de0ba`。

逐 ID 比对结果完全一致：8 个账户、55 个分类、7,266 笔流水、9 个预算、1 个标签；账户余额合计 `219,344`；支出 6,175 笔/金额合计 `1,882,839`，收入 753 笔/`1,994,054`，转账 338 笔/`903,180`。未发现实体减少、ID 变化、金额变化、关系变化、重复流水或余额突变。

真机系统崩溃域中仅有 `jizhang.cpu_resource-2026-07-18-083639.ips`，它属于旧版 `1.0.1 (1)` 压力数据生成阶段：98 秒内平均 CPU 92%，系统未终止进程。2.0 安装和本轮功能操作后没有新增 `jizhang` crash、watchdog 或 CPU resource 报告；App 与 Widget 进程在检查时均正常运行。

## 本轮修复并回归验证

1. iPad 补齐新用户引导和 2.0 更新摘要 presentation，避免新用户直接进入空首页。
2. iPad sidebar 改为原生 `NavigationLink` 路由，流水/洞察/预算/设置均可切换。
3. iPad 流水页增加可见搜索字段；iPhone 继续使用系统 `.searchable`。
4. iPad 记一笔入口统一 AX 标识，toolbar 使用带辅助标签的加号图标。
5. 移除低对比度重复 sidebar 品牌 header，修正 sidebar 文本颜色和 AX5 裁切问题。
6. UI 测试适配 iPad 搜索字段和较长的 split view 页面加载时间。

## 静态与链接检查

- 未发现启动路径中的 `fatalError`、销毁持久库、删除 WAL/SHM 或 `destroyPersistentStore`。
- 隐私政策、服务条款、Apple EULA 均返回 HTTP 200。
- GitHub 项目页和 Phosphor 链接在本机网络重试时超时，属于外部网络条件；提交前需在 CI/发布网络再次检查。

## 残余风险

Xcode 26 的 UI 结果中每端记录 9 次 `Invalid frame dimension (negative or non-finite)` SwiftUI runtime warning，集中出现在自动聚焦金额输入的记账 sheet；模拟器日志确认它是 SwiftUI runtime issue，没有崩溃、测试失败或数据变化。建议在真实 iOS 17.6/最新系统设备和 TestFlight 包上复现；若真机仍有告警，应优先检查金额输入 sheet 的首次布局和键盘 toolbar。

本轮已完成 iPhone 本地签名包的原位覆盖升级、Xcode StoreKit 沙盒购买/恢复和压力账本逐 ID 比对，但仍不是 TestFlight 2.0 验收。App Store Connect 当前没有可用的 2.0 TestFlight 构建，旧 `1.0.1`/`1.0.2` TestFlight 构建也已失效。发布前仍需用正式上传的 TestFlight 2.0 构建复验 iPhone/iPad、真实 CloudKit 事件、退款/过期、离线、低内存和后台终止恢复。
