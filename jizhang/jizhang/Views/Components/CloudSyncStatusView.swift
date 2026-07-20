//
//  CloudSyncStatusView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct CloudSyncStatusView: View {
    @ObservedObject var cloudKitService: CloudKitService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var showText: Bool = true
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: cloudKitService.syncStatus.icon)
                .font(.caption)
                .foregroundStyle(cloudKitService.syncStatus.color)
                .rotationEffect(.degrees(cloudKitService.syncStatus == .syncing && !reduceMotion ? 360 : 0))
                .animation(
                    cloudKitService.syncStatus == .syncing && !reduceMotion ?
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SubPageNavigationBar(title: "iCloud同步") {
                EmptyView()
            }
            
            syncStatusContent
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .onAppear {
            hideTabBar.wrappedValue = true
        }
        .onDisappear {
            hideTabBar.wrappedValue = false
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
                                .rotationEffect(.degrees(cloudKitService.syncStatus == .syncing && !reduceMotion ? 360 : 0))
                                .animation(
                                    cloudKitService.syncStatus == .syncing && !reduceMotion ?
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
                                Text("刷新状态")
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
                        
                        Text("• 数据由您的 iCloud 账户保护")
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
