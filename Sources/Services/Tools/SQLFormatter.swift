//
//  SQLFormatter.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation

/// SQL 格式化工具
struct SQLFormatter {
    
    /// 格式化 SQL 语句
    static func format(_ sql: String) -> String {
        var formatted = sql.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果是空字符串，直接返回
        if formatted.isEmpty {
            return formatted
        }
        
        // 1. 移除多余的空白字符
        formatted = formatted.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // 2. 关键字大写
        formatted = uppercaseKeywords(formatted)
        
        // 3. 添加换行和缩进
        formatted = addLineBreaksAndIndentation(formatted)
        
        // 4. 格式化逗号
        formatted = formatCommas(formatted)
        
        // 5. 清理多余的空行
        formatted = cleanupEmptyLines(formatted)
        
        return formatted
    }
    
    // MARK: - Private Methods
    
    /// 将 SQL 关键字转换为大写
    private static func uppercaseKeywords(_ sql: String) -> String {
        let keywords = [
            // 基本查询
            "select", "from", "where", "group by", "having", "order by", "limit", "offset",
            // 连接
            "join", "inner join", "left join", "right join", "full join", "cross join", "on", "using",
            // 集合操作
            "union", "union all", "intersect", "except",
            // 子查询
            "exists", "in", "not in", "any", "all",
            // 聚合函数
            "count", "sum", "avg", "min", "max",
            // 条件
            "and", "or", "not", "between", "like", "is null", "is not null",
            // 数据操作
            "insert", "into", "values", "update", "set", "delete",
            // 表操作
            "create", "table", "alter", "drop", "truncate",
            // 其他
            "as", "distinct", "case", "when", "then", "else", "end",
            "with", "recursive", "over", "partition by"
        ]
        
        var result = sql
        
        // 按长度降序排序，避免短关键字替换长关键字的一部分
        let sortedKeywords = keywords.sorted { $0.count > $1.count }
        
        for keyword in sortedKeywords {
            // 使用正则表达式匹配完整的单词
            let pattern = "\\b\(keyword)\\b"
            result = result.replacingOccurrences(
                of: pattern,
                with: keyword.uppercased(),
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return result
    }
    
    /// 添加换行和缩进
    private static func addLineBreaksAndIndentation(_ sql: String) -> String {
        var result = sql
        
        // 主要子句前换行
        let mainClauses = [
            "SELECT", "FROM", "WHERE", "GROUP BY", "HAVING", "ORDER BY",
            "LIMIT", "OFFSET", "UNION", "UNION ALL", "INTERSECT", "EXCEPT"
        ]
        
        for clause in mainClauses {
            result = result.replacingOccurrences(
                of: " \(clause) ",
                with: "\n\(clause) "
            )
        }
        
        // JOIN 前换行并缩进
        let joinTypes = ["INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN", "CROSS JOIN", "JOIN"]
        for joinType in joinTypes {
            result = result.replacingOccurrences(
                of: " \(joinType) ",
                with: "\n  \(joinType) "
            )
        }
        
        // ON 条件缩进
        result = result.replacingOccurrences(of: " ON ", with: "\n    ON ")
        
        // AND/OR 在 WHERE 和 HAVING 中换行
        result = formatLogicalOperators(result)
        
        return result
    }
    
    /// 格式化逻辑操作符
    private static func formatLogicalOperators(_ sql: String) -> String {
        var result = ""
        var inWhere = false
        var inHaving = false
        var indentLevel = 0
        
        let lines = sql.components(separatedBy: "\n")
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 检测是否进入 WHERE 或 HAVING 子句
            if trimmedLine.hasPrefix("WHERE") {
                inWhere = true
                inHaving = false
                indentLevel = 1
                result += line + "\n"
                continue
            } else if trimmedLine.hasPrefix("HAVING") {
                inHaving = true
                inWhere = false
                indentLevel = 1
                result += line + "\n"
                continue
            } else if trimmedLine.hasPrefix("GROUP BY") || trimmedLine.hasPrefix("ORDER BY") || 
                      trimmedLine.hasPrefix("LIMIT") || trimmedLine.hasPrefix("OFFSET") {
                inWhere = false
                inHaving = false
                indentLevel = 0
            }
            
            // 在 WHERE 或 HAVING 中格式化 AND/OR
            if inWhere || inHaving {
                var formattedLine = line
                
                // AND 前换行
                formattedLine = formattedLine.replacingOccurrences(
                    of: " AND ",
                    with: "\n" + String(repeating: "  ", count: indentLevel) + "AND "
                )
                
                // OR 前换行
                formattedLine = formattedLine.replacingOccurrences(
                    of: " OR ",
                    with: "\n" + String(repeating: "  ", count: indentLevel) + "OR "
                )
                
                result += formattedLine + "\n"
            } else {
                result += line + "\n"
            }
        }
        
        return result.trimmingCharacters(in: .newlines)
    }
    
    /// 格式化逗号
    private static func formatCommas(_ sql: String) -> String {
        var result = ""
        let lines = sql.components(separatedBy: "\n")
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 在 SELECT 子句中，将逗号后的字段换行
            if trimmedLine.hasPrefix("SELECT") {
                var selectLine = line
                
                // 找到 SELECT 后的内容
                if let selectRange = selectLine.range(of: "SELECT ", options: .caseInsensitive) {
                    let afterSelect = String(selectLine[selectRange.upperBound...])
                    
                    // 分割字段
                    let fields = afterSelect.components(separatedBy: ",")
                    
                    if fields.count > 1 {
                        var formattedSelect = "SELECT "
                        for (index, field) in fields.enumerated() {
                            let trimmedField = field.trimmingCharacters(in: .whitespaces)
                            if index == 0 {
                                formattedSelect += trimmedField
                            } else {
                                formattedSelect += ",\n       " + trimmedField
                            }
                        }
                        result += formattedSelect + "\n"
                        continue
                    }
                }
            }
            
            result += line + "\n"
        }
        
        return result.trimmingCharacters(in: .newlines)
    }
    
    /// 清理多余的空行
    private static func cleanupEmptyLines(_ sql: String) -> String {
        // 移除连续的空行，只保留一个
        var result = sql.replacingOccurrences(
            of: "\n\n+",
            with: "\n\n",
            options: .regularExpression
        )
        
        // 移除行首和行尾的空白
        let lines = result.components(separatedBy: "\n")
        result = lines.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        
        return result
    }
}
