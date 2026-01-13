#!/bin/bash

echo "🚀 启动 TableQuery..."

# 检查是否已经构建
if [ ! -d ".build" ]; then
    echo "📦 首次构建项目..."
    swift build
fi

# 尝试运行应用
echo "🖥️  启动应用界面..."
swift run &

# 等待一下让应用启动
sleep 2

echo "✅ TableQuery 已启动！"
echo ""
echo "使用说明："
echo "1. 将 CSV 或 JSON 文件拖放到应用窗口"
echo "2. 或点击'添加文件'按钮选择文件"
echo "3. 在 SQL 编辑器中输入查询语句"
echo "4. 按 ⌘+Enter 执行查询"
echo ""
echo "示例数据文件位于 sample_data/ 目录"
echo ""
echo "如果应用没有显示窗口，请："
echo "1. 检查 Dock 中是否有 TableQuery 图标"
echo "2. 或者使用 Xcode 运行: open Package.swift"