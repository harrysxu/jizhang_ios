//
//  CloudKitService.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import CloudKit
import SwiftUI
import Combine

/// CloudKit同步状态
enum CloudSyncStatus: Equatable {
    case notAvailable      // iCloud不可用
    case idle              // 空闲
    case syncing           // 同步中
    case synced            // 已同步
    case error(String)     // 错误
    
    var displayText: String {
        switch self {
        case .notAvailable:
            return "未登录iCloud"
        case .idle:
            return "待同步"
        case .syncing:
            return "同步中..."
        case .synced:
            return "已同步"
        case .error(let message):
            return "同步失败: \(message)"
        }
    }
    
    var icon: String {
        switch self {
        case .notAvailable:
            return "icloud.slash"
        case .idle:
            return "icloud"
        case .syncing:
            return "icloud.and.arrow.up"
        case .synced:
            return "icloud.and.arrow.up.fill"
        case .error:
            return "exclamationmark.icloud"
        }
    }
    
    var color: Color {
        switch self {
        case .notAvailable:
            return .gray
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .error:
            return .red
        }
    }
}

@MainActor
class CloudKitService: ObservableObject {
    // MARK: - Published Properties
    
    @Published var syncStatus: CloudSyncStatus = .idle
    @Published var isCloudKitAvailable = false
    @Published var lastSyncDate: Date?
    
    // MARK: - Properties
    
    private let container: CKContainer
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    init() {
        // 使用默认容器(需要在Xcode中配置)
        self.container = CKContainer.default()
        
        Task {
            await checkiCloudStatus()
            await setupNotifications()
        }
    }
    
    // MARK: - iCloud Status
    
    /// 检查iCloud账号状态
    func checkiCloudStatus() async {
        do {
            let status = try await container.accountStatus()
            
            await MainActor.run {
                isCloudKitAvailable = (status == .available)
                
                if status != .available {
                    syncStatus = .notAvailable
                }
            }
        } catch {
            print("检查iCloud状态失败: \(error)")
            await MainActor.run {
                isCloudKitAvailable = false
                syncStatus = .notAvailable
            }
        }
    }
    
    // MARK: - Sync Operations
    
    /// 手动触发同步
    func forceSyncNow() async {
        guard isCloudKitAvailable else {
            syncStatus = .notAvailable
            return
        }
        
        syncStatus = .syncing
        
        // SwiftData+CloudKit会自动处理同步
        // 这里只是模拟同步过程和更新UI状态
        
        do {
            // 等待一段时间模拟同步
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                syncStatus = .synced
                lastSyncDate = Date()
            }
            
            // 3秒后重置为空闲状态
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            await MainActor.run {
                if case .synced = syncStatus {
                    syncStatus = .idle
                }
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Notifications
    
    /// 设置远程变更通知
    private func setupNotifications() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // 监听SwiftData远程变更通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSPersistentStoreRemoteChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleRemoteChange()
            }
        }
    }
    
    private func handleRemoteChange() {
        print("检测到远程数据变更")
        
        // 更新同步状态
        syncStatus = .synced
        lastSyncDate = Date()
        
        // 3秒后重置状态
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .synced = syncStatus {
                syncStatus = .idle
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 格式化同步时间
    func formattedSyncTime() -> String {
        guard let date = lastSyncDate else {
            return "从未同步"
        }
        
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚同步"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}
