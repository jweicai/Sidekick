//
//  QueryHistory.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation

/// 查询历史记录
struct QueryHistory: Identifiable, Codable {
    let id: UUID
    let query: String
    let executedAt: Date
    let rowCount: Int?
    let executionTime: TimeInterval?
    let isSuccess: Bool
    
    init(
        id: UUID = UUID(),
        query: String,
        executedAt: Date = Date(),
        rowCount: Int? = nil,
        executionTime: TimeInterval? = nil,
        isSuccess: Bool = true
    ) {
        self.id = id
        self.query = query
        self.executedAt = executedAt
        self.rowCount = rowCount
        self.executionTime = executionTime
        self.isSuccess = isSuccess
    }
    
    /// 格式化的执行时间
    var formattedExecutionTime: String {
        guard let time = executionTime else { return "-" }
        return String(format: "%.3fs", time)
    }
    
    /// 格式化的日期时间
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: executedAt)
    }
    
    /// 查询预览（前50个字符）
    var preview: String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 50 {
            return String(trimmed.prefix(50)) + "..."
        }
        return trimmed
    }
}

/// 查询历史管理器
class QueryHistoryManager {
    static let shared = QueryHistoryManager()
    
    private let maxHistoryCount = 50
    private let historyKey = "Sidekick.QueryHistory"
    
    private init() {}
    
    /// 保存查询历史
    func saveHistory(_ history: QueryHistory) {
        var histories = loadHistories()
        histories.insert(history, at: 0)
        
        // 限制历史记录数量
        if histories.count > maxHistoryCount {
            histories = Array(histories.prefix(maxHistoryCount))
        }
        
        if let encoded = try? JSONEncoder().encode(histories) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    /// 加载查询历史
    func loadHistories() -> [QueryHistory] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let histories = try? JSONDecoder().decode([QueryHistory].self, from: data) else {
            return []
        }
        return histories
    }
    
    /// 删除指定历史记录
    func deleteHistory(id: UUID) {
        var histories = loadHistories()
        histories.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(histories) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    /// 清空所有历史记录
    func clearAllHistories() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}
