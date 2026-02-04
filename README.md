# Sidekick

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-orange.svg)
![Swift](https://img.shields.io/badge/swift-5.9+-red.svg)

**你的开发助手 - 数据查询 + 开发工具一体化的 macOS 应用**

[![下载最新版本](https://img.shields.io/badge/下载-v1.0.0-blue.svg)](https://github.com/jweicai/Sidekick/releases/latest)

[功能特性](#核心功能) • [下载安装](#下载安装) • [开发指南](#开发指南) • [贡献](CONTRIBUTING.md)

</div>

---

## ✨ 简介

Sidekick 是一款**完全免费开源**的 macOS 开发者工具箱，集成了数据查询、格式转换、编码工具等常用功能。

**核心特点：**
- 🆓 完全免费开源（MIT 许可证）
- 🔒 隐私优先，所有数据本地处理
- ⚡ 原生性能（Swift + SwiftUI）
- 🌏 完整中文界面

## 核心功能

### 📊 数据查询
- 支持 CSV、JSON、JSONL、XLSX、Parquet、Markdown 格式
- 智能类型推断，自动识别数据类型
- 多表 JOIN 查询，基于 DuckDB 引擎
- 数据导出（CSV、JSON、SQL）
- 数据持久化，重启自动恢复

### 🛠️ 10+ 开发工具
- **JSON**: 扁平化、格式化、压缩、验证、路径查询
- **IP**: 格式转换、子网计算、地址验证、批量处理
- **时间戳**: 实时显示、时间转换、多时区支持
- **文本**: Base64、URL编码、Hash计算、文本对比
- **其他**: UUID生成、颜色转换、正则测试、翻译

## 下载安装

### 📥 下载应用

**[⬇️ 下载 Sidekick v1.0.0](https://github.com/jweicai/Sidekick/releases/latest/download/Sidekick-1.0.0-macOS.dmg)** (18MB)

或访问 [Releases 页面](https://github.com/jweicai/Sidekick/releases) 查看所有版本。

### 💻 安装步骤

1. 下载 `Sidekick-1.0.0-macOS.dmg`
2. 双击打开 DMG 文件
3. 拖拽 Sidekick 到 Applications 文件夹
4. 在 Launchpad 中找到并打开 Sidekick

**首次运行提示：** macOS 可能会显示安全警告，请前往 **系统设置 → 隐私与安全性**，点击「仍要打开」。

### ⚙️ 系统要求

- macOS 14.0 或更高版本
- Apple Silicon (M1/M2/M3/M4)

## 开发指南

### 从源码构建

```bash
# 克隆项目
git clone https://github.com/jweicai/Sidekick.git
cd Sidekick

# 使用 Xcode 打开
open Package.swift

# 或使用命令行构建
swift build -c release
```

详细开发文档请查看 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 快速上手

### 数据查询
1. 拖放 CSV/JSON/Excel 文件到应用窗口（或按 ⌘+N）
2. 在 SQL 编辑器中输入查询语句
3. 按 ⌘+Enter 执行查询
4. 导出结果为 CSV/JSON/SQL

### 示例 SQL 查询
```sql
-- 基本查询
SELECT * FROM users WHERE age > 25;

-- 多表 JOIN
SELECT u.name, o.amount
FROM users u
JOIN orders o ON u.id = o.user_id;

-- 聚合统计
SELECT city, COUNT(*), AVG(age)
FROM users
GROUP BY city;
```

### 快捷键
- **⌘+Enter**: 执行查询
- **⌘+N**: 添加文件
- **⌘+W**: 清除数据

## 🏗️ 技术栈

- **Swift + SwiftUI** - 原生 macOS 应用
- **DuckDB** - 高性能数据引擎
- **MVVM 架构** - 清晰的代码组织
- **~14K 行代码** - 完整测试覆盖

详细技术文档和项目结构请查看 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 🤝 贡献

欢迎贡献代码、报告问题或提出建议！详见 [贡献指南](CONTRIBUTING.md)。

## 📄 许可证

本项目采用 MIT 许可证，完全免费开源。详见 [LICENSE](LICENSE)。

## 💬 反馈与支持

- **问题反馈**: [GitHub Issues](https://github.com/jweicai/Sidekick/issues)
- **功能建议**: [GitHub Issues](https://github.com/jweicai/Sidekick/issues)

## 🙏 致谢

- [DuckDB](https://duckdb.org/) - 高性能分析数据库
- [CoreXLSX](https://github.com/CoreOffice/CoreXLSX) - Excel 文件解析

---

<div align="center">

**Sidekick - Your Coding Companion** 🚀

[GitHub](https://github.com/jweicai/Sidekick) • [下载](https://github.com/jweicai/Sidekick/releases) • [贡献](CONTRIBUTING.md) • [许可证](LICENSE)

</div>