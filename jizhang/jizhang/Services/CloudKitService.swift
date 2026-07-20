//
//  CloudKitService.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import CloudKit
import CoreData
import SwiftUI
import Combine

protocol CloudContainerProviding: AnyObject {
    func accountStatus() async throws -> CKAccountStatus
}

extension CloudKitService: SyncStatusProviding {}

@MainActor
protocol SyncStatusProviding {
    var status: CloudSyncStatus { get }
}

extension CKContainer: CloudContainerProviding {}

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
            return "本地可用，iCloud不可用"
        case .idle:
            return "自动同步"
        case .syncing:
            return "同步中..."
        case .synced:
            return "自动同步"
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

    var status: CloudSyncStatus { syncStatus }
    
    // MARK: - Properties
    
    private let container: (any CloudContainerProviding)?
    private var isMonitoring = false
    private var eventObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    convenience init() {
        self.init(
            container: CKContainer(identifier: AppConstants.iCloudContainerIdentifier),
            startMonitoring: true
        )
    }

    init(container: (any CloudContainerProviding)?, startMonitoring: Bool) {
        self.container = container
        guard startMonitoring else {
            syncStatus = .notAvailable
            return
        }

        Task {
            await checkiCloudStatus()
            setupNotifications()
        }
    }
    
    // MARK: - iCloud Status
    
    /// 检查iCloud账号状态
    func checkiCloudStatus() async {
        guard let container else {
            isCloudKitAvailable = false
            syncStatus = .notAvailable
            return
        }
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
    /// 注意：SwiftData + CloudKit 的同步是由系统自动管理的
    /// 此方法主要用于刷新iCloud状态和触发UI更新
    func forceSyncNow() async {
        guard let container, isCloudKitAvailable else {
            syncStatus = .notAvailable
            return
        }
        
        syncStatus = .syncing
        
        do {
            // 重新检查iCloud账号状态
            let status = try await container.accountStatus()
            
            guard status == .available else {
                await MainActor.run {
                    isCloudKitAvailable = false
                    syncStatus = .notAvailable
                }
                return
            }
            
            await MainActor.run {
                syncStatus = .idle
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Notifications
    
    /// 设置远程变更通知
    private func setupNotifications() {
        guard !isMonitoring else { return }
        isMonitoring = true

        eventObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                self?.handleCloudKitEvent(notification)
            }
        }
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        if let error = event.error {
            syncStatus = .error(error.localizedDescription)
        } else if event.endDate != nil {
            syncStatus = .synced
            lastSyncDate = event.endDate
        } else {
            syncStatus = .syncing
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
