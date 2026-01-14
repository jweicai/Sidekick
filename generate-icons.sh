#!/bin/bash
# 生成 macOS 应用图标的所有尺寸

set -e

# 检查源图标是否存在
if [ ! -f "app-icon.png" ]; then
    echo "❌ 错误：请将图标文件保存为 app-icon.png"
    echo "💡 提示：将你的宝箱图标保存到项目根目录，命名为 app-icon.png"
    exit 1
fi

# 创建目标目录
ICON_DIR="Sources/Resources/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICON_DIR"

echo "🎨 开始生成应用图标..."

# 生成各种尺寸
sips -z 16 16 app-icon.png --out "$ICON_DIR/icon_16x16.png" > /dev/null 2>&1
echo "✅ 生成 16x16"

sips -z 32 32 app-icon.png --out "$ICON_DIR/icon_16x16@2x.png" > /dev/null 2>&1
echo "✅ 生成 16x16@2x"

sips -z 32 32 app-icon.png --out "$ICON_DIR/icon_32x32.png" > /dev/null 2>&1
echo "✅ 生成 32x32"

sips -z 64 64 app-icon.png --out "$ICON_DIR/icon_32x32@2x.png" > /dev/null 2>&1
echo "✅ 生成 32x32@2x"

sips -z 128 128 app-icon.png --out "$ICON_DIR/icon_128x128.png" > /dev/null 2>&1
echo "✅ 生成 128x128"

sips -z 256 256 app-icon.png --out "$ICON_DIR/icon_128x128@2x.png" > /dev/null 2>&1
echo "✅ 生成 128x128@2x"

sips -z 256 256 app-icon.png --out "$ICON_DIR/icon_256x256.png" > /dev/null 2>&1
echo "✅ 生成 256x256"

sips -z 512 512 app-icon.png --out "$ICON_DIR/icon_256x256@2x.png" > /dev/null 2>&1
echo "✅ 生成 256x256@2x"

sips -z 512 512 app-icon.png --out "$ICON_DIR/icon_512x512.png" > /dev/null 2>&1
echo "✅ 生成 512x512"

sips -z 1024 1024 app-icon.png --out "$ICON_DIR/icon_512x512@2x.png" > /dev/null 2>&1
echo "✅ 生成 512x512@2x"

echo ""
echo "🎉 图标生成完成！"
echo "📁 图标位置：$ICON_DIR"
echo ""
echo "📝 下一步："
echo "   1. 重新编译项目：swift build"
echo "   2. 或在 Xcode 中重新构建"
echo ""
