#!/bin/bash

# Sidekick 启动脚本
# 推荐使用 Xcode 运行以获得最佳体验

echo "🚀 Sidekick 启动助手"
echo ""
echo "选择启动方式:"
echo "  1) 在 Xcode 中打开 (推荐)"
echo "  2) 命令行运行"
echo ""
read -p "请选择 (1 或 2): " choice

case $choice in
    1)
        echo ""
        echo "📂 在 Xcode 中打开项目..."
        open Package.swift
        echo ""
        echo "✅ 项目已在 Xcode 中打开"
        echo ""
        echo "📝 下一步:"
        echo "  1. 等待 Xcode 加载完成"
        echo "  2. 按 ⌘+R 运行应用"
        echo "  3. 或点击 Xcode 左上角的运行按钮 (▶️)"
        echo ""
        echo "💡 提示: 使用 Xcode 运行可以确保键盘输入正常工作"
        ;;
    2)
        echo ""
        echo "📦 构建项目..."
        swift build
        
        echo ""
        echo "🖥️  启动应用..."
        swift run &
        
        sleep 2
        
        echo ""
        echo "✅ Sidekick 已启动！"
        echo ""
        echo "⚠️  注意: 命令行启动可能会遇到键盘输入问题"
        echo "   如果 SQL 编辑器无法输入，请使用 Xcode 运行"
        echo ""
        echo "使用说明："
        echo "1. 将 CSV 或 JSON 文件拖放到应用窗口"
        echo "2. 或点击'添加文件'按钮选择文件"
        echo "3. 在 SQL 编辑器中输入查询语句"
        echo "4. 按 ⌘+Enter 执行查询"
        echo ""
        echo "示例数据文件位于 sample_data/ 目录"
        ;;
    *)
        echo ""
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
