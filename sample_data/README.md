# 示例数据文件

这里提供了一些示例数据文件，用于测试 Sidekick 的数据查询功能。

## 文件说明

### users.csv
用户信息表，包含：
- id: 用户ID
- name: 姓名
- age: 年龄
- city: 城市
- salary: 薪资

### orders.json
订单信息表，包含：
- id: 订单ID
- user_id: 用户ID（关联 users 表）
- product: 产品名称
- amount: 订单金额
- date: 订单日期

## 使用方法

1. 启动 Sidekick 应用
2. 将这些文件拖放到应用窗口，或点击"添加文件"按钮选择文件
3. 在左侧边栏查看已加载的表
4. 在 SQL 编辑器中输入查询语句

## 示例查询

```sql
-- 查看所有用户
SELECT * FROM users;

-- 查看所有订单
SELECT * FROM orders;

-- 用户订单统计
SELECT 
    u.name as 用户名,
    u.city as 城市,
    COUNT(o.id) as 订单数量,
    SUM(o.amount) as 总消费
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name, u.city
ORDER BY 总消费 DESC;

-- 各城市消费统计
SELECT 
    u.city as 城市,
    COUNT(DISTINCT u.id) as 用户数,
    COUNT(o.id) as 订单数,
    COALESCE(SUM(o.amount), 0) as 总消费
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.city
ORDER BY 总消费 DESC;

-- 高薪用户的消费情况
SELECT 
    u.name as 用户名,
    u.salary as 薪资,
    COALESCE(SUM(o.amount), 0) as 总消费,
    ROUND(COALESCE(SUM(o.amount), 0) / u.salary * 100, 2) as 消费占薪资比例
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.salary > 10000
GROUP BY u.id, u.name, u.salary
ORDER BY 消费占薪资比例 DESC;
```