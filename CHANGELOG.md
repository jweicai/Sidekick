# 更新日志

本文档记录 Sidekick 项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Changed
- 项目转为开源，采用 MIT 许可证
- 移除许可证系统，所有功能完全免费
- 更新文档适配开源项目

## [1.0.0] - 2025-01-14

### Added
- ✨ 数据查询功能
  - 支持 CSV、JSON、JSONL、XLSX、Parquet、Markdown 文件加载
  - 基于 DuckDB 的 SQL 查询引擎
  - 多表 JOIN 支持
  - 查询结果导出（CSV、JSON、INSERT 语句）
  - 数据持久化，重启自动恢复

- 🛠️ 开发工具集
  - JSON 工具：扁平化、格式化、压缩、验证、路径查询
  - IP 工具：格式转换、子网计算、地址验证、批量处理
  - 时间戳工具：时间戳与日期互转，支持多时区
  - 文本工具：Base64、URL 编码、Hash 计算、文本对比
  - 其他工具：UUID 生成、颜色转换、正则测试、翻译

- 📊 数据管理
  - 智能类型推断
  - 大文件优化处理
  - 拖拽文件加载
  - 剪贴板数据导入

- ⌨️ 快捷键支持
  - ⌘+Enter: 执行 SQL 查询
  - ⌘+N: 添加新文件
  - ⌘+W: 清除所有数据

- 🎨 用户界面
  - 现代化三栏布局
  - 完整中文界面
  - 深色/浅色模式支持
  - 原生 macOS 体验

### Technical
- Swift + SwiftUI 实现
- DuckDB 高性能数据引擎
- MVVM 架构
- 完善的错误处理

## [0.1.0] - 2025-01-12

### Added
- 初始项目结构
- 基础 MVP 功能
- CSV/JSON 文件加载
- SQL 查询引擎原型

---

## 版本说明

- `Added`: 新增功能
- `Changed`: 功能变更
- `Deprecated`: 即将废弃的功能
- `Removed`: 已移除的功能
- `Fixed`: Bug 修复
- `Security`: 安全相关更新
