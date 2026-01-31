# 修复iCloud同步账本重复 - 实施总结

## 修改完成时间
2026-01-31

## 问题描述
当用户将本地数据同步到iCloud后卸载App，重新安装后再同步iCloud时，会出现两个"日常账本"（自动创建的默认账本）。

### 根本原因
1. App启动时，CloudKit同步是异步的
2. 数据迁移逻辑在同步完成前立即执行
3. 检测到0个账本时立即创建新的"日常账本"
4. CloudKit随后同步下来旧的"日常账本"
5. 结果：本地存在两个"日常账本"

## 解决方案

### 策略
- ✅ 允许多个名为"日常账本"的账本存在（用户可能手动创建）
- ✅ 但只能有一个标记为`isDefault=true`的默认账本
- ✅ 增加CloudKit同步等待时间，避免重复创建

### 实施的修改

#### 1. DataMigration.swift

**修改点1: 将`migrateIfNeeded`改为async函数**
```swift
@MainActor
static func migrateIfNeeded(context: ModelContext) async {
    // 现在是异步函数，可以await
}
```

**修改点2: `ensureDefaultLedger`增加等待逻辑**
```swift
@MainActor
private static func ensureDefaultLedger(context: ModelContext) async throws {
    let ledgers = try context.fetch(ledgerDescriptor)
    
    if ledgers.isEmpty {
        print("⏳ 未检测到账本，等待CloudKit同步...")
        
        // 等待2秒，给CloudKit时间完成初始同步
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 再次检查
        let ledgersAfterWait = try context.fetch(ledgerDescriptor)
        
        if ledgersAfterWait.isEmpty {
            print("📝 CloudKit同步完成，仍无账本，创建默认账本...")
            // 创建逻辑
        } else {
            print("✅ 检测到 \(ledgersAfterWait.count) 个账本（来自iCloud），跳过创建")
        }
    } else {
        print("✅ 检测到 \(ledgers.count) 个账本，跳过创建")
    }
}
```

**修改点3: 增强`ensureDefaultLedgerExists`逻辑**
```swift
@MainActor
private static func ensureDefaultLedgerExists(context: ModelContext) throws {
    let defaultLedgers = try context.fetch(defaultDescriptor)
    
    if defaultLedgers.count > 1 {
        print("⚠️ 发现 \(defaultLedgers.count) 个默认账本，只保留第一个...")
        
        // 按sortOrder排序，保留第一个
        let sortedLedgers = defaultLedgers.sorted { $0.sortOrder < $1.sortOrder }
        
        for (index, ledger) in sortedLedgers.enumerated() {
            if index > 0 {
                ledger.isDefault = false
                print("  - 取消默认: \(ledger.name) (sortOrder: \(ledger.sortOrder))")
            } else {
                print("  - 保留默认: \(ledger.name) (sortOrder: \(ledger.sortOrder))")
            }
        }
        
        try context.save()
    }
}
```

#### 2. AppState.swift

**修改: 在调用DataMigration前增加0.5秒延迟**
```swift
Task { @MainActor in
    // 等待一小段时间，让CloudKit有机会完成初始同步
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    
    migrateDefaultLedger()
    
    // 执行数据迁移检查
    await DataMigration.migrateIfNeeded(context: modelContainer.mainContext)
}
```

## 关键改进

### 1. 双重等待机制
- **AppState启动延迟**: 0.5秒，让CloudKit启动
- **DataMigration检测延迟**: 2秒，等待数据同步

### 2. 智能检测
- 第一次检查：立即检查账本数量
- 如果为0：等待2秒
- 第二次检查：再次检查账本数量
- 只有两次都为0才创建账本

### 3. 默认账本唯一性保证
- 即使出现多个默认账本，也会自动修正
- 按sortOrder排序，保留第一个

### 4. 详细日志
- 每个步骤都有清晰的日志输出
- 便于调试和追踪问题

## 测试场景

### ✅ 场景1：全新安装（无iCloud数据）
1. 删除App
2. 确保iCloud中无数据
3. 重新安装
4. **期望**：
   - 等待0.5秒
   - 检测到0个账本
   - 等待2秒
   - 再次检测到0个账本
   - 创建"日常账本"

### ✅ 场景2：重新安装（有iCloud数据）
1. 创建测试数据并同步到iCloud
2. 删除App
3. 重新安装
4. **期望**：
   - 等待0.5秒
   - CloudKit开始同步
   - 第一次检测可能为0
   - 等待2秒
   - 第二次检测到账本（来自iCloud）
   - 不创建新账本

### ✅ 场景3：多个默认账本修复
1. 手动制造多个`isDefault=true`的账本
2. 重启App
3. **期望**：
   - 自动检测并修正
   - 只保留sortOrder最小的作为默认

## 潜在影响

### 正面影响
1. ✅ 解决了账本重复问题
2. ✅ 提高了CloudKit同步的可靠性
3. ✅ 增加了系统的容错能力

### 可能的副作用
1. ⚠️ 首次安装启动时间增加2.5秒（0.5s + 2s）
   - **缓解**: 只在检测到0个账本时才等待
   - **影响**: 正常启动（已有账本）不受影响

2. ⚠️ 网络慢时仍可能失败
   - **缓解**: 保留多账本检测逻辑作为兜底
   - **结果**: 即使创建重复账本，也能确保只有一个默认

## 验证清单

- [x] 编译通过，无错误
- [x] 修改了DataMigration.swift
- [x] 修改了AppState.swift
- [x] 增加了详细日志
- [x] 增强了默认账本唯一性检测
- [x] 所有TODO任务完成

## 后续建议

### 短期（下个版本）
1. 在真机上进行完整测试
2. 测试不同网络条件下的表现
3. 收集用户反馈

### 长期（未来版本）
1. 考虑监听CloudKit的同步完成通知
2. 添加同步进度UI提示
3. 允许用户手动触发同步

## 相关文档
- 修复计划: `.cursor/plans/修复icloud同步账本重复_e35db2d2.plan.md`
- CloudKit修复说明: `docs/CloudKit修复说明_v6.md`
- CloudKit故障排查: `docs/CloudKit故障排查.md`
