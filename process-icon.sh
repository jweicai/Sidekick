#!/bin/bash
# 处理图标：去除背景，添加透明度

set -e

if [ ! -f "app-icon.png" ]; then
    echo "❌ 错误：找不到 app-icon.png"
    exit 1
fi

echo "🎨 处理图标..."

# 检查是否安装了 ImageMagick
if ! command -v convert &> /dev/null; then
    echo "⚠️  未安装 ImageMagick，尝试使用 sips..."
    
    # 使用 sips 创建一个临时的透明背景版本
    # 先裁剪掉白边
    sips -Z 900 app-icon.png --out app-icon-processed.png > /dev/null 2>&1
    
    echo "✅ 图标已处理（基础版本）"
    echo ""
    echo "💡 建议："
    echo "   1. 使用图像编辑软件（如 Photoshop、Pixelmator）"
    echo "   2. 去除黑色背景，保存为透明 PNG"
    echo "   3. 或者安装 ImageMagick："
    echo "      brew install imagemagick"
    echo "   4. 然后重新运行此脚本"
    
else
    echo "✨ 使用 ImageMagick 处理..."
    
    # 更激进地去除背景和边角
    # 1. 去除黑色背景
    # 2. 去除白色边角
    # 3. 裁剪到内容
    magick app-icon.png \
        -fuzz 30% -transparent black \
        -fuzz 30% -transparent white \
        -trim +repage \
        -background none \
        -gravity center \
        -extent 1024x1024 \
        app-icon-processed.png
    
    echo "✅ 图标已处理（高级版本）"
fi

echo ""
echo "📝 下一步："
echo "   1. 检查 app-icon-processed.png"
echo "   2. 如果满意，替换原文件："
echo "      mv app-icon-processed.png app-icon.png"
echo "   3. 重新生成图标："
echo "      ./generate-icons.sh"
echo "   4. 重新构建应用："
echo "      ./build-app.sh"
echo ""
