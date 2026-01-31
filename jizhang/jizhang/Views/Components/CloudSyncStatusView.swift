//
//  CloudSyncStatusView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct CloudSyncStatusView: View {
    @ObservedObject var cloudKitService: CloudKitService
    var showText: Bool = true
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: cloudKitService.syncStatus.icon)
                .font(.caption)
                .foregroundStyle(cloudKitService.syncStatus.color)
                .rotationEffect(.degrees(cloudKitService.syncStatus == .syncing ? 360 : 0))
                .animation(
                    cloudKitService.syncStatus == .syncing ?
                        .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                    value: cloudKitService.syncStatus == .syncing
                )
            
            if showText {
                Text(cloudKitService.syncStatus.displayText)
                    .font(.caption)
                    .foregroundStyle(cloudKitService.syncStatus.color)
            }
        }
    }
}

struct CloudSyncStatusDetailView: View {
    @ObservedObject var cloudKitService: CloudKitService
    @Environment(\.hideTabBar) private var hideTabBar
    @Environment(AppState.self) private var appState
    @State private var showSubscriptionSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SubPageNavigationBar(title: "iCloud同步") {
                EmptyView()
            }
            
            if !appState.subscriptionManager.hasAccess(to: .cloudSync) {
                // 免费用户显示升级提示
                premiumFeatureView
            } else {
                // 高级用户显示完整功能
                syncStatusContent
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionView()
        }
        .onAppear {
            hideTabBar.wrappedValue = true
        }
        .onDisappear {
            hideTabBar.wrappedValue = false
        }
    }
    
    // MARK: - Premium Feature View
    
    private var premiumFeatureView: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer()
                    .frame(height: 60)
                
                // 图标
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "icloud")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                }
                
                // 标题和描述
                VStack(spacing: Spacing.m) {
                    Text("iCloud同步")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("升级到高级版，享受多设备同步功能")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 功能列表
                VStack(alignment: .leading, spacing: Spacing.m) {
                    FeatureBulletPoint(icon: "checkmark.icloud", text: "数据自动同步到所有设备")
                    FeatureBulletPoint(icon: "lock.shield", text: "云端加密存储，安全可靠")
                    FeatureBulletPoint(icon: "arrow.triangle.2.circlepath", text: "实时同步，数据不丢失")
                    FeatureBulletPoint(icon: "iphone.and.ipad", text: "支持iPhone、iPad多设备")
                }
                .padding(Spacing.l)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color(.systemBackground))
                )
                
                // 升级按钮
                Button {
                    showSubscriptionSheet = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("升级到高级版")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(CornerRadius.medium)
                }
                
                Spacer()
            }
            .padding(Spacing.l)
        }
    }
    
    // MARK: - Sync Status Content
    
    private var syncStatusContent: some View {
        ScrollView {
                VStack(spacing: Spacing.m) {
                    // 状态卡片
                    VStack(spacing: Spacing.m) {
                        // 图标
                        ZStack {
                            Circle()
                                .fill(cloudKitService.syncStatus.color.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: cloudKitService.syncStatus.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(cloudKitService.syncStatus.color)
                                .rotationEffect(.degrees(cloudKitService.syncStatus == .syncing ? 360 : 0))
                                .animation(
                                    cloudKitService.syncStatus == .syncing ?
                                        .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                    value: cloudKitService.syncStatus == .syncing
                                )
                        }
                        
                        // 状态文本
                        Text(cloudKitService.syncStatus.displayText)
                            .font(.headline)
                            .foregroundStyle(cloudKitService.syncStatus.color)
                        
                        // 最后同步时间
                        if cloudKitService.lastSyncDate != nil {
                            Text("最后同步: \(cloudKitService.formattedSyncTime())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(Spacing.l)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(Color(.systemBackground))
                    )
                    
                    // 手动同步按钮
                    if cloudKitService.isCloudKitAvailable {
                        Button {
                            Task {
                                await cloudKitService.forceSyncNow()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("立即同步")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.m)
                            .background(Color.primaryBlue)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .disabled(cloudKitService.syncStatus == .syncing)
                    }
                    
                    // 说明文本
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("关于iCloud同步")
                            .font(.headline)
                        
                        Text("• 数据自动同步到您的所有设备")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("• 需要登录iCloud账号")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("• 同步过程完全加密,保护您的隐私")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !cloudKitService.isCloudKitAvailable {
                            Text("• 请前往 设置 → Apple ID → iCloud 登录")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(Color(.secondarySystemBackground))
                    )
                    
                    Spacer()
                }
                .padding(Spacing.m)
        }
    }
}

// MARK: - Feature Bullet Point

private struct FeatureBulletPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
                .frame(width: 28)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

#Preview("Status Icon") {
    CloudSyncStatusView(cloudKitService: CloudKitService())
}

#Preview("Detail View") {
    NavigationStack {
        CloudSyncStatusDetailView(cloudKitService: CloudKitService())
            .navigationTitle("iCloud同步")
            .environment(AppState())
    }
}
