#!/bin/bash

# Sidekick 许可证系统测试脚本

echo "🧪 Sidekick 许可证系统测试"
echo "================================"
echo ""

# 1. 生成测试激活码
echo "1️⃣  生成测试激活码..."
echo ""

TEST_EMAIL="test@example.com"

# 创建临时 Swift 文件获取机器码
cat > /tmp/get_machine_id.swift << 'EOF'
import Foundation
import IOKit

let platformExpert = IOServiceGetMatchingService(
    kIOMainPortDefault,
    IOServiceMatching("IOPlatformExpertDevice")
)

if platformExpert > 0 {
    if let uuid = IORegistryEntryCreateCFProperty(
        platformExpert,
        "IOPlatformUUID" as CFString,
        kCFAllocatorDefault,
        0
    ).takeUnretainedValue() as? String {
        print(uuid)
    }
    IOObjectRelease(platformExpert)
}
EOF

MACHINE_ID=$(swift /tmp/get_machine_id.swift)
rm /tmp/get_machine_id.swift

echo "测试邮箱: $TEST_EMAIL"
echo "机器码: $MACHINE_ID"
echo ""

# 生成激活码
LICENSE_KEY=$(swift generate_license.swift "$TEST_EMAIL" "$MACHINE_ID" 2>/dev/null | grep "激活码:" | awk '{print $2}')

if [ -z "$LICENSE_KEY" ]; then
    echo "❌ 激活码生成失败"
    exit 1
fi

echo "✅ 激活码生成成功: $LICENSE_KEY"
echo ""

# 2. 清除现有许可证数据（用于测试）
echo "2️⃣  清除现有许可证数据..."
defaults delete com.yourcompany.Sidekick Sidekick.License 2>/dev/null
defaults delete com.yourcompany.Sidekick Sidekick.TrialStart 2>/dev/null
echo "✅ 已清除"
echo ""

# 3. 测试试用期
echo "3️⃣  测试试用期..."
echo "   - 首次启动应显示 90 天试用期"
echo "   - 可以在应用中查看剩余天数"
echo ""

# 4. 测试激活
echo "4️⃣  测试激活..."
echo "   - 在应用中点击'激活'按钮"
echo "   - 输入邮箱: $TEST_EMAIL"
echo "   - 输入激活码: $LICENSE_KEY"
echo "   - 应该激活成功"
echo ""

# 5. 测试过期
echo "5️⃣  测试试用期过期..."
echo "   运行以下命令模拟试用期过期:"
echo "   defaults write com.yourcompany.Sidekick Sidekick.TrialStart -date \"\$(date -v-91d)\""
echo "   然后重启应用，应该显示过期提示"
echo ""

echo "================================"
echo "📝 测试清单:"
echo ""
echo "□ 首次启动显示 90 天试用期"
echo "□ 设置中显示剩余天数"
echo "□ 菜单栏显示试用期信息"
echo "□ 激活码验证成功"
echo "□ 激活后显示已激活状态"
echo "□ 试用期过期后显示遮罩"
echo "□ 过期后无法使用功能"
echo "□ 激活后可以正常使用"
echo ""
echo "🎯 开始测试吧！"
echo ""
