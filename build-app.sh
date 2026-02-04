#!/bin/bash

set -e

echo "🔨 Building Sidekick.app..."

# 1. 清理并构建
echo "📦 Building executable..."
swift build -c release

# 2. 创建 .app 目录结构
APP_NAME="Sidekick"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📁 Creating app bundle structure..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 3. 复制可执行文件
echo "📋 Copying executable..."
cp .build/release/Sidekick "$MACOS_DIR/"

# 4. 创建 Info.plist
echo "📝 Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>Sidekick</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.sidekick.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Sidekick</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 Sidekick. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# 5. 复制资源文件
echo "🎨 Copying resources..."
if [ -d "Sources/Resources" ]; then
    cp -r Sources/Resources/* "$RESOURCES_DIR/" 2>/dev/null || true
fi

# 6. 创建 .icns 文件（从 PNG 图标）
echo "🖼️  Creating app icon..."
ICONSET_DIR="$RESOURCES_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

# 复制 PNG 图标到 iconset
if [ -d "Sources/Resources/Assets.xcassets/AppIcon.appiconset" ]; then
    cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/*.png "$ICONSET_DIR/" 2>/dev/null || true
    
    # 生成 .icns 文件
    if command -v iconutil &> /dev/null; then
        iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
        rm -rf "$ICONSET_DIR"
        echo "✅ Icon created successfully"
    else
        echo "⚠️  iconutil not found, skipping .icns creation"
    fi
fi

# 7. 设置可执行权限
chmod +x "$MACOS_DIR/Sidekick"

echo ""
echo "✅ Build complete!"
echo "📦 Application: $APP_DIR"
echo ""
echo "To run the app:"
echo "  open $APP_DIR"
echo ""
echo "To install to Applications:"
echo "  cp -r $APP_DIR /Applications/"
echo ""

# 8. 自动打开应用
read -p "Open the app now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$APP_DIR"
fi
