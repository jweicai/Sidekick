//
//  QueryViewModel.swift
//  Sidekick
//
//  Created on 2025-01-13.
//
//  职责：
//  1. 管理 SQL 查询执行
//  2. 将表数据注册到 DuckDB
//  3. 管理查询历史（全局共享）
//  4. 管理多个 SQL Console Tab（每个 Tab 有独立的 SQL 和结果集）
//

import Foundation
import Combine

/// 带编号的查询结果
struct NumberedQueryResult: Identifiable {
    let id = UUID()
    let number: Int
    let result: QueryResult
    let query: String
    let executedAt: Date
}

/// SQL Console Tab - 每个 Tab 有独立的 SQL 和结果集
struct SQLConsoleTab: Identifiable {
    let id = UUID()
    let number: Int
    var content: String = ""
    var selectedText: String = ""
    var results: [NumberedQueryResult] = []  // 该 Tab 的查询结果
    var selectedResultId: UUID?  // 当前选中的结果
    var resultCounter: Int = 0  // 结果计数器
    var errorMessage: String?
    var isExecuting: Bool = false
    
    var displayName: String {
        number == 1 ? "SQLConsole" : "SQLConsole \(number)"
    }
    
    /// 当前选中的结果
    var currentResult: NumberedQueryResult? {
        guard let id = selectedResultId else { return results.last }
        return results.first { $0.id == id }
    }
}

/// 查询视图的 ViewModel
class QueryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var consoleTabs: [SQLConsoleTab] = []
    @Published var selectedConsoleId: UUID?
    
    // MARK: - Computed Properties
    
    /// 当前选中的 Console Tab
    var currentConsole: SQLConsoleTab? {
        guard let id = selectedConsoleId else { return consoleTabs.first }
        return consoleTabs.first { $0.id == id }
    }
    
    /// 当前 Console 的索引
    var currentConsoleIndex: Int? {
        guard let id = selectedConsoleId else { return consoleTabs.isEmpty ? nil : 0 }
        return consoleTabs.firstIndex { $0.id == id }
    }
    
    // 兼容旧代码的属性
    var sqlQuery: String {
        get { currentConsole?.content ?? "" }
        set { 
            updateCurrentConsole { $0.content = newValue }
            debounceSave()
        }
    }
    
    var selectedSQLText: String {
        get { currentConsole?.selectedText ?? "" }
        set { updateCurrentConsole { $0.selectedText = newValue } }
    }
    
    var queryResults: [NumberedQueryResult] {
        currentConsole?.results ?? []
    }
    
    var selectedResultId: UUID? {
        get { currentConsole?.selectedResultId }
        set { updateCurrentConsole { $0.selectedResultId = newValue } }
    }
    
    var isExecuting: Bool {
        currentConsole?.isExecuting ?? false
    }
    
    var errorMessage: String? {
        get { currentConsole?.errorMessage }
        set { updateCurrentConsole { $0.errorMessage = newValue } }
    }
    
    var currentResult: NumberedQueryResult? {
        currentConsole?.currentResult
    }
    
    var queryResult: QueryResult? {
        currentResult?.result
    }
    
    // MARK: - Private Properties
    
    private let sqlEngine = DuckDBEngine.shared
    private var cancellables = Set<AnyCancellable>()
    private let consolePersistenceKey = "Sidekick.SQLConsoles"
    private var consoleCounter = 0
    private let maxResults = 10
    private var saveWorkItem: DispatchWorkItem?
    
    // MARK: - Initialization
    
    init() {
        // 初始化数据库
        do {
            try sqlEngine.openDatabase()
        } catch {
            logError(.database, "Failed to initialize database", error: error)
        }
        
        // 加载持久化的 Consoles
        loadPersistedConsoles()
        
        // 如果没有 Console，创建一个默认的
        if consoleTabs.isEmpty {
            addNewConsole()
        }
    }
    
    // MARK: - Console Tab Management
    
    /// 添加新的 Console Tab
    func addNewConsole() {
        consoleCounter += 1
        let tab = SQLConsoleTab(number: consoleCounter)
        consoleTabs.append(tab)
        selectedConsoleId = tab.id
        saveAllConsoles()
    }
    
    /// 关闭 Console Tab
    func closeConsole(id: UUID) {
        // 至少保留一个 Tab
        guard consoleTabs.count > 1 else { return }
        
        consoleTabs.removeAll { $0.id == id }
        
        // 如果关闭的是当前选中的，选择最后一个
        if selectedConsoleId == id {
            selectedConsoleId = consoleTabs.last?.id
        }
        
        saveAllConsoles()
    }
    
    /// 选择 Console Tab
    func selectConsole(id: UUID) {
        selectedConsoleId = id
    }
    
    /// 更新当前 Console
    private func updateCurrentConsole(_ update: (inout SQLConsoleTab) -> Void) {
        guard let index = currentConsoleIndex else { return }
        update(&consoleTabs[index])
    }
    
    // MARK: - Table Management
    
    /// 注册表到 DuckDB，返回错误信息（nil 表示成功）
    @discardableResult
    func loadTable(name: String, dataFrame: DataFrame) -> String? {
        return sqlEngine.registerTable(name: name, dataFrame: dataFrame)
    }
    
    /// 执行 SQL 查询
    func executeQuery() {
        guard let index = currentConsoleIndex else { return }
        
        // 优先执行选中的文本，如果没有选中则执行全部
        let queryToExecute = consoleTabs[index].selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? consoleTabs[index].content 
            : consoleTabs[index].selectedText
        
        guard !queryToExecute.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            consoleTabs[index].errorMessage = "请输入 SQL 查询"
            return
        }
        
        consoleTabs[index].isExecuting = true
        consoleTabs[index].errorMessage = nil
        objectWillChange.send()
        
        let startTime = Date()
        let consoleId = consoleTabs[index].id
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let result = try self.sqlEngine.executeQuery(sql: queryToExecute)
                let executionTime = Date().timeIntervalSince(startTime)
                
                DispatchQueue.main.async {
                    // 找到对应的 Console（可能索引已变）
                    guard let idx = self.consoleTabs.firstIndex(where: { $0.id == consoleId }) else { return }
                    
                    // 创建新的结果
                    self.consoleTabs[idx].resultCounter += 1
                    let numberedResult = NumberedQueryResult(
                        number: self.consoleTabs[idx].resultCounter,
                        result: result,
                        query: queryToExecute,
                        executedAt: Date()
                    )
                    
                    self.consoleTabs[idx].results.append(numberedResult)
                    self.consoleTabs[idx].selectedResultId = numberedResult.id
                    
                    // 限制结果数量
                    if self.consoleTabs[idx].results.count > self.maxResults {
                        self.consoleTabs[idx].results.removeFirst()
                    }
                    
                    self.consoleTabs[idx].isExecuting = false
                    self.objectWillChange.send()
                    
                    // 保存到全局历史记录
                    let history = QueryHistory(
                        query: queryToExecute,
                        rowCount: result.rowCount,
                        executionTime: executionTime,
                        isSuccess: true
                    )
                    QueryHistoryManager.shared.saveHistory(history)
                }
            } catch {
                let executionTime = Date().timeIntervalSince(startTime)
                
                DispatchQueue.main.async {
                    guard let idx = self.consoleTabs.firstIndex(where: { $0.id == consoleId }) else { return }
                    
                    self.consoleTabs[idx].errorMessage = error.localizedDescription
                    self.consoleTabs[idx].isExecuting = false
                    self.objectWillChange.send()
                    
                    // 保存失败的查询到历史记录
                    let history = QueryHistory(
                        query: queryToExecute,
                        executionTime: executionTime,
                        isSuccess: false
                    )
                    QueryHistoryManager.shared.saveHistory(history)
                }
            }
        }
    }
    
    /// 关闭指定的结果 Tab
    func closeResult(id: UUID) {
        guard let index = currentConsoleIndex else { return }
        
        consoleTabs[index].results.removeAll { $0.id == id }
        
        // 如果关闭的是当前选中的，选择最后一个
        if consoleTabs[index].selectedResultId == id {
            consoleTabs[index].selectedResultId = consoleTabs[index].results.last?.id
        }
    }
    
    /// 清除查询结果
    func clearResults() {
        guard let index = currentConsoleIndex else { return }
        consoleTabs[index].results.removeAll()
        consoleTabs[index].selectedResultId = nil
        consoleTabs[index].errorMessage = nil
    }
    
    /// 清除所有数据
    func clearAll() {
        consoleTabs.removeAll()
        consoleCounter = 0
        addNewConsole()
        
        // 重启数据库
        sqlEngine.closeDatabase()
        do {
            try sqlEngine.openDatabase()
        } catch {
            if let index = currentConsoleIndex {
                consoleTabs[index].errorMessage = "数据库重置失败: \(error.localizedDescription)"
            }
        }
    }
    
    /// 移除表
    func removeTable(name: String) {
        sqlEngine.removeTable(name: name)
    }
    
    /// 获取已注册的表列表
    func getLoadedTables() -> [String] {
        return sqlEngine.getRegisteredTableNames()
    }
    
    /// 格式化 SQL 查询
    func formatSQL() {
        // 如果有选中的文本，只格式化选中的部分
        if !selectedSQLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let formatted = SQLFormatter.format(selectedSQLText)
            // 替换选中的文本
            sqlQuery = sqlQuery.replacingOccurrences(of: selectedSQLText, with: formatted)
        } else {
            // 格式化整个查询
            sqlQuery = SQLFormatter.format(sqlQuery)
        }
    }
    
    // MARK: - Query History Methods
    
    /// 获取查询历史
    func getQueryHistories() -> [QueryHistory] {
        return QueryHistoryManager.shared.loadHistories()
    }
    
    /// 从历史记录加载查询
    func loadQueryFromHistory(_ history: QueryHistory) {
        sqlQuery = history.query
    }
    
    /// 删除历史记录
    func deleteHistory(id: UUID) {
        QueryHistoryManager.shared.deleteHistory(id: id)
    }
    
    /// 清空所有历史记录
    func clearAllHistories() {
        QueryHistoryManager.shared.clearAllHistories()
    }
    
    // MARK: - Export Methods
    
    /// 导出为 CSV
    func exportToCSV() -> Data? {
        guard let result = queryResult else { return nil }
        
        // Convert QueryResult to DataFrame
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        
        // Use DataConverter to export
        let converter = DataConverter()
        return try? converter.convertToCSV(dataFrame: dataFrame)
    }
    
    /// 导出为 JSON
    func exportToJSON() -> Data? {
        guard let result = queryResult else { return nil }
        
        // Convert QueryResult to DataFrame
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        
        // Use DataConverter to export
        let converter = DataConverter()
        return try? converter.convertToJSON(dataFrame: dataFrame)
    }
    
    /// 生成 INSERT 语句
    func generateInsertStatements(tableName: String) -> String? {
        guard let result = queryResult else { return nil }
        
        // Convert QueryResult to DataFrame
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        
        // Use DataConverter to generate INSERT statements
        let converter = DataConverter()
        return converter.generateInsertStatements(dataFrame: dataFrame, tableName: tableName)
    }
    
    // MARK: - Private Methods - Persistence
    
    /// 持久化的 Console 数据
    private struct PersistedConsole: Codable {
        let number: Int
        let content: String
    }
    
    /// 保存所有 Consoles
    private func saveAllConsoles() {
        let data = consoleTabs.map { PersistedConsole(number: $0.number, content: $0.content) }
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: consolePersistenceKey)
        }
    }
    
    /// 防抖保存（延迟 0.5 秒）
    private func debounceSave() {
        saveWorkItem?.cancel()
        saveWorkItem = DispatchWorkItem { [weak self] in
            self?.saveAllConsoles()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: saveWorkItem!)
    }
    
    /// 加载持久化的 Consoles
    private func loadPersistedConsoles() {
        guard let data = UserDefaults.standard.data(forKey: consolePersistenceKey),
              let persisted = try? JSONDecoder().decode([PersistedConsole].self, from: data) else {
            return
        }
        
        for p in persisted {
            var tab = SQLConsoleTab(number: p.number)
            tab.content = p.content
            consoleTabs.append(tab)
            consoleCounter = max(consoleCounter, p.number)
        }
        
        selectedConsoleId = consoleTabs.first?.id
        logDebug(.persistence, "Loaded \(consoleTabs.count) SQL consoles")
    }
}
