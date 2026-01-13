//
//  MainView.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import SwiftUI
import UniformTypeIdentifiers

/// 主视图 - 三栏布局
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var queryViewModel = QueryViewModel()
    @State private var selectedFeature: FeatureType = .tables
    
    var body: some View {
        HStack(spacing: 0) {
            // 第一栏：功能图标栏
            FeatureSidebar(selectedFeature: $selectedFeature)
            
            // 第二栏：根据选中的功能显示不同内容
            Group {
                switch selectedFeature {
                case .tables:
                    LoadedTablesView(
                        viewModel: viewModel,
                        onTableRemoved: { tableName in
                            queryViewModel.removeTable(name: tableName)
                        },
                        onAddFile: { openFilePicker() }
                    )
                    
                case .settings:
                    SettingsView()
                }
            }
            .frame(width: 240)
            
            // 分隔线
            Rectangle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 1)
            
            // 第三栏：SQL 编辑器和结果集
            QueryEditorView(viewModel: queryViewModel)
        }
        .frame(minWidth: 1100, minHeight: 700)
        .onAppear {
            loadAllTablesToQueryEngine()
        }
        .onChange(of: viewModel.loadedTables.count) {
            loadAllTablesToQueryEngine()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers: providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenFile"))) { _ in
            openFilePicker()
        }
    }
    
    private func loadAllTablesToQueryEngine() {
        for table in viewModel.loadedTables {
            queryViewModel.loadTable(name: table.name, dataFrame: table.dataFrame)
        }
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .init(filenameExtension: "csv")!,
            .init(filenameExtension: "json")!,
            .init(filenameExtension: "xlsx")!
        ]
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                viewModel.loadFile(url: url)
            }
        }
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                
                DispatchQueue.main.async {
                    viewModel.loadFile(url: url)
                }
            }
        }
        return true
    }
}

// MARK: - 功能类型

enum FeatureType: String, CaseIterable {
    case tables = "数据表"
    case settings = "设置"
    
    var icon: String {
        switch self {
        case .tables: return "cylinder.split.1x2"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - 功能图标栏

struct FeatureSidebar: View {
    @Binding var selectedFeature: FeatureType
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accentDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "tablecells")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("TQ")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.navText)
            }
            .padding(.vertical, DesignSystem.Spacing.lg)
            
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // 功能图标
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach([FeatureType.tables], id: \.self) { feature in
                    FeatureIconButton(
                        feature: feature,
                        isSelected: selectedFeature == feature,
                        action: { selectedFeature = feature }
                    )
                }
            }
            .padding(.top, DesignSystem.Spacing.md)
            
            Spacer()
            
            // 底部功能
            VStack(spacing: DesignSystem.Spacing.xs) {
                FeatureIconButton(
                    feature: .settings,
                    isSelected: selectedFeature == .settings,
                    action: { selectedFeature = .settings }
                )
            }
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .frame(width: 56)
        .background(DesignSystem.Colors.navBackground)
    }
}

// MARK: - 功能图标按钮

struct FeatureIconButton: View {
    let feature: FeatureType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: feature.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : 
                                    (isHovering ? DesignSystem.Colors.navTextActive : DesignSystem.Colors.navText))
                
                Text(feature.rawValue)
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : 
                                    (isHovering ? DesignSystem.Colors.navTextActive : DesignSystem.Colors.navText))
            }
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? DesignSystem.Colors.accent.opacity(0.1) : 
                          (isHovering ? DesignSystem.Colors.navHover : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .help(feature.rawValue)
    }
}

// MARK: - 加载视图

struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(DesignSystem.Colors.accent)
            
            Text("正在加载...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - 错误视图

struct ErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.error.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.Colors.error)
            }
            
            Text("出错了")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("重试")
                        .primaryButtonStyle()
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

#Preview {
    MainView()
}

// MARK: - 设置视图

struct SettingsView: View {
    @AppStorage("autoSaveQuery") private var autoSaveQuery = true
    @AppStorage("autoLoadTables") private var autoLoadTables = true
    @AppStorage("showLineNumbers") private var showLineNumbers = false
    @AppStorage("fontSize") private var fontSize = 13.0
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text("设置")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 设置列表
            ScrollView {
                VStack(spacing: 0) {
                    // 通用设置
                    SettingsSection(title: "通用") {
                        SettingsToggle(
                            title: "自动保存查询",
                            description: "自动保存 SQL 查询到本地",
                            isOn: $autoSaveQuery
                        )
                        
                        SettingsToggle(
                            title: "自动加载表",
                            description: "启动时自动加载上次的数据表",
                            isOn: $autoLoadTables
                        )
                    }
                    
                    // 编辑器设置
                    SettingsSection(title: "编辑器") {
                        SettingsToggle(
                            title: "显示行号",
                            description: "在 SQL 编辑器中显示行号",
                            isOn: $showLineNumbers
                        )
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("字体大小")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            HStack {
                                Slider(value: $fontSize, in: 10...20, step: 1)
                                
                                Text("\(Int(fontSize))")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(width: 30)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                    
                    // 关于
                    SettingsSection(title: "关于") {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            HStack {
                                Text("版本")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("1.0.0")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Divider()
                                .padding(.vertical, DesignSystem.Spacing.xs)
                            
                            HStack {
                                Text("构建")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("2025.01.13")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
        }
    }
}

// MARK: - 设置区块

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textMuted)
                .textCase(.uppercase)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.sm)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .padding(.horizontal, DesignSystem.Spacing.sm)
        }
    }
}

// MARK: - 设置开关

struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}
