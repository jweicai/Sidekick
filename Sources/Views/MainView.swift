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
    @State private var selectedFormat: DataFormatType = .tables
    @State private var selectedMethod: ProcessingMethod?
    
    var body: some View {
        HStack(spacing: 0) {
            // 第一栏：数据格式图标栏
            DataFormatSidebar(selectedFormat: $selectedFormat, selectedMethod: $selectedMethod)
            
            // 第二栏：处理方式列表或特殊内容
            Group {
                switch selectedFormat {
                case .tables:
                    // 数据表直接显示表列表
                    LoadedTablesView(
                        viewModel: viewModel,
                        onTableRemoved: { tableName in
                            queryViewModel.removeTable(name: tableName)
                        },
                        onAddFile: { openFilePicker() }
                    )
                    
                case .settings:
                    // 设置直接显示设置页面
                    SettingsView()
                    
                default:
                    // 其他格式显示处理方式列表
                    ProcessingMethodListView(
                        format: selectedFormat,
                        selectedMethod: $selectedMethod
                    )
                }
            }
            .frame(width: 240)
            
            // 分隔线
            Rectangle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 1)
            
            // 第三栏：主内容区域
            Group {
                if selectedFormat == .tables {
                    // 数据表：显示 SQL 编辑器和结果集
                    QueryEditorView(viewModel: queryViewModel)
                } else if selectedFormat == .settings {
                    // 设置：显示空白（设置内容已在第二栏显示）
                    EmptyContentView(message: "在左侧配置应用设置")
                } else if let method = selectedMethod {
                    // 其他格式：显示对应的处理界面
                    ProcessingContentView(format: selectedFormat, method: method)
                } else {
                    // 未选择处理方式
                    EmptyContentView(message: "请在左侧选择一个处理方式")
                }
            }
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

// MARK: - 数据格式类型

enum DataFormatType: String, CaseIterable {
    case tables = "数据表"
    case json = "JSON"
    case ip = "IP"
    case timestamp = "时间戳"
    case text = "文本"
    case other = "其他"
    case settings = "设置"
    
    var icon: String {
        switch self {
        case .tables: return "cylinder.split.1x2"
        case .json: return "curlybraces.square"
        case .ip: return "network"
        case .timestamp: return "clock"
        case .text: return "doc.text"
        case .other: return "square.grid.2x2"
        case .settings: return "gearshape"
        }
    }
    
    // 获取该数据格式的处理方式列表
    var processingMethods: [ProcessingMethod] {
        switch self {
        case .tables:
            return [] // 数据表不需要处理方式列表，直接显示表列表
        case .json:
            return [
                ProcessingMethod(id: "flatten", name: "扁平化", icon: "arrow.down.right.and.arrow.up.left", description: "列式 JSON → 行式 JSON"),
                ProcessingMethod(id: "format", name: "格式化", icon: "text.alignleft", description: "美化 JSON 格式"),
                ProcessingMethod(id: "compress", name: "压缩", icon: "arrow.up.left.and.arrow.down.right", description: "移除空格和换行"),
                ProcessingMethod(id: "validate", name: "验证", icon: "checkmark.shield", description: "检查 JSON 格式"),
                ProcessingMethod(id: "path", name: "路径查询", icon: "arrow.triangle.branch", description: "JSONPath 查询")
            ]
        case .ip:
            return [
                ProcessingMethod(id: "convert", name: "格式转换", icon: "arrow.left.arrow.right", description: "IP ↔ 整数 ↔ 十六进制"),
                ProcessingMethod(id: "subnet", name: "子网计算", icon: "network", description: "CIDR 子网信息"),
                ProcessingMethod(id: "validate", name: "地址验证", icon: "checkmark.circle", description: "验证 IP 格式"),
                ProcessingMethod(id: "batch", name: "批量处理", icon: "list.bullet", description: "批量转换 IP 列表")
            ]
        case .timestamp:
            return [
                ProcessingMethod(id: "convert", name: "时间戳处理", icon: "clock", description: "时间戳与日期互转")
            ]
        case .text:
            return [
                ProcessingMethod(id: "base64", name: "Base64", icon: "textformat.abc", description: "编码/解码"),
                ProcessingMethod(id: "url", name: "URL 编码", icon: "link", description: "URL 编码/解码"),
                ProcessingMethod(id: "hash", name: "Hash", icon: "number", description: "MD5/SHA 计算"),
                ProcessingMethod(id: "diff", name: "文本对比", icon: "arrow.left.arrow.right", description: "对比两段文本差异")
            ]
        case .other:
            return [
                ProcessingMethod(id: "uuid", name: "UUID", icon: "key", description: "生成 UUID"),
                ProcessingMethod(id: "color", name: "颜色转换", icon: "paintpalette", description: "HEX ↔ RGB"),
                ProcessingMethod(id: "regex", name: "正则测试", icon: "text.magnifyingglass", description: "正则表达式测试")
            ]
        case .settings:
            return [] // 设置不需要处理方式列表
        }
    }
}

// MARK: - 处理方式

struct ProcessingMethod: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
}

// MARK: - 处理方式列表视图（第二栏）

struct ProcessingMethodListView: View {
    let format: DataFormatType
    @Binding var selectedMethod: ProcessingMethod?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: format.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text(format.rawValue)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 处理方式列表
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(format.processingMethods) { method in
                        ProcessingMethodRow(
                            method: method,
                            isSelected: selectedMethod?.id == method.id,
                            onSelect: { selectedMethod = method }
                        )
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
            }
            .background(DesignSystem.Colors.sidebarBackground)
        }
    }
}

// MARK: - 处理方式行

struct ProcessingMethodRow: View {
    let method: ProcessingMethod
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: method.icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(isSelected ? .medium : .regular)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(method.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textMuted)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(isSelected ? DesignSystem.Colors.accent.opacity(0.1) : 
                          (isHovering ? DesignSystem.Colors.sidebarHover : Color.clear))
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: DesignSystem.Animation.fast)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - 处理内容视图（第三栏）

struct ProcessingContentView: View {
    let format: DataFormatType
    let method: ProcessingMethod
    
    @State private var showUpgradeAlert = false
    
    var body: some View {
        let licenseManager = LicenseManager.shared
        let toolId = "\(format.rawValue.lowercased()).\(method.id)"
        
        Group {
            if licenseManager.canUseTool(toolId) {
                // 有权限，显示功能界面
                switch format {
                case .json:
                    switch method.id {
                    case "flatten":
                        JSONFlattenerView()
                    case "format":
                        JSONFormatterView()
                    case "compress":
                        JSONCompressorView()
                    case "validate":
                        JSONValidatorView()
                    case "path":
                        JSONPathQueryView()
                    default:
                        ComingSoonView(format: format, method: method)
                    }
                    
                case .timestamp:
                    switch method.id {
                    case "convert":
                        TimestampConverterView()
                    default:
                        ComingSoonView(format: format, method: method)
                    }
                    
                case .ip:
                    switch method.id {
                    case "convert":
                        IPConverterView()
                    case "subnet":
                        SubnetCalculatorView()
                    case "validate":
                        IPValidatorView()
                    case "batch":
                        IPBatchProcessorView()
                    default:
                        ComingSoonView(format: format, method: method)
                    }
                    
                case .text:
                    switch method.id {
                    case "base64":
                        Base64ToolView()
                    case "url":
                        URLEncodeToolView()
                    case "hash":
                        HashToolView()
                    case "diff":
                        TextDiffView()
                    default:
                        ComingSoonView(format: format, method: method)
                    }
                    
                default:
                    // 其他格式暂未实现
                    ComingSoonView(format: format, method: method)
                }
            } else {
                // 无权限，显示升级提示
                UpgradeRequiredView(
                    format: format,
                    method: method,
                    message: licenseManager.getUpgradeMessage(for: toolId)
                )
            }
        }
    }
}

// MARK: - 空内容视图

struct EmptyContentView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "arrow.left")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(DesignSystem.Colors.textMuted)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - 即将推出视图

struct ComingSoonView: View {
    let format: DataFormatType
    let method: ProcessingMethod
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: method.icon)
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(method.name)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                
                Text(method.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Text("即将推出")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textMuted)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.accent.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - 升级提示视图

struct UpgradeRequiredView: View {
    let format: DataFormatType
    let method: ProcessingMethod
    let message: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.warning.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.Colors.warning)
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(method.name)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                
                Text(method.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    // TODO: 打开升级页面
                    print("升级到专业版")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("升级解锁")
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [DesignSystem.Colors.warning, DesignSystem.Colors.warning.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - 数据格式图标栏（第一栏）

struct DataFormatSidebar: View {
    @Binding var selectedFormat: DataFormatType
    @Binding var selectedMethod: ProcessingMethod?
    
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
                    
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("SK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.navText)
            }
            .padding(.vertical, DesignSystem.Spacing.lg)
            
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // 数据格式图标
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach([DataFormatType.tables, .json, .ip, .timestamp, .text, .other], id: \.self) { format in
                        DataFormatIconButton(
                            format: format,
                            isSelected: selectedFormat == format,
                            action: {
                                selectedFormat = format
                                // 切换格式时清除选中的处理方式
                                selectedMethod = nil
                            }
                        )
                    }
                }
                .padding(.top, DesignSystem.Spacing.md)
            }
            
            Spacer()
            
            // 底部设置
            VStack(spacing: DesignSystem.Spacing.xs) {
                DataFormatIconButton(
                    format: .settings,
                    isSelected: selectedFormat == .settings,
                    action: {
                        selectedFormat = .settings
                        selectedMethod = nil
                    }
                )
            }
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .frame(width: 56)
        .background(DesignSystem.Colors.navBackground)
    }
}

// MARK: - 数据格式图标按钮

struct DataFormatIconButton: View {
    let format: DataFormatType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: format.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : 
                                    (isHovering ? DesignSystem.Colors.navTextActive : DesignSystem.Colors.navText))
                
                Text(format.rawValue)
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
        .help(format.rawValue)
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
    
    @State private var licenseType: LicenseType = .free
    
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
                    // 许可证信息
                    SettingsSection(title: "许可证") {
                        LicenseInfoView()
                    }
                    
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

// MARK: - 许可证信息视图

struct LicenseInfoView: View {
    @State private var licenseType: LicenseType = .free
    @State private var limits: FeatureLimits?
    @State private var showActivationSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前版本")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: licenseIcon)
                            .font(.system(size: 12))
                            .foregroundColor(licenseColor)
                        
                        Text(licenseType.rawValue)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(licenseColor)
                    }
                }
                
                Spacer()
                
                if licenseType == .free {
                    Button(action: {
                        showActivationSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("激活")
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(DesignSystem.Colors.warning)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        // 停用许可证
                        LicenseManager.shared.deactivateLicense()
                        refreshLicenseInfo()
                    }) {
                        Text("停用")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, 6)
                            .background(DesignSystem.Colors.sidebarHover)
                            .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let limits = limits {
                Divider()
                    .padding(.vertical, DesignSystem.Spacing.xs)
                
                VStack(alignment: .leading, spacing: 6) {
                    LimitRow(icon: "tablecells", title: "数据表", value: limits.maxTables == Int.max ? "无限制" : "\(limits.maxTables) 个")
                    LimitRow(icon: "list.number", title: "每表行数", value: limits.maxRowsPerTable == Int.max ? "无限制" : "\(limits.maxRowsPerTable) 行")
                    LimitRow(icon: "square.and.arrow.up", title: "导出限制", value: limits.maxExportSize == Int.max ? "无限制" : "\(limits.maxExportSize) 行")
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .onAppear {
            refreshLicenseInfo()
        }
        .sheet(isPresented: $showActivationSheet) {
            LicenseActivationView(onActivated: {
                refreshLicenseInfo()
            })
        }
    }
    
    private func refreshLicenseInfo() {
        let manager = LicenseManager.shared
        licenseType = manager.licenseType
        limits = manager.limits
    }
    
    private var licenseIcon: String {
        switch licenseType {
        case .free: return "person"
        case .pro: return "star.fill"
        case .enterprise: return "building.2.fill"
        }
    }
    
    private var licenseColor: Color {
        switch licenseType {
        case .free: return DesignSystem.Colors.textSecondary
        case .pro: return DesignSystem.Colors.warning
        case .enterprise: return DesignSystem.Colors.accent
        }
    }
}

struct LimitRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(DesignSystem.Colors.textMuted)
                .frame(width: 16)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 许可证激活视图

struct LicenseActivationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var licenseKey = ""
    @State private var isActivating = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    let onActivated: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("激活许可证")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.Spacing.lg)
            
            Divider()
            
            // 内容
            VStack(spacing: DesignSystem.Spacing.lg) {
                // 说明
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("输入您的许可证密钥")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("购买后您会收到一个许可证密钥，格式为 XXXX-XXXX-XXXX-XXXX")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                // 输入框
                TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(DesignSystem.Spacing.sm)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                
                // 错误信息
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.error)
                        
                        Text(error)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                        
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.error.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                
                // 成功信息
                if let success = successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.success)
                        
                        Text(success)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.success)
                        
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.success.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                
                // 按钮
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button(action: { dismiss() }) {
                        Text("取消")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(DesignSystem.Colors.sidebarHover)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: activateLicense) {
                        HStack(spacing: 4) {
                            if isActivating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isActivating ? "激活中..." : "激活")
                                .font(DesignSystem.Typography.bodyMedium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.accent)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                    .disabled(licenseKey.isEmpty || isActivating)
                }
                
                Divider()
                
                // 购买链接
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("还没有许可证？")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Button(action: {
                        // TODO: 打开购买页面
                        if let url = URL(string: "https://your-store.com/tablequery") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("立即购买")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .frame(width: 480, height: 400)
        .background(DesignSystem.Colors.background)
    }
    
    private func activateLicense() {
        errorMessage = nil
        successMessage = nil
        isActivating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = LicenseManager.shared.activateLicense(key: licenseKey)
            
            isActivating = false
            
            if result.success {
                successMessage = result.message
                onActivated()
                
                // 2秒后自动关闭
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } else {
                errorMessage = result.message
            }
        }
    }
}


