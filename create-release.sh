#!/bin/bash

set -e

echo "🚀 Building Sidekick Release Package..."
echo ""

APP_NAME="Sidekick"
VERSION="1.0.0"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 1. 清理旧构建
echo "🧹 Cleaning..."
rm -rf "$APP_DIR"
rm -rf .build
swift package clean

# 2. 构建发布版本
echo "🔨 Building release version..."
swift build -c release --arch arm64

# 3. 检查可执行文件
EXECUTABLE=$(find .build -name "Sidekick" -type f -perm +111 | grep release | head -1)
if [ -z "$EXECUTABLE" ]; then
    echo "❌ Executable not found!"
    exit 1
fi
echo "✅ Found executable: $EXECUTABLE"

# 4. 创建 .app 结构
echo "📁 Creating app bundle..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 5. 复制可执行文件
echo "📋 Copying executable..."
cp "$EXECUTABLE" "$MACOS_DIR/Sidekick"
chmod +x "$MACOS_DIR/Sidekick"

# 6. 创建 Info.plist
echo "📝 Creating Info.plist..."
cp Info.plist "$CONTENTS_DIR/Info.plist"

# 7. 创建应用图标
echo "🎨 Creating app icon..."
ICONSET_DIR="$RESOURCES_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

# 复制图标文件
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_16x16.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_32x32.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png "$ICONSET_DIR/"
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png "$ICONSET_DIR/"

# 生成 .icns 文件
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET_DIR"
echo "✅ App icon created"

# 8. 复制资源文件（如果有）
if [ -d "Sources/Resources/Assets.xcassets" ]; then
    cp -r Sources/Resources/Assets.xcassets "$RESOURCES_DIR/" 2>/dev/null || true
fi

# 9. 创建 PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# 10. 验证构建
echo ""
echo "✅ App bundle created successfully!"
echo ""
echo "📦 Application: $APP_DIR"
ls -lh "$APP_DIR"
echo ""
echo "Size:"
du -sh "$APP_DIR"
echo ""

# 11. 创建 DMG
echo "💿 Creating DMG installer..."
DMG_NAME="$APP_NAME-$VERSION-macOS.dmg"
rm -f "$DMG_NAME"

# 创建一个临时目录用于 DMG 内容
DMG_DIR="dmg_temp"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# 复制 app 到临时目录
cp -r "$APP_DIR" "$DMG_DIR/"

# 创建 Applications 链接
ln -s /Applications "$DMG_DIR/Applications"

# 创建 DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$DMG_NAME"

# 清理临时目录
rm -rf "$DMG_DIR"

echo "✅ DMG created: $DMG_NAME"
du -h "$DMG_NAME"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 App Bundle: $APP_DIR"
echo "💿 Installer: $DMG_NAME"
echo ""
echo "To test the app:"
echo "  open $APP_DIR"
echo ""
echo "To distribute:"
echo "  Share $DMG_NAME with users"
echo ""
echo "Installation:"
echo "  1. Open $DMG_NAME"
echo "  2. Drag Sidekick to Applications folder"
echo "  3. Done!"
echo ""

# 测试应用
read -p "🚀 Launch the app now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Launching..."
    open "$APP_DIR"
fi

