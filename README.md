# Sidekick

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-orange.svg)
![Swift](https://img.shields.io/badge/swift-5.9+-red.svg)

**开发者工具箱 - 数据查询 + 开发工具一体化的 macOS 应用**

[![下载最新版本](https://img.shields.io/badge/下载-v1.0.0-blue.svg)](https://github.com/jweicai/Sidekick/releases/latest)

</div>

## 简介

免费开源的 macOS 开发者工具箱，集成数据查询和常用开发工具。

- 🆓 完全免费开源（MIT 许可证）
- 🔒 隐私优先，本地处理
- ⚡ 原生性能（Swift + SwiftUI）

## 功能

**数据查询**
- 支持 CSV、JSON、XLSX、Parquet、Markdown
- SQL 查询（基于 DuckDB）
- 多表 JOIN、数据导出

**开发工具**
- JSON 格式化、扁平化、验证
- IP 地址转换、子网计算
- 时间戳转换、Base64 编码
- UUID 生成、Hash 计算等

## 下载安装

**[⬇️ 下载 Sidekick v1.0.0](https://github.com/jweicai/Sidekick/releases/latest/download/Sidekick-1.0.0-macOS.dmg)**

**系统要求：** macOS 14.0+，Apple Silicon (M1/M2/M3/M4)

**安装：** 下载 DMG → 拖拽到 Applications → 打开应用

*首次运行可能需要在系统设置中允许运行*

## 快速开始

1. 拖放数据文件到应用窗口
2. 在 SQL 编辑器中输入查询
3. 按 ⌘+Enter 执行

```sql
-- 示例查询
SELECT * FROM users WHERE age > 25;
SELECT u.name, o.amount FROM users u JOIN orders o ON u.id = o.user_id;
```

## 开发

```bash
git clone https://github.com/jweicai/Sidekick.git
cd Sidekick
open Package.swift  # 使用 Xcode 打开
```

## 许可证

MIT 许可证 - 完全免费开源

---

**反馈与支持：** [GitHub Issues](https://github.com/jweicai/Sidekick/issues)