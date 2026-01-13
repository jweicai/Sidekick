# TableQuery MVP

一个用于查询数据文件的 Mac 应用程序，支持 CSV 和 JSON 格式，提供 SQL 查询功能。

## 功能特性

- 📁 **文件加载**: 支持 CSV 和 JSON/JSONL 格式
- 🔍 **智能类型推断**: 自动识别 INTEGER、REAL、TEXT、BOOLEAN 类型
- 🗃️ **多表管理**: 同时加载多个数据文件，支持 JOIN 查询
- 💾 **SQL 查询**: 基于 SQLite 内存数据库，支持完整 SQL 语法
- 📤 **数据导出**: 导出为 CSV、JSON 或 INSERT 语句
- ⌨️ **键盘快捷键**: ⌘+Enter 执行查询，⌘+N 添加文件
- 🌏 **中文界面**: 完整的中文用户界面和错误提示

## 快速开始

### 1. 构建应用

```bash
# 克隆项目
git clone <repository-url>
cd TableQuery

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
# 2. 选择 "TableQuery" scheme
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

1. **拖放文件**: 将 CSV 或 JSON 文件拖放到应用窗口
2. **点击添加**: 点击"添加文件"按钮选择文件
3. **键盘快捷键**: 按 ⌘+N 打开文件选择器

支持的文件格式：
- **CSV**: 标准 CSV 格式，自动检测分隔符和引号
- **JSON**: JSON 数组格式 `[{...}, {...}]`
- **JSONL**: 每行一个 JSON 对象

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

## 系统要求

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本（开发）
- Swift 5.9 或更高版本

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**享受数据查询的乐趣！** 🚀

## 故障排除

### 应用没有显示窗口

如果运行 `swift run` 后没有看到应用窗口：

1. **检查 Dock**: 查看 Dock 中是否有 TableQuery 图标，点击激活
2. **使用 Xcode**: 推荐使用 Xcode 运行应用
   ```bash
   open Package.swift
   # 在 Xcode 中按 ⌘+R 运行
   ```
3. **检查进程**: 确认应用是否在运行
   ```bash
   ps aux | grep TableQuery
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