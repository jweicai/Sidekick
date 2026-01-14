# SwiftUI macOS 键盘输入问题排查记录

## 问题背景

在 Sidekick 项目中，SQL 查询编辑器无法接收键盘输入。这是一个典型的 SwiftUI macOS 应用键盘焦点问题，排查过程走了不少弯路，记录下来供参考。

## 问题现象

1. 应用正常启动，界面显示正常
2. 可以加载文件、点击按钮等鼠标操作
3. 点击 SQL 编辑器后光标显示正常
4. 键盘输入无反应，或者输入被发送到 Xcode 编辑器

## 排查过程

### 第一阶段：怀疑是 TextEditor 组件问题

**尝试 1：移除可能干扰的键盘快捷键**

```swift
// 移除了 MainView 中的全局键盘快捷键
// .keyboardShortcut("n", modifiers: .command)
```

❌ **结果**：无效，问题依旧

**尝试 2：添加 @FocusState 管理焦点**

```swift
@FocusState private var isTextEditorFocused: Bool

TextEditor(text: $viewModel.sqlQuery)
    .focused($isTextEditorFocused)
    .onAppear {
        isTextEditorFocused = true
    }
```

❌ **结果**：无效，焦点状态改变但键盘输入仍然不工作

**尝试 3：移除 onTapGesture**

怀疑 `onTapGesture` 拦截了点击事件：

```swift
// 移除了
.onTapGesture {
    isTextEditorFocused = true
}
```

❌ **结果**：无效

### 第二阶段：怀疑是 SwiftUI TextEditor 的 bug

**尝试 4：使用自定义 NSTextView 替代 TextEditor**

创建了 `SQLTextEditor` 组件，使用 `NSViewRepresentable` 包装 `NSTextView`：

```swift
struct SQLTextEditor: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        // ... 配置代码
        return scrollView
    }
}
```

❌ **结果**：无效，NSTextView 同样无法接收键盘输入

**尝试 5：使用 NSTextView.scrollableTextView()**

改用 Apple 推荐的方式创建可滚动文本视图：

```swift
let scrollView = NSTextView.scrollableTextView()
guard let textView = scrollView.documentView as? NSTextView else { ... }
```

❌ **结果**：无效

**尝试 6：创建自定义 NSTextView 子类**

```swift
class SQLNSTextView: NSTextView {
    override var acceptsFirstResponder: Bool { return true }
    override func becomeFirstResponder() -> Bool { ... }
    override func keyDown(with event: NSEvent) { ... }
}
```

❌ **结果**：无效

### 第三阶段：怀疑是视图层级问题

**尝试 7：简化视图层级**

移除了 SQL 编辑器周围的 ZStack、overlay 等：

```swift
// 从
ZStack(alignment: .topLeading) {
    SQLTextEditor(text: $viewModel.sqlQuery)
    if viewModel.sqlQuery.isEmpty {
        Text("placeholder...")
            .allowsHitTesting(false)
    }
}

// 改为
SQLTextEditor(text: $viewModel.sqlQuery)
```

❌ **结果**：无效

**尝试 8：移除 placeholder 覆盖层**

完全移除了 placeholder 文本，避免任何可能的事件拦截。

❌ **结果**：无效

### 第四阶段：创建测试视图验证问题范围

**尝试 9：创建最小测试视图**

```swift
struct TestTextInputView: View {
    @State private var text1 = ""
    @State private var text2 = ""
    @State private var text3 = ""
    
    var body: some View {
        VStack {
            // 测试 SwiftUI TextField
            TextField("输入...", text: $text1)
            
            // 测试 SwiftUI TextEditor
            TextEditor(text: $text2)
            
            // 测试自定义 NSTextView
            SQLTextEditor(text: $text3)
        }
    }
}
```

**关键发现**：三种输入方式都无法工作！

✅ **这说明问题不在具体的组件，而是整个应用的键盘输入都有问题。**

### 第五阶段：怀疑是应用级别的问题

**尝试 10：添加 AppDelegate**

```swift
@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
```

❌ **结果**：无效，但方向是对的

**尝试 11：设置激活策略（最终解决方案）**

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // 关键！设置应用激活策略为常规应用
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
}

func applicationDidBecomeActive(_ notification: Notification) {
    if let window = NSApp.windows.first {
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.contentView)
    }
}
```

✅ **结果**：成功！键盘输入正常工作了！

## 走过的弯路总结

| 阶段 | 方向 | 尝试次数 | 结果 |
|------|------|----------|------|
| 1 | 组件级别修复 | 3 次 | ❌ 方向错误 |
| 2 | 替换 TextEditor | 3 次 | ❌ 方向错误 |
| 3 | 视图层级优化 | 2 次 | ❌ 方向错误 |
| 4 | 创建测试视图 | 1 次 | ✅ 找到关键线索 |
| 5 | 应用级别修复 | 2 次 | ✅ 解决问题 |

**总计**：11 次尝试，前 8 次都是弯路

## 关键教训

### 1. 先确定问题范围

**错误做法**：一开始就假设是 TextEditor 组件的问题，花了大量时间在组件级别修复。

**正确做法**：应该先创建最小测试用例，确定问题是组件级别还是应用级别。

### 2. 理解 macOS 应用的激活机制

**不知道的知识点**：
- Swift Package Manager 构建的应用默认使用 `.accessory` 激活策略
- `.accessory` 策略的应用不会自动获得键盘焦点
- 必须手动设置为 `.regular` 才能正常接收键盘输入

### 3. SwiftUI 与 AppKit 的集成

**容易忽略的点**：
- SwiftUI 应用仍然运行在 AppKit 之上
- 某些底层行为需要通过 AppKit API 来控制
- `@NSApplicationDelegateAdaptor` 是连接 SwiftUI 和 AppKit 的桥梁

### 4. 调试技巧

**有用的调试代码**：

```swift
// 检查激活策略
print("Activation policy: \(NSApp.activationPolicy().rawValue)")
// 0 = regular, 1 = accessory, 2 = prohibited

// 检查窗口状态
if let window = NSApp.windows.first {
    print("Is key window: \(window.isKeyWindow)")
    print("First responder: \(window.firstResponder)")
}

// 检查应用状态
print("Is active: \(NSApp.isActive)")
```

## 问题根因

```
Swift Package Manager 构建的可执行文件
    ↓
默认激活策略为 .accessory
    ↓
应用不会自动成为活动应用
    ↓
窗口不是 key window
    ↓
键盘事件不会发送到应用
    ↓
TextEditor/NSTextView 无法接收输入
```

## 最终解决方案

```swift
import SwiftUI
import AppKit

@main
struct SidekickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.windows.first?.makeKeyAndOrderFront(nil)
                    }
                }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 🔑 关键：设置激活策略为常规应用
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
```

## 如何避免类似问题

### 1. 项目初始化时就添加 AppDelegate

即使暂时不需要，也建议在 SwiftUI macOS 项目中添加 AppDelegate：

```swift
@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
```

### 2. 设置正确的激活策略

在 `applicationDidFinishLaunching` 中设置：

```swift
NSApp.setActivationPolicy(.regular)
```

### 3. 遇到键盘问题时的排查顺序

1. **先检查激活策略** - 最常见的原因
2. **检查窗口是否是 key window**
3. **检查 first responder**
4. **创建最小测试用例确定问题范围**
5. **最后才考虑组件级别的问题**

## 相关文件

- `Sources/App/SidekickApp.swift` - 包含 AppDelegate 的实现
- `Sources/Views/SQLTextEditor.swift` - 自定义文本编辑器（可选）
- `docs/SwiftUI键盘输入问题解决方案.md` - 解决方案详细文档

---

**记录时间**: 2025-01-13  
**排查耗时**: 约 2 小时  
**教训价值**: ⭐⭐⭐⭐⭐
