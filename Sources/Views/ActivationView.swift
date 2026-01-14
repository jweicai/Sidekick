//
//  ActivationView.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import SwiftUI

/// 激活视图
struct ActivationView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var licenseKey = ""
    @State private var email = ""
    @State private var isActivating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部栏
            HStack {
                Text("激活 Sidekick")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 32) {
                    // 状态信息
                    statusSection
                    
                    // 激活表单
                    activationForm
                    
                    // 购买信息
                    purchaseInfo
                }
                .padding(32)
            }
        }
        .frame(width: 600, height: 700)
        .alert("激活成功", isPresented: $showSuccess) {
            Button("开始使用") {
                dismiss()
            }
        } message: {
            Text("感谢您购买 Sidekick！")
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(licenseManager.isExpired ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: licenseManager.isExpired ? "lock.fill" : "clock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(licenseManager.isExpired ? .red : .blue)
            }
            
            // 状态文本
            if licenseManager.isInTrial {
                VStack(spacing: 8) {
                    Text("试用期剩余")
                        .font(.headline)
                    
                    Text("\(licenseManager.trialDaysRemaining) 天")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("共 90 天试用期")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if licenseManager.isExpired {
                VStack(spacing: 8) {
                    Text("试用期已结束")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("请购买激活码以继续使用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Activation Form
    
    private var activationForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("激活许可证")
                .font(.title3)
                .fontWeight(.semibold)
            
            // 邮箱输入
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱地址")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("your@email.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .disabled(isActivating)
            }
            
            // 激活码输入
            VStack(alignment: .leading, spacing: 8) {
                Text("激活码")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .disabled(isActivating)
            }
            
            // 错误信息
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 激活按钮
            Button(action: activateLicense) {
                HStack {
                    if isActivating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "key.fill")
                    }
                    Text(isActivating ? "激活中..." : "激活")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(canActivate ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(!canActivate || isActivating)
        }
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Purchase Info
    
    private var purchaseInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("购买激活码")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(icon: "cart.fill", title: "价格", value: "¥68")
                InfoRow(icon: "checkmark.circle.fill", title: "包含", value: "永久使用权")
                InfoRow(icon: "arrow.clockwise.circle.fill", title: "更新", value: "免费更新")
                InfoRow(icon: "desktopcomputer", title: "设备", value: "绑定当前设备")
            }
            
            // 机器码
            VStack(alignment: .leading, spacing: 8) {
                Text("您的机器码")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(licenseManager.getMachineID().prefix(16) + "...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("复制") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(licenseManager.getMachineID(), forType: .string)
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                Text("购买时请提供此机器码")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 购买按钮
            Button(action: openPurchaseLink) {
                HStack {
                    Image(systemName: "cart.fill")
                    Text("前往购买")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private struct InfoRow: View {
        let icon: String
        let title: String
        let value: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(value)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canActivate: Bool {
        !email.isEmpty && !licenseKey.isEmpty
    }
    
    // MARK: - Actions
    
    private func activateLicense() {
        errorMessage = nil
        isActivating = true
        
        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = licenseManager.activate(licenseKey: licenseKey, email: email)
            
            isActivating = false
            
            switch result {
            case .success:
                showSuccess = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func openPurchaseLink() {
        // TODO: 替换为实际的购买链接
        if let url = URL(string: "https://your-store.com/sidekick") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    ActivationView()
}
