#!/bin/bash
# 构建完整的 macOS .app 包

set -e

echo "🔨 开始构建 Sidekick.app..."

# 编译项目
echo "📦 编译项目..."
swift build -c release

# 创建 .app 包结构
APP_NAME="Sidekick.app"
APP_DIR="build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📁 创建应用包结构..."
rm -rf build
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 复制可执行文件
echo "📋 复制可执行文件..."
cp .build/release/Sidekick "$MACOS_DIR/"

# 复制 Info.plist
echo "📋 复制 Info.plist..."
cp Info.plist "$CONTENTS_DIR/"

# 生成 .icns 文件（从 AppIcon.appiconset）
echo "🎨 生成应用图标..."
ICONSET_DIR="Sources/Resources/Assets.xcassets/AppIcon.appiconset"
ICONSET_TMP="build/AppIcon.iconset"
mkdir -p "$ICONSET_TMP"

# 复制并重命名图标文件为 iconutil 需要的格式
cp "$ICONSET_DIR/icon_16x16.png" "$ICONSET_TMP/icon_16x16.png"
cp "$ICONSET_DIR/icon_16x16@2x.png" "$ICONSET_TMP/icon_16x16@2x.png"
cp "$ICONSET_DIR/icon_32x32.png" "$ICONSET_TMP/icon_32x32.png"
cp "$ICONSET_DIR/icon_32x32@2x.png" "$ICONSET_TMP/icon_32x32@2x.png"
cp "$ICONSET_DIR/icon_128x128.png" "$ICONSET_TMP/icon_128x128.png"
cp "$ICONSET_DIR/icon_128x128@2x.png" "$ICONSET_TMP/icon_128x128@2x.png"
cp "$ICONSET_DIR/icon_256x256.png" "$ICONSET_TMP/icon_256x256.png"
cp "$ICONSET_DIR/icon_256x256@2x.png" "$ICONSET_TMP/icon_256x256@2x.png"
cp "$ICONSET_DIR/icon_512x512.png" "$ICONSET_TMP/icon_512x512.png"
cp "$ICONSET_DIR/icon_512x512@2x.png" "$ICONSET_TMP/icon_512x512@2x.png"

# 生成 .icns 文件
iconutil -c icns "$ICONSET_TMP" -o "$RESOURCES_DIR/AppIcon.icns"

echo ""
echo "✅ 构建完成！"
echo "📦 应用位置：$APP_DIR"
echo ""
echo "🚀 运行应用："
echo "   open build/$APP_NAME"
echo ""
echo "📥 安装到应用程序文件夹："
echo "   cp -r build/$APP_NAME /Applications/"
echo ""
