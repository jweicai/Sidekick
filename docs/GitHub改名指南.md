# GitHub 仓库改名指南

## 📝 需要手动完成的步骤

由于 GitHub 仓库改名需要在网页上操作，请按照以下步骤完成：

---

## 🔧 步骤1：在 GitHub 上改名

1. 打开浏览器，访问：https://github.com/jweicai/QueryKit

2. 点击 **Settings**（设置）

3. 在 **Repository name** 输入框中，将 `QueryKit` 改为 `TableQuery`

4. 点击 **Rename** 按钮

5. GitHub 会自动设置重定向，旧链接仍然可用

---

## 🔧 步骤2：推送本地更改

改名完成后，在终端执行：

```bash
cd ~/tools/TableQuery
git push
```

---

## ✅ 验证改名成功

访问新地址确认：
https://github.com/jweicai/TableQuery

---

## 📋 改名完成后的检查清单

- [ ] GitHub 仓库已改名
- [ ] 本地代码已推送
- [ ] README.md 已更新
- [ ] 所有文档中的项目名称已更新
- [ ] Git 远程地址已更新

---

## 🎉 改名完成！

改名后，你可以：
1. 继续开发 TableQuery
2. 创建 Xcode 项目
3. 开始编写代码

---

**注意**：GitHub 会自动将 `QueryKit` 重定向到 `TableQuery`，所以旧链接仍然可用。
