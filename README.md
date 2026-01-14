# Sidekick

你的开发助手 - 集数据查询、格式转换、开发工具于一体的 macOS 应用

## 简介

Sidekick 是一款为 macOS 开发者打造的多功能工具箱，集成了数据查询、格式转换、编码工具等常用功能。无论是 SQL 查询、JSON 处理、时间戳转换还是 IP 地址计算，Sidekick 都能帮你快速完成。

## 核心功能

### 📊 数据查询
- **文件加载**: 支持 CSV、JSON/JSONL 和 XLSX 格式
- **智能类型推断**: 自动识别 INTEGER、REAL、TEXT、BOOLEAN 类型
- **多表管理**: 同时加载多个数据文件，支持 JOIN 查询
- **SQL 查询**: 基于 SQLite 内存数据库，支持完整 SQL 语法
- **数据持久化**: 自动保存已加载的表，重启后自动恢复
- **数据导出**: 导出为 CSV、JSON 或 INSERT 语句

### 🛠️ 开发工具

#### JSON 工具
- **扁平化**: 列式 JSON → 行式 JSON
- **格式化**: 美化 JSON 格式
- **压缩**: 移除空格和换行
- **验证**: 检查 JSON 格式
- **路径查询**: JSONPath 查询

#### IP 工具
- **格式转换**: IP ↔ 整数 ↔ 十六进制
- **子网计算**: CIDR 子网信息
- **地址验证**: 验证 IP 格式
- **批量处理**: 批量转换 IP 列表

#### 时间戳工具
- **实时显示**: 当前时间戳（秒/毫秒/微秒）
- **时间戳转日期**: 支持多种单位和时区
- **日期转时间戳**: 支持多种日期格式
- **单位切换**: 秒/毫秒/微秒自由切换
- **时区支持**: Asia/Shanghai, UTC, America/New_York

#### 文本工具
- **Base64**: 编码/解码
- **URL 编码**: URL 编码/解码
- **Hash**: MD5/SHA 计算
- **文本对比**: 对比两段文本差异

#### 其他工具
- **UUID**: 生成 UUID
- **颜色转换**: HEX ↔ RGB
- **正则测试**: 正则表达式测试

### ⌨️ 快捷键
- **⌘+Enter**: 执行 SQL 查询
- **⌘+N**: 添加新文件
- **⌘+W**: 清除所有数据

### 🌏 中文界面
完整的中文用户界面和错误提示

## 快速开始

### 1. 构建应用

```bash
# 克隆项目
git clone <repository-url>
cd Sidekick

# 构建项目
swift build

# 运行测试（可选）
swift test
```

### 2. 运行应用

**推荐方式：使用 Xcode**

```bash
# 打开项目
open Package.swift

# 在 Xcode 中：
# 1. 等待项目加载完成
# 2. 选择 "Sidekick" scheme
# 3. 点击运行按钮 (▶️) 或按 ⌘+R
```

**或者使用启动脚本：**

```bash
# 使用提供的启动脚本
./run.sh
```

**注意**: SwiftUI Mac 应用最好通过 Xcode 运行，这样可以确保正确的窗口管理和调试支持。

## 使用指南

### 加载数据文件

1. **拖放文件**: 将 CSV、JSON 或 XLSX 文件拖放到应用窗口
2. **点击添加**: 点击"添加文件"按钮选择文件
3. **键盘快捷键**: 按 ⌘+N 打开文件选择器
4. **自动恢复**: 重启应用后，之前加载的表会自动恢复

支持的文件格式：
- **CSV**: 标准 CSV 格式，自动检测分隔符和引号
- **JSON**: JSON 数组格式 `[{...}, {...}]`
- **JSONL**: 每行一个 JSON 对象
- **XLSX**: Excel 文件格式（读取第一个工作表）

### 数据持久化

应用会自动保存已加载的表信息：
- 文件路径会被保存到 UserDefaults
- 重启应用时自动重新加载这些文件
- 如果文件被移动或删除，会跳过该文件并显示警告
- 使用"清除所有数据"可以清空持久化信息

### 查看数据

加载文件后，左侧边栏会显示：
- 表名（基于文件名）
- 行数和列数
- 点击展开可查看列名和数据类型

### 执行 SQL 查询

1. 在 SQL 编辑器中输入查询语句
2. 点击"执行查询"按钮或按 ⌘+Enter
3. 查看结果表格，显示行数和执行时间

#### 示例查询

```sql
-- 查看所有数据
SELECT * FROM users;

-- 条件查询
SELECT name, age FROM users WHERE age > 25;

-- 多表 JOIN
SELECT u.name, o.amount 
FROM users u 
JOIN orders o ON u.id = o.user_id;

-- 聚合查询
SELECT COUNT(*), AVG(age) FROM users;

-- 排序和限制
SELECT * FROM users ORDER BY age DESC LIMIT 10;
```

### 导出数据

查询结果可以导出为多种格式：

1. **CSV 格式**: 点击"导出 CSV"，保存为 .csv 文件
2. **JSON 格式**: 点击"导出 JSON"，保存为 .json 文件  
3. **INSERT 语句**: 点击"生成 INSERT"，保存为 .sql 文件

### 多表操作

- **加载多个文件**: 可以同时加载多个数据文件
- **表管理**: 在左侧边栏查看所有已加载的表
- **移除表**: 点击表旁边的 ❌ 按钮移除不需要的表
- **JOIN 查询**: 使用标准 SQL JOIN 语法关联多个表

## 数据类型支持

TableQuery 自动推断以下数据类型：

- **INTEGER**: 整数（如 123, -456）
- **REAL**: 浮点数（如 3.14, -2.5）
- **TEXT**: 文本字符串（如 "Hello", "用户名"）
- **BOOLEAN**: 布尔值（true/false）
- **NULL**: 空值（空字符串或 null）

## 键盘快捷键

- **⌘+Enter**: 执行 SQL 查询
- **⌘+N**: 添加新文件
- **⌘+W**: 清除所有数据

## 错误处理

应用提供详细的中文错误信息：

- **文件格式错误**: 显示支持的格式列表
- **SQL 语法错误**: 显示具体的语法问题
- **文件读取错误**: 提供解决建议
- **导出错误**: 指导如何修复问题

## 示例数据

### CSV 示例 (users.csv)
```csv
id,name,age,city
1,张三,25,北京
2,李四,30,上海
3,王五,28,广州
```

### JSON 示例 (orders.json)
```json
[
  {"id": 1, "user_id": 1, "amount": 100.50, "date": "2024-01-15"},
  {"id": 2, "user_id": 2, "amount": 250.00, "date": "2024-01-16"},
  {"id": 3, "user_id": 1, "amount": 75.25, "date": "2024-01-17"}
]
```

### 多表查询示例
```sql
SELECT 
    u.name as 用户名,
    u.city as 城市,
    COUNT(o.id) as 订单数量,
    SUM(o.amount) as 总金额
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name, u.city
ORDER BY 总金额 DESC;
```

## 技术架构

- **Swift + SwiftUI**: 现代 Mac 应用开发
- **SQLite**: 内存数据库，支持完整 SQL 功能
- **MVVM 架构**: 清晰的代码组织结构
- **属性测试**: 78 个测试确保代码质量

### 技术难点

项目开发过程中遇到的主要技术难点是 **SwiftUI macOS 应用的键盘输入问题**。

**问题**: Swift Package Manager 构建的 SwiftUI 应用默认使用 `.accessory` 激活策略，导致应用无法正确接收键盘输入。

**解决方案**: 使用 `@NSApplicationDelegateAdaptor` 添加 AppDelegate，并设置 `NSApp.setActivationPolicy(.regular)`。

详细的排查过程和解决方案请参考：
- [SwiftUI键盘输入问题解决方案](docs/项目难点记录/SwiftUI键盘输入问题解决方案.md)
- [SwiftUI键盘输入问题排查记录](docs/项目难点记录/SwiftUI键盘输入问题排查记录.md)

## 系统要求

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本（开发）
- Swift 5.9 或更高版本

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**Sidekick - Your Coding Companion** 🚀

## 故障排除

### SQL 查询框键盘输入问题

**问题**: SQL 查询框无法接收键盘输入

**原因**: SwiftUI macOS 应用的键盘焦点问题

**解决方案**:
1. **使用 Xcode 运行**: 推荐使用 Xcode 打开项目并运行（⌘+R）
   ```bash
   open Package.swift
   # 在 Xcode 中按 ⌘+R 运行
   ```

2. **确保应用获得焦点**: 
   - 点击应用窗口确保它是活动窗口
   - 点击 SQL 编辑器区域
   - 尝试使用 Tab 键切换焦点到编辑器

3. **重启应用**: 如果问题持续，完全退出应用并重新启动

4. **检查系统权限**: 
   - 系统设置 → 隐私与安全性 → 辅助功能
   - 确保终端或 Xcode 有必要的权限

**技术说明**: 
- 应用使用 AppDelegate 来确保正确的键盘焦点
- SQL 编辑器使用自定义 NSTextView 实现
- 如果使用 `swift run` 启动，可能会遇到焦点问题
- 推荐使用 Xcode 运行以获得最佳体验

### 应用没有显示窗口

如果运行 `swift run` 后没有看到应用窗口：

1. **检查 Dock**: 查看 Dock 中是否有 Sidekick 图标，点击激活
2. **使用 Xcode**: 推荐使用 Xcode 运行应用
   ```bash
   open Package.swift
   # 在 Xcode 中按 ⌘+R 运行
   ```
3. **检查进程**: 确认应用是否在运行
   ```bash
   ps aux | grep Sidekick
   ```
4. **重新构建**: 清理并重新构建
   ```bash
   swift package clean
   swift build
   ```

### 文件加载问题

- 确保文件格式正确（CSV 或 JSON）
- 检查文件编码是否为 UTF-8
- 查看错误消息获取具体问题

### SQL 查询错误

- 检查表名是否正确（基于文件名）
- 确认 SQL 语法正确
- 查看左侧边栏确认表已加载

### 性能问题

- 大文件（>10MB）可能需要较长加载时间
- 复杂查询可能需要更多执行时间
- 考虑使用 LIMIT 限制结果数量