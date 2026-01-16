//
//  SQLFormatter.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation

/// SQL 格式化工具
struct SQLFormatter {
    
    private static let indent = "    " // 4 空格缩进
    
    /// 格式化 SQL 语句
    static func format(_ sql: String) -> String {
        let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        
        // 提取并保护注释
        let (sqlWithoutComments, comments) = extractComments(trimmed)
        
        // 标记化
        let tokens = tokenize(sqlWithoutComments)
        
        // 格式化
        let formatted = formatTokens(tokens)
        
        // 还原注释
        let result = restoreComments(formatted, comments: comments)
        
        return result
    }
    
    // MARK: - 注释处理
    
    private static func extractComments(_ sql: String) -> (String, [(Int, String)]) {
        var result = sql
        var comments: [(Int, String)] = []
        var commentIndex = 0
        
        // 提取单行注释 --
        let singleLinePattern = "--[^\n]*"
        if let regex = try? NSRegularExpression(pattern: singleLinePattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range).reversed()
            for match in matches {
                if let swiftRange = Range(match.range, in: result) {
                    let comment = String(result[swiftRange])
                    let placeholder = "/*__COMMENT_\(commentIndex)__*/"
                    comments.append((commentIndex, comment))
                    result.replaceSubrange(swiftRange, with: placeholder)
                    commentIndex += 1
                }
            }
        }
        
        // 提取多行注释 /* */
        let multiLinePattern = "/\\*[^_][\\s\\S]*?\\*/"
        if let regex = try? NSRegularExpression(pattern: multiLinePattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range).reversed()
            for match in matches {
                if let swiftRange = Range(match.range, in: result) {
                    let comment = String(result[swiftRange])
                    let placeholder = "/*__COMMENT_\(commentIndex)__*/"
                    comments.append((commentIndex, comment))
                    result.replaceSubrange(swiftRange, with: placeholder)
                    commentIndex += 1
                }
            }
        }
        
        return (result, comments)
    }
    
    private static func restoreComments(_ sql: String, comments: [(Int, String)]) -> String {
        var result = sql
        for (index, comment) in comments {
            let placeholder = "/*__COMMENT_\(index)__*/"
            result = result.replacingOccurrences(of: placeholder, with: comment)
        }
        return result
    }
    
    // MARK: - 标记化
    
    private enum Token {
        case keyword(String)
        case identifier(String)
        case symbol(String)
        case string(String)
        case number(String)
        case comment(String)
        case whitespace
    }
    
    private static let mainKeywords = Set([
        "select", "from", "where", "group", "having", "order", "limit", "offset",
        "insert", "into", "values", "update", "set", "delete",
        "create", "alter", "drop", "truncate", "table",
        "union", "intersect", "except", "with"
    ])
    
    private static let subKeywords = Set([
        "and", "or", "not", "in", "between", "like", "is", "null", "as",
        "on", "using", "case", "when", "then", "else", "end",
        "join", "inner", "left", "right", "full", "cross", "outer",
        "by", "asc", "desc", "nulls", "first", "last",
        "distinct", "all", "exists", "any", "some",
        "over", "partition", "rows", "range", "unbounded", "preceding", "following", "current", "row"
    ])
    
    private static func tokenize(_ sql: String) -> [Token] {
        var tokens: [Token] = []
        var current = sql.startIndex
        let end = sql.endIndex
        
        while current < end {
            let char = sql[current]
            
            // 空白
            if char.isWhitespace {
                current = sql.index(after: current)
                continue
            }
            
            // 字符串 (单引号或双引号)
            if char == "'" || char == "\"" {
                let quote = char
                var str = String(char)
                current = sql.index(after: current)
                while current < end {
                    let c = sql[current]
                    str.append(c)
                    current = sql.index(after: current)
                    if c == quote {
                        // 检查转义
                        if current < end && sql[current] == quote {
                            str.append(sql[current])
                            current = sql.index(after: current)
                        } else {
                            break
                        }
                    }
                }
                tokens.append(.string(str))
                continue
            }
            
            // 反引号标识符
            if char == "`" {
                var str = String(char)
                current = sql.index(after: current)
                while current < end && sql[current] != "`" {
                    str.append(sql[current])
                    current = sql.index(after: current)
                }
                if current < end {
                    str.append(sql[current])
                    current = sql.index(after: current)
                }
                tokens.append(.identifier(str))
                continue
            }
            
            // 注释占位符
            if char == "/" && current < sql.index(before: end) {
                let next = sql[sql.index(after: current)]
                if next == "*" {
                    var comment = "/*"
                    current = sql.index(current, offsetBy: 2)
                    while current < end {
                        let c = sql[current]
                        comment.append(c)
                        if c == "*" && sql.index(after: current) < end && sql[sql.index(after: current)] == "/" {
                            current = sql.index(after: current)
                            comment.append(sql[current])
                            current = sql.index(after: current)
                            break
                        }
                        current = sql.index(after: current)
                    }
                    tokens.append(.comment(comment))
                    continue
                }
            }
            
            // 数字
            if char.isNumber || (char == "." && current < sql.index(before: end) && sql[sql.index(after: current)].isNumber) {
                var num = String(char)
                current = sql.index(after: current)
                while current < end && (sql[current].isNumber || sql[current] == ".") {
                    num.append(sql[current])
                    current = sql.index(after: current)
                }
                tokens.append(.number(num))
                continue
            }
            
            // 标识符或关键字
            if char.isLetter || char == "_" {
                var word = String(char)
                current = sql.index(after: current)
                while current < end && (sql[current].isLetter || sql[current].isNumber || sql[current] == "_") {
                    word.append(sql[current])
                    current = sql.index(after: current)
                }
                let lower = word.lowercased()
                if mainKeywords.contains(lower) || subKeywords.contains(lower) {
                    tokens.append(.keyword(lower))
                } else {
                    tokens.append(.identifier(word))
                }
                continue
            }
            
            // 多字符操作符
            let nextIndex = sql.index(after: current)
            if nextIndex < end {
                let next = sql[nextIndex]
                let twoChar = String(char) + String(next)
                if [">=", "<=", "!=", "<>", "||", "&&", "::", "=>"].contains(twoChar) {
                    tokens.append(.symbol(twoChar))
                    current = sql.index(current, offsetBy: 2)
                    continue
                }
            }
            
            // 单字符符号
            tokens.append(.symbol(String(char)))
            current = sql.index(after: current)
        }
        
        return tokens
    }
    
    // MARK: - 格式化
    
    private static func formatTokens(_ tokens: [Token]) -> String {
        var result = ""
        var currentIndent = 0
        var i = 0
        var inSelect = false
        var inCase = false
        var caseDepth = 0
        var afterKeyword = false
        var lineStart = true
        
        func newLine() {
            result += "\n" + String(repeating: indent, count: currentIndent)
            lineStart = true
        }
        
        func append(_ str: String) {
            if !lineStart && !result.hasSuffix(" ") && !result.hasSuffix("\n") && !str.hasPrefix(" ") {
                result += " "
            }
            result += str
            lineStart = false
        }
        
        while i < tokens.count {
            let token = tokens[i]
            
            switch token {
            case .keyword(let kw):
                switch kw {
                case "select":
                    if !result.isEmpty { newLine() }
                    append("select")
                    currentIndent = 1
                    newLine()
                    inSelect = true
                    afterKeyword = true
                    
                case "from", "where", "having", "limit", "offset":
                    currentIndent = 0
                    newLine()
                    append(kw)
                    currentIndent = 1
                    newLine()
                    inSelect = false
                    afterKeyword = true
                    
                case "group", "order":
                    // 检查是否是 group by / order by
                    if i + 1 < tokens.count, case .keyword("by") = tokens[i + 1] {
                        currentIndent = 0
                        newLine()
                        append(kw + " by")
                        currentIndent = 1
                        newLine()
                        i += 1
                        inSelect = false
                        afterKeyword = true
                    } else {
                        append(kw)
                    }
                    
                case "partition":
                    // partition by
                    if i + 1 < tokens.count, case .keyword("by") = tokens[i + 1] {
                        append("partition by")
                        i += 1
                    } else {
                        append(kw)
                    }
                    
                case "union", "intersect", "except":
                    currentIndent = 0
                    newLine()
                    // 检查 union all
                    if kw == "union" && i + 1 < tokens.count, case .keyword("all") = tokens[i + 1] {
                        append("union all")
                        i += 1
                    } else {
                        append(kw)
                    }
                    newLine()
                    
                case "join", "inner", "left", "right", "full", "cross":
                    // 处理各种 join
                    var joinType = kw
                    var j = i + 1
                    while j < tokens.count {
                        if case .keyword(let next) = tokens[j] {
                            if next == "outer" || next == "join" {
                                joinType += " " + next
                                if next == "join" { break }
                            } else {
                                break
                            }
                        } else {
                            break
                        }
                        j += 1
                    }
                    currentIndent = 1
                    newLine()
                    append(joinType)
                    i = j
                    
                case "on":
                    currentIndent = 2
                    newLine()
                    append("on")
                    
                case "and":
                    newLine()
                    append("and")
                    
                case "or":
                    newLine()
                    append("or")
                    
                case "case":
                    if !inCase {
                        inCase = true
                        caseDepth = currentIndent
                    }
                    newLine()
                    append("case")
                    currentIndent += 1
                    
                case "when":
                    newLine()
                    append("when")
                    
                case "then":
                    append("then")
                    
                case "else":
                    newLine()
                    append("else")
                    
                case "end":
                    currentIndent = caseDepth
                    newLine()
                    append("end")
                    inCase = false
                    
                case "as":
                    append("as")
                    
                case "is":
                    append("is")
                    
                case "not":
                    append("not")
                    
                case "null":
                    append("null")
                    
                case "like", "between", "in", "exists":
                    append(kw)
                    
                case "asc", "desc":
                    append(kw)
                    
                case "distinct":
                    append("distinct")
                    
                default:
                    append(kw)
                }
                
            case .identifier(let id):
                append(id)
                afterKeyword = false
                
            case .string(let str):
                append(str)
                afterKeyword = false
                
            case .number(let num):
                append(num)
                afterKeyword = false
                
            case .symbol(let sym):
                if sym == "," {
                    result += ","
                    if inSelect {
                        newLine()
                    }
                } else if sym == "." {
                    // 点号前后不加空格
                    // 移除点号前的空格
                    while result.hasSuffix(" ") {
                        result.removeLast()
                    }
                    result += "."
                    // 标记下一个 token 不需要前置空格
                    lineStart = true
                } else if sym == "(" {
                    result += "("
                    lineStart = true
                } else if sym == ")" {
                    result += ")"
                    lineStart = false
                } else if sym == ";" {
                    result += ";"
                    newLine()
                } else {
                    // 操作符前后加空格
                    append(sym)
                }
                afterKeyword = false
                
            case .comment(let comment):
                append(comment)
                
            case .whitespace:
                break
            }
            
            i += 1
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
