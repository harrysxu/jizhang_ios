#!/bin/bash

# 完整的真机部署修复脚本
# 解决图标不显示和 Siri 无法识别问题

set -e

echo "🚀 开始完整修复流程..."
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="/Users/xuxiaolong/OpenSource/jizhang_ios"
cd "$PROJECT_DIR"

# 步骤 1: 清理 DerivedData
echo -e "${BLUE}📦 步骤 1/6: 清理 DerivedData...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/jizhang-*
rm -rf ~/Library/Developer/Xcode/DerivedData/*jizhang*
echo -e "${GREEN}✅ DerivedData 已清理${NC}"
echo ""

# 步骤 2: 清理 Xcode 缓存
echo -e "${BLUE}🗂️  步骤 2/6: 清理 Xcode 缓存...${NC}"
rm -rf ~/Library/Caches/com.apple.dt.Xcode
echo -e "${GREEN}✅ Xcode 缓存已清理${NC}"
echo ""

# 步骤 3: 清理项目构建文件
echo -e "${BLUE}🧹 步骤 3/6: 清理项目构建文件...${NC}"
cd jizhang
xcodebuild clean -project jizhang.xcodeproj -scheme jizhang -configuration Debug > /dev/null 2>&1 || true
cd ..
echo -e "${GREEN}✅ 项目构建文件已清理${NC}"
echo ""

# 步骤 4: 验证资源文件
echo -e "${BLUE}🔍 步骤 4/6: 验证资源文件...${NC}"
if [ -f "jizhang/jizhang/Assets.xcassets/AppIcon.appiconset/AppIcon.png" ]; then
    echo -e "${GREEN}✅ AppIcon.png 存在${NC}"
    file jizhang/jizhang/Assets.xcassets/AppIcon.appiconset/AppIcon.png | grep -q "PNG image" && echo -e "${GREEN}✅ 图标格式正确${NC}" || echo -e "${RED}❌ 图标格式错误${NC}"
else
    echo -e "${RED}❌ AppIcon.png 不存在${NC}"
fi

if plutil -lint jizhang/jizhang/Info.plist > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Info.plist 格式正确${NC}"
else
    echo -e "${RED}❌ Info.plist 格式错误${NC}"
fi
echo ""

# 步骤 5: 重新编译项目
echo -e "${BLUE}🔨 步骤 5/6: 重新编译项目...${NC}"
cd jizhang
if xcodebuild -project jizhang.xcodeproj -scheme jizhang -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' build > /tmp/build_fix.log 2>&1; then
    echo -e "${GREEN}✅ 编译成功${NC}"
else
    echo -e "${RED}❌ 编译失败，查看日志: /tmp/build_fix.log${NC}"
    tail -50 /tmp/build_fix.log
    exit 1
fi
cd ..
echo ""

# 步骤 6: 检查构建产物
echo -e "${BLUE}📱 步骤 6/6: 检查构建产物...${NC}"
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/jizhang-*/Build/Products/Debug-iphoneos/jizhang.app -type d 2>/dev/null | head -1)
if [ -n "$APP_PATH" ]; then
    echo -e "${GREEN}✅ 找到构建产物: $APP_PATH${NC}"
    
    # 检查 Info.plist
    if [ -f "$APP_PATH/Info.plist" ]; then
        echo -e "${GREEN}✅ Info.plist 已生成${NC}"
        BUNDLE_NAME=$(plutil -extract CFBundleDisplayName raw "$APP_PATH/Info.plist" 2>/dev/null || echo "未设置")
        echo -e "   App 名称: ${BLUE}$BUNDLE_NAME${NC}"
    fi
    
    # 检查图标文件
    if [ -d "$APP_PATH/AppIcon60x60.png" ] || [ -f "$APP_PATH/AppIcon60x60@2x.png" ] || ls "$APP_PATH"/Assets.car > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 图标资源已打包${NC}"
    else
        echo -e "${YELLOW}⚠️  未找到明确的图标文件，但可能在 Assets.car 中${NC}"
    fi
    
    # 检查 Metadata.appintents
    if [ -d "$APP_PATH/Metadata.appintents" ]; then
        echo -e "${GREEN}✅ AppIntents 元数据已生成${NC}"
    else
        echo -e "${YELLOW}⚠️  未找到 AppIntents 元数据${NC}"
    fi
else
    echo -e "${RED}❌ 未找到构建产物${NC}"
fi
echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 清理和构建完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📝 接下来请执行以下步骤：${NC}"
echo ""
echo -e "${BLUE}1. 在真机上完全删除 App${NC}"
echo "   - 长按 App 图标（如果能看到）"
echo "   - 选择 '删除 App' → '删除'"
echo "   - 在设置 → 通用 → iPhone 储存空间中确认已删除"
echo ""
echo -e "${BLUE}2. 重启 iPhone${NC}"
echo "   - 这一步很重要，可以清除系统缓存"
echo ""
echo -e "${BLUE}3. 在 Xcode 中重新安装${NC}"
echo "   - 打开项目: open jizhang/jizhang.xcodeproj"
echo "   - 连接 iPhone"
echo "   - 点击运行按钮 (Cmd + R)"
echo ""
echo -e "${BLUE}4. 验证修复（等待 2-3 分钟）${NC}"
echo "   a) 检查主屏幕图标"
echo "   b) 在 Spotlight 搜索 '简记账'"
echo "   c) 对 Siri 说: '打开简记账'"
echo "   d) 等待 10 分钟后对 Siri 说: '在简记账记一笔'"
echo ""
echo -e "${YELLOW}💡 提示：${NC}"
echo "   - 如果图标还是不显示，在 App 资源库中查找"
echo "   - Siri 自定义指令可能需要 10-30 分钟才能生效"
echo "   - 可以在快捷指令 App 中搜索 '简记账' 验证集成"
echo ""
