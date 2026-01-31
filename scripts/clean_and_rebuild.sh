#!/bin/bash

# 清理并重新构建 iOS 项目
# 用于解决图标不显示、Siri 无法识别等真机部署问题

echo "🧹 开始清理项目..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. 清理 DerivedData
echo -e "${BLUE}📦 清理 DerivedData...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/jizhang-*
rm -rf ~/Library/Developer/Xcode/DerivedData/*jizhang*

# 2. 清理项目构建文件
echo -e "${BLUE}🗑️  清理项目构建文件...${NC}"
cd "$(dirname "$0")/.." || exit
if [ -d "jizhang/jizhang.xcodeproj" ]; then
    xcodebuild clean -project jizhang/jizhang.xcodeproj -scheme jizhang -configuration Debug
    xcodebuild clean -project jizhang/jizhang.xcodeproj -scheme jizhang -configuration Release
fi

# 3. 清理模拟器（可选）
echo -e "${BLUE}📱 清理不可用的模拟器...${NC}"
xcrun simctl delete unavailable 2>/dev/null || true

# 4. 清理 Xcode 缓存
echo -e "${BLUE}🗂️  清理 Xcode 缓存...${NC}"
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*/Symbols/System/Library/Caches

# 5. 清理 CocoaPods 缓存（如果使用）
if [ -d "jizhang/Pods" ]; then
    echo -e "${BLUE}📦 清理 CocoaPods 缓存...${NC}"
    cd jizhang || exit
    pod cache clean --all
    rm -rf Pods
    rm -rf ~/Library/Caches/CocoaPods
    cd ..
fi

echo -e "${GREEN}✅ 清理完成！${NC}"
echo ""
echo -e "${YELLOW}📝 接下来的步骤：${NC}"
echo "1. 在真机上完全删除 App（长按图标 → 删除 App）"
echo "2. 在 iPhone 设置 → 通用 → iPhone 储存空间 中确认已删除"
echo "3. 重启 iPhone"
echo "4. 在 Xcode 中重新构建并运行项目"
echo "5. 等待 2-3 分钟让系统索引 Siri 指令"
echo ""
echo -e "${BLUE}💡 提示：${NC}"
echo "- 如果图标仍不显示，检查是否在 App 资源库中"
echo "- 对 Siri 说 '打开简记账' 测试基础识别"
echo "- 在快捷指令 App 中搜索 '简记账' 查看可用操作"
echo ""
echo -e "${GREEN}🎉 准备就绪！请按照上述步骤继续。${NC}"
