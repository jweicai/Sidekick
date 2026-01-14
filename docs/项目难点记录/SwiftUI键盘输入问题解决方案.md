# SwiftUI macOS 应用键盘输入问题解决方案

## 问题描述

在使用 Swift Package Manager 构建的 SwiftUI macOS 应用中，TextEditor 和其他文本输入控件无法接收键盘输入。具体表现为：

- 点击文本编辑器后光标显示正常
- 键盘输入被发送到其他应用（如 Xcode）而不是当前应用
- 应用窗口看起来正常，但无法获得键盘焦点

## 问题根因

### 1. 激活策略问题

Swift Package Manager 构建的可执行文件默认使用 `.accessory` 激活策略，这意味着：
- 应用不会出现在 Dock 中
- 应用不会自动成为活动应用
- 应用不会自动接收键盘事件

### 2. 窗口焦点问题

即使应用窗口显示了，如果没有正确设置：
- 窗口可能不是 "key window"（接收键盘事件的窗口）
- 没有正确的 first responder（第一响应者）
- 键盘事件会被发送到之前的活动应用

### 3. SwiftUI 与 AppKit 的集成问题

SwiftUI 的 TextEditor 在 macOS 上是对 NSTextView 的包装，但：
- SwiftUI 可能不会正确设置 NSTextView 的响应者链
- 复杂的视图层级可能干扰焦点传递
- 某些 SwiftUI 修饰符可能拦截事件

## 解决方案

### 核心修复：设置正确的激活策略

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
                    // 确保窗口获得焦点
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
        // 关键：设置应用激活策略为常规应用
        NSApp.setActivationPolicy(.regular)
        
        // 确保应用成为活动应用
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // 当应用变为活动状态时，确保窗口可以接收键盘输入
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

### 关键点解释

#### 1. `NSApp.setActivationPolicy(.regular)`

这是最关键的一行代码。激活策略有三种：

| 策略 | 说明 | Dock 图标 | 菜单栏 | 键盘焦点 |
|------|------|-----------|--------|----------|
| `.regular` | 常规应用 | ✅ | ✅ | ✅ |
| `.accessory` | 辅助应用 | ❌ | ❌ | ⚠️ |
| `.prohibited` | 禁止激活 | ❌ | ❌ | ❌ |

Swift Package Manager 构建的应用默认是 `.accessory`，必须手动设置为 `.regular`。

#### 2. `NSApp.activate(ignoringOtherApps: true)`

强制将应用带到前台并激活，即使其他应用当前是活动的。

#### 3. `window.makeKeyAndOrderFront(nil)`

确保窗口成为 "key window"，这是接收键盘事件的必要条件。

#### 4. `window.makeFirstResponder(window.contentView)`

设置窗口的第一响应者，确保键盘事件有正确的接收者。

### 自定义 NSTextView（可选但推荐）

如果 SwiftUI 的 TextEditor 仍有问题，可以使用自定义的 NSTextView：

```swift
struct SQLTextEditor: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        // 基本配置
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        
        // 字体和颜色
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // 禁用自动替换
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // 设置代理
        textView.delegate = context.coordinator
        textView.string = text
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SQLTextEditor
        
        init(_ parent: SQLTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
```

## 排查步骤

如果遇到类似问题，按以下步骤排查：

### 1. 检查激活策略
```swift
print("Activation policy: \(NSApp.activationPolicy().rawValue)")
// 0 = regular, 1 = accessory, 2 = prohibited
```

### 2. 检查窗口状态
```swift
if let window = NSApp.windows.first {
    print("Is key window: \(window.isKeyWindow)")
    print("Is main window: \(window.isMainWindow)")
    print("First responder: \(String(describing: window.firstResponder))")
}
```

### 3. 检查应用状态
```swift
print("Is active: \(NSApp.isActive)")
print("Is running: \(NSApp.isRunning)")
```

### 4. 创建测试视图
```swift
struct TestView: View {
    @State private var text = ""
    
    var body: some View {
        VStack {
            TextField("Test input", text: $text)
            Text("You typed: \(text)")
        }
        .padding()
    }
}
```

## 常见陷阱

### 1. 不要在 SwiftUI 视图中直接调用 NSApp

```swift
// ❌ 错误：可能在错误的时机调用
var body: some View {
    Text("Hello")
        .onAppear {
            NSApp.activate(ignoringOtherApps: true) // 可能太早
        }
}

// ✅ 正确：使用延迟或在 AppDelegate 中调用
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
```

### 2. 不要忘记 @NSApplicationDelegateAdaptor

```swift
// ❌ 错误：AppDelegate 不会被调用
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ... }
    }
}

// ✅ 正确：使用适配器
@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup { ... }
    }
}
```

### 3. 避免事件拦截

```swift
// ❌ 可能拦截点击事件
TextEditor(text: $text)
    .onTapGesture { ... }

// ✅ 使用 allowsHitTesting(false) 或避免在编辑器上添加手势
```

## 总结

SwiftUI macOS 应用的键盘输入问题主要是由于：

1. **激活策略不正确** - 必须设置为 `.regular`
2. **窗口焦点未设置** - 需要调用 `makeKeyAndOrderFront`
3. **第一响应者未设置** - 需要调用 `makeFirstResponder`

解决方案的核心是使用 `@NSApplicationDelegateAdaptor` 添加 AppDelegate，并在适当的生命周期方法中设置正确的激活策略和窗口焦点。

## 参考资料

- [Apple Documentation: NSApplication.ActivationPolicy](https://developer.apple.com/documentation/appkit/nsapplication/activationpolicy)
- [Apple Documentation: NSWindow.makeKeyAndOrderFront](https://developer.apple.com/documentation/appkit/nswindow/1419208-makekeyandorderfront)
- [SwiftUI App Lifecycle](https://developer.apple.com/documentation/swiftui/app)

---

**文档版本**: 1.0  
**最后更新**: 2025-01-13  
**适用于**: macOS 14.0+, Swift 5.9+, SwiftUI
