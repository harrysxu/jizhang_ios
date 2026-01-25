# CloudKit配置指南

## 重要提示

本项目使用SwiftData + CloudKit实现多设备同步功能。在运行App之前,**必须**先在Xcode中配置iCloud能力,否则App会崩溃。

## 配置步骤

### 1. 配置Apple Developer账号

确保你有有效的Apple Developer账号(免费或付费账号均可)。

### 2. 在Xcode中配置iCloud

1. 打开项目 `jizhang.xcodeproj`
2. 选择Target: `jizhang`
3. 切换到 `Signing & Capabilities` 标签

### 3. 添加iCloud能力

1. 点击 `+ Capability` 按钮
2. 选择 `iCloud`
3. 在iCloud部分:
   - ✅ 勾选 `CloudKit`
   - 在Containers列表中,点击 `+` 按钮
   - 选择 `iCloud.` 开头的容器,或创建新容器
   - 容器ID建议格式: `iCloud.com.yourcompany.jizhang`

### 4. 添加Background Modes

1. 继续在 `Signing & Capabilities` 标签
2. 点击 `+ Capability` 按钮
3. 选择 `Background Modes`
4. 勾选:
   - ✅ `Remote notifications`

### 5. 配置Bundle Identifier

1. 在 `General` 标签中
2. 修改 `Bundle Identifier` 为你自己的ID
3. 例如: `com.yourname.jizhang`

### 6. 配置App Groups (可选,但推荐)

如果将来要开发Widget或其他Extension:

1. 点击 `+ Capability` 按钮
2. 选择 `App Groups`
3. 点击 `+` 按钮添加新的App Group
4. 格式: `group.com.yourcompany.jizhang`

## 验证配置

配置完成后,构建并运行App:

1. 确保设备或模拟器已登录iCloud账号
2. 运行App
3. 进入 `设置` → `数据` → `iCloud同步`
4. 检查同步状态是否正常显示

## 同步测试

要测试多设备同步:

1. 在两台设备上使用相同的iCloud账号登录
2. 在设备A创建交易记录
3. 等待约10-30秒
4. 在设备B上查看,应该能看到同步的数据

## 常见问题

### Q: App启动崩溃,提示无法创建ModelContainer

**A**: 你可能没有配置CloudKit能力。请按照上述步骤配置。

### Q: 同步状态显示"未登录iCloud"

**A**: 
- 检查设备是否已登录iCloud账号
- 前往 `设置` → `Apple ID` → `iCloud` 确认已登录
- 确认iCloud Drive已开启

### Q: 数据不同步

**A**:
- 检查网络连接
- 确认两台设备使用相同的iCloud账号
- 等待更长时间(首次同步可能需要1-2分钟)
- 在设置页面手动触发"立即同步"

### Q: 开发时是否需要付费开发者账号?

**A**: 
- 免费账号可以使用CloudKit
- 但有设备数量和功能限制
- 付费账号($99/年)没有限制

## 关于CloudKit配额

### 免费额度
- **Public Database**: 10GB存储 + 200GB/月传输
- **Private Database**: 1GB存储 + 10GB/月传输
- 对于记账App来说,完全够用

### 数据量估算
- 1条交易记录 ≈ 1KB
- 10,000条交易 ≈ 10MB
- 1GB可以存储约100万条交易记录

## 禁用CloudKit同步

如果你不需要多设备同步功能,可以这样做:

### 方法1: 修改AppState.swift

```swift
// 将这行:
cloudKitDatabase: .automatic

// 改为:
cloudKitDatabase: .none
```

### 方法2: 使用本地存储

```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    allowsSave: true
    // 删除 cloudKitDatabase 参数
)
```

## 参考资料

- [Apple CloudKit文档](https://developer.apple.com/documentation/cloudkit)
- [SwiftData + CloudKit指南](https://developer.apple.com/documentation/swiftdata)
- [iCloud配置教程](https://developer.apple.com/icloud/)

## 技术支持

如有问题,请提交Issue或联系开发者。
