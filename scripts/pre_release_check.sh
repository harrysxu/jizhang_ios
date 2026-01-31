#!/bin/bash

# 简记账 iOS App 发布前检查脚本
# 使用方法: ./scripts/pre_release_check.sh

set -e

echo "🚀 简记账 iOS App 发布前检查"
echo "================================"
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查结果统计
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# 检查函数
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASS_COUNT++))
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAIL_COUNT++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARN_COUNT++))
}

check_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "📋 1. 检查基础配置"
echo "-------------------"

# 检查 Bundle ID
if grep -q "com.xxl.jizhang" jizhang/jizhang.xcodeproj/project.pbxproj; then
    check_pass "Bundle ID: com.xxl.jizhang"
else
    check_fail "Bundle ID 未找到或不正确"
fi

# 检查版本号
MARKETING_VERSION=$(grep -m 1 "MARKETING_VERSION" jizhang/jizhang.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
if [ -n "$MARKETING_VERSION" ]; then
    check_pass "版本号: $MARKETING_VERSION"
else
    check_fail "未找到版本号"
fi

# 检查构建号
BUILD_VERSION=$(grep -m 1 "CURRENT_PROJECT_VERSION" jizhang/jizhang.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
if [ -n "$BUILD_VERSION" ]; then
    check_pass "构建号: $BUILD_VERSION"
else
    check_fail "未找到构建号"
fi

echo ""
echo "📱 2. 检查必需文件"
echo "-------------------"

# 检查 Info.plist
if [ -f "jizhang/jizhang/Info.plist" ]; then
    check_pass "Info.plist 存在"
else
    check_fail "Info.plist 不存在"
fi

# 检查 Entitlements
if [ -f "jizhang/jizhang/jizhang.entitlements" ]; then
    check_pass "jizhang.entitlements 存在"
    
    # 检查 aps-environment
    if grep -q "<string>production</string>" jizhang/jizhang/jizhang.entitlements; then
        check_pass "推送通知环境: production"
    else
        check_fail "推送通知环境不是 production！发布前必须改为 production"
    fi
else
    check_fail "jizhang.entitlements 不存在"
fi

# 检查隐私清单文件
if [ -f "jizhang/jizhang/PrivacyInfo.xcprivacy" ]; then
    check_pass "PrivacyInfo.xcprivacy 存在"
else
    check_fail "PrivacyInfo.xcprivacy 不存在（iOS 17+ 必需）"
fi

# 检查 StoreKit 配置
if ls jizhang/*.storekit 1> /dev/null 2>&1; then
    check_pass "StoreKit 配置文件存在"
else
    check_warn "StoreKit 配置文件不存在（如有订阅功能需要创建）"
fi

echo ""
echo "🎨 3. 检查资源文件"
echo "-------------------"

# 检查 AppIcon
if [ -f "jizhang/jizhang/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    check_pass "AppIcon 配置存在"
    
    # 检查是否有1024x1024图标
    if ls jizhang/jizhang/Assets.xcassets/AppIcon.appiconset/*.png 1> /dev/null 2>&1; then
        ICON_COUNT=$(ls jizhang/jizhang/Assets.xcassets/AppIcon.appiconset/*.png 2>/dev/null | wc -l)
        if [ "$ICON_COUNT" -gt 0 ]; then
            check_pass "找到 $ICON_COUNT 个 App 图标文件"
        else
            check_fail "未找到 App 图标文件"
        fi
    else
        check_fail "未找到 App 图标文件"
    fi
else
    check_fail "AppIcon 配置不存在"
fi

echo ""
echo "⚙️  4. 检查功能配置"
echo "-------------------"

# 检查 iCloud 配置
if grep -q "iCloud.com.xxl.jizhang" jizhang/jizhang/jizhang.entitlements; then
    check_pass "iCloud 容器ID配置正确"
else
    check_fail "iCloud 容器ID未配置或不正确"
fi

# 检查 App Group
if grep -q "group.com.xxl.jizhang" jizhang/jizhang/jizhang.entitlements; then
    check_pass "App Group 配置正确"
else
    check_fail "App Group 未配置或不正确"
fi

# 检查 Siri 权限
if grep -q "com.apple.developer.siri" jizhang/jizhang/jizhang.entitlements; then
    check_pass "Siri 权限已配置"
else
    check_warn "Siri 权限未配置"
fi

# 检查 Siri 使用说明
if grep -q "NSSiriUsageDescription" jizhang/jizhang/Info.plist; then
    check_pass "Siri 使用说明已配置"
else
    check_warn "Siri 使用说明未配置"
fi

echo ""
echo "🧪 5. 检查代码质量"
echo "-------------------"

# 检查是否有 TODO 或 FIXME
TODO_COUNT=$(find jizhang/jizhang -name "*.swift" -type f -exec grep -l "TODO\|FIXME" {} \; 2>/dev/null | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -eq 0 ]; then
    check_pass "无待办事项（TODO/FIXME）"
else
    check_warn "发现 $TODO_COUNT 个文件包含 TODO/FIXME"
fi

# 检查是否有 print 语句（调试代码）
PRINT_COUNT=$(find jizhang/jizhang -name "*.swift" -type f -exec grep -c "print(" {} \; 2>/dev/null | awk '{s+=$1} END {print s}')
if [ -z "$PRINT_COUNT" ] || [ "$PRINT_COUNT" -eq 0 ]; then
    check_pass "无调试 print 语句"
else
    check_warn "发现约 $PRINT_COUNT 个 print 语句（建议清理调试代码）"
fi

echo ""
echo "📦 6. 检查 Widget 配置"
echo "-------------------"

# 检查 Widget Extension
if [ -d "jizhang/jizhangWidget" ]; then
    check_pass "Widget Extension 存在"
    
    if [ -f "jizhang/jizhangWidget/jizhangWidgetExtension.entitlements" ]; then
        check_pass "Widget Entitlements 存在"
    else
        check_warn "Widget Entitlements 不存在"
    fi
else
    check_warn "Widget Extension 不存在（可选功能）"
fi

echo ""
echo "📝 7. 检查文档"
echo "-------------------"

# 检查 README
if [ -f "README.md" ]; then
    check_pass "README.md 存在"
else
    check_warn "README.md 不存在（建议添加）"
fi

# 检查发布文档
if [ -f "docs/App发布准备清单.md" ]; then
    check_pass "发布准备清单存在"
else
    check_info "发布准备清单不存在"
fi

if [ -f "docs/App发布详细步骤.md" ]; then
    check_pass "发布详细步骤存在"
else
    check_info "发布详细步骤不存在"
fi

echo ""
echo "================================"
echo "📊 检查结果汇总"
echo "================================"
echo -e "${GREEN}✅ 通过: $PASS_COUNT${NC}"
echo -e "${YELLOW}⚠️  警告: $WARN_COUNT${NC}"
echo -e "${RED}❌ 失败: $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 恭喜！所有必需项检查通过！${NC}"
    echo ""
    echo "📋 下一步操作："
    echo "1. 查看警告项并根据需要修复"
    echo "2. 在 Xcode 中打开项目进行最终测试"
    echo "3. 准备 App Store Connect 所需的截图和描述"
    echo "4. 参考 docs/App发布详细步骤.md 进行发布"
    echo ""
    exit 0
else
    echo -e "${RED}❌ 有 $FAIL_COUNT 项检查失败，请修复后再发布！${NC}"
    echo ""
    echo "📋 修复建议："
    echo "1. 查看上面标记为 ❌ 的项目"
    echo "2. 根据错误信息进行修复"
    echo "3. 参考 docs/App发布准备清单.md 获取详细信息"
    echo "4. 修复后重新运行此脚本"
    echo ""
    exit 1
fi
