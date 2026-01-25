# 数字展示自适应优化总结

## 优化目标

优化报表及其他界面中的数字展示，实现自适应格式化，减少换行导致的不美观问题。

## 优化内容

### 1. 报表页面 (Report)

#### 1.1 汇总卡片 (ReportView)
- **优化点**：
  - 使用智能金额格式化，根据金额大小自动选择单位（亿、万、千）
  - 添加 `minimumScaleFactor(0.6)` 支持文字缩放
  - 添加 `lineLimit(1)` 防止换行
  - 使用 `design: .rounded` 圆角数字字体
  - 优化布局spacing和padding

- **格式化规则**：
  - ≥ 1亿：显示"¥X.X亿"（0-1位小数）
  - ≥ 1万：显示"¥X.X万"（0-1位小数）
  - ≥ 1千：显示"¥X.X"（0-1位小数）
  - < 1千：显示"¥X.XX"（2位小数）

#### 1.2 收支趋势图 (IncomeExpenseChartView)
- **优化点**：
  - Y轴标签字体从 `caption` 改为 `caption2`
  - 添加 `monospacedDigit()` 等宽数字
  - 优化金额格式化，支持亿、万、k单位

- **格式化规则**：
  - ≥ 1亿：显示"¥X.X亿"
  - ≥ 1万：显示"¥X.X万"
  - ≥ 1千：显示"¥X.Xk"
  - < 1千：显示"¥X"（整数）

#### 1.3 分类占比 (CategoryPieChartView)
- **优化点**：
  - 优化列表项间距和图标大小
  - 百分比使用 `caption` 字体，更紧凑
  - 金额栏添加 `minimumScaleFactor(0.8)` 和 `lineLimit(1)`
  - 使用 `minWidth` 替代固定 `width`

- **格式化规则**：
  - ≥ 1亿：显示"¥X.X亿"
  - ≥ 1万：显示"¥X.X万"
  - ≥ 1千：显示"¥X"（整数）
  - < 1千：显示"¥X.XX"（2位小数）

#### 1.4 Top排行榜 (TopRankingView)
- **优化点**：
  - 分类名称添加 `lineLimit(1)`
  - 金额添加 `minimumScaleFactor(0.8)` 和 `lineLimit(1)`
  - 使用 `Spacer(minLength: 8)` 保证最小间距
  - 使用 `minWidth: 80` 设置金额栏最小宽度

### 2. 首页 (Home)

#### 2.1 净资产卡片 (NetAssetCard)
- **优化点**：
  - 本月收支添加 `minimumScaleFactor(0.7)` 和 `lineLimit(1)`
  - 使用智能金额格式化

- **格式化规则**：
  - ≥ 1亿：显示"¥X.XX亿"（0-2位小数）
  - ≥ 1万：显示"¥X.XX万"（0-2位小数）
  - < 1万：显示"¥X.XX"（2位小数）

#### 2.2 今日支出卡片 (TodayExpenseCard)
- **优化点**：
  - 添加 `minimumScaleFactor(0.7)` 和 `lineLimit(1)`
  - 使用与NetAssetCard相同的格式化规则

#### 2.3 精简资产卡片 (CompactAssetCard)
- **优化点**：
  - 净资产使用 `minimumScaleFactor(0.6)`，支持更大缩放
  - 收支添加 `minimumScaleFactor(0.8)` 和 `lineLimit(1)`
  - 图标字体从 `caption` 改为 `caption2`
  - 优化布局，使用 `frame(maxWidth: .infinity, alignment: .leading)`

### 3. 预算 (Budget)

#### 3.1 预算卡片 (BudgetCardView)
- **优化点**：
  - 分类名称和预算添加 `lineLimit(1)`
  - 已用/剩余金额使用圆角字体，添加 `minimumScaleFactor(0.7)`
  - 优化HStack spacing，使用 `frame(maxWidth: .infinity)` 均分空间
  - 结转金额添加 `lineLimit(1)`

- **格式化规则**：
  - ≥ 1亿：显示"¥X.X亿"
  - ≥ 1万：显示"¥X.X万"
  - ≥ 1千：显示"¥X.X"（0-1位小数）
  - < 1千：显示"¥X.XX"（2位小数）

#### 3.2 预算概览卡片 (BudgetOverviewCard)
- **优化点**：
  - 总预算和已用金额使用圆角字体
  - 添加 `minimumScaleFactor(0.7)` 和 `lineLimit(1)`
  - 日均可用添加 `minimumScaleFactor(0.8)` 和 `lineLimit(1)`
  - 百分比添加 `padding(.leading, 4)` 增加间距

## 技术要点

### 1. 等宽数字
所有金额显示都使用 `monospacedDigit()` 修饰符，确保数字宽度一致，避免数字跳动。

### 2. 自适应缩放
使用 `minimumScaleFactor` 修饰符：
- 主要金额：0.6-0.7（允许较大缩放）
- 次要金额：0.7-0.8（中等缩放）
- 小金额：0.8（轻微缩放）

### 3. 防止换行
所有金额文本都添加 `lineLimit(1)`，确保单行显示。

### 4. 圆角数字字体
主要金额使用 `design: .rounded`，更现代美观。

### 5. 智能单位转换
根据金额大小自动选择合适的单位：
- 亿级：适合展示大额资产
- 万级：适合展示日常收支
- 千级：适合展示中等金额
- 完整显示：适合展示小额金额

### 6. 精度控制
- 大额数字（亿、万）：0-2位小数
- 中等数字（千）：0-1位小数
- 小额数字：2位小数（保持精确）

## 代码规范

### 统一的格式化函数
```swift
private func formatAmount(_ amount: Decimal) -> String {
    let absAmount = abs(amount)
    
    if absAmount >= 100000000 {
        return "¥\((amount / 100000000).formatted(.number.precision(.fractionLength(0...1))))亿"
    } else if absAmount >= 10000 {
        return "¥\((amount / 10000).formatted(.number.precision(.fractionLength(0...1))))万"
    } else if absAmount >= 1000 {
        return "¥\(amount.formatted(.number.precision(.fractionLength(0...1))))"
    } else {
        return "¥\(amount.formatted(.number.precision(.fractionLength(2))))"
    }
}
```

### 文本修饰符组合
```swift
Text(formatAmount(amount))
    .font(.system(size: 18, weight: .semibold, design: .rounded))
    .monospacedDigit()
    .minimumScaleFactor(0.7)
    .lineLimit(1)
```

## 构建状态

✅ **构建成功** - 所有修改已通过编译验证

## 优化效果

1. **更简洁**：大额数字使用万、亿单位，节省显示空间
2. **更美观**：避免长数字换行，保持界面整洁
3. **更易读**：智能选择精度，重要信息一目了然
4. **自适应**：支持不同金额大小自动调整显示方式
5. **响应式**：支持文字缩放，适配不同屏幕尺寸

## 测试建议

建议测试以下场景：
1. 小额金额（< 1000）
2. 中等金额（1000 - 9999）
3. 万级金额（10000 - 99999999）
4. 亿级金额（≥ 100000000）
5. 负数金额
6. 小屏幕设备（iPhone SE）
7. 大屏幕设备（iPhone Pro Max）
8. 动态字体大小调整
