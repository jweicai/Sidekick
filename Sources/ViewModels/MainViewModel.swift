//
//  MainViewModel.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import Foundation
import Combine

/// 主视图的 ViewModel
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var fileURL: URL? {
        didSet {
            if let url = fileURL {
                loadFile(url: url)
            }
        }
    }
    
    @Published var dataFrame: DataFrame?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var fileName: String = ""
    
    // MARK: - Private Properties
    
    private let loaderManager = FileLoaderManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// 加载文件
    func loadFile(url: URL) {
        isLoading = true
        errorMessage = nil
        fileName = url.lastPathComponent
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let dataFrame = try self?.loaderManager.loadFile(from: url)
                
                DispatchQueue.main.async {
                    self?.dataFrame = dataFrame
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }
        }
    }
    
    /// 清除当前数据
    func clearData() {
        dataFrame = nil
        fileURL = nil
        fileName = ""
        errorMessage = nil
    }
}
