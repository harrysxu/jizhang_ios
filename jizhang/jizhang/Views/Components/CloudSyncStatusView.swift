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
    
    var body: some View {
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

#Preview("Status Icon") {
    CloudSyncStatusView(cloudKitService: CloudKitService())
}

#Preview("Detail View") {
    NavigationStack {
        CloudSyncStatusDetailView(cloudKitService: CloudKitService())
            .navigationTitle("iCloud同步")
    }
}
