//
//  AppState.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation
import SwiftUI
import SwiftData

/// 应用全局状态
@Observable
class AppState {
    // MARK: - Properties
    
    /// 当前选中的账本
    var currentLedger: Ledger? {
        didSet {
            if let ledger = currentLedger, ledger.id != oldValue?.id {
                saveCurrentLedgerID()
                updateLastAccessedAt(ledger)
                applyTheme(ledger)
            }
        }
    }
    
    /// 是否显示账本抽屉
    var showLedgerDrawer: Bool = false
    
    /// 是否首次启动
    var isFirstLaunch: Bool = true
    
    /// CloudKit服务
    var cloudKitService: CloudKitService
    
    /// 订阅管理器
    var subscriptionManager: SubscriptionManager
    
    /// ModelContainer (需要支持CloudKit)
    var modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init() {
        // App Groups标识符 (用于Widget和Live Activity数据共享)
        let appGroupIdentifier = AppConstants.appGroupIdentifier
        
        // 使用App Groups的UserDefaults
        let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        // 检查是否首次启动
        if sharedDefaults?.bool(forKey: "hasLaunched") == true {
            isFirstLaunch = false
        } else {
            isFirstLaunch = true
            sharedDefaults?.set(true, forKey: "hasLaunched")
        }
        
        // 初始化CloudKit服务
        cloudKitService = CloudKitService()
        
        // 初始化订阅管理器（注意：loadStatusFromCache 需要在所有属性初始化后调用）
        subscriptionManager = SubscriptionManager()
        
        // 配置SwiftData + CloudKit + App Groups
        let schema = Schema([
            Ledger.self,
            Account.self,
            Category.self,
            Transaction.self,
            Budget.self,
            Tag.self
        ])
        
        // 获取App Groups共享容器URL
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("无法获取App Groups容器URL，请确保已在Xcode中配置App Groups能力")
        }
        
        // 数据库文件路径
        let storeURL = containerURL.appendingPathComponent("jizhang.sqlite")
        
        // 检查是否需要清理数据库（用于开发阶段的schema变更）
        let needsCleanDatabase = sharedDefaults?.bool(forKey: "needsCleanDatabase_v2") ?? true
        
        if needsCleanDatabase {
            print("🗑️ 清理旧数据库（schema已更新）...")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            sharedDefaults?.set(false, forKey: "needsCleanDatabase_v2")
            print("✅ 旧数据库已清理")
        }
        
        // CloudKit + App Groups配置
        let modelConfiguration = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .automatic  // 自动使用Private Database
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            print("✅ 成功创建ModelContainer")
        } catch {
            // 如果创建失败（通常是因为数据库schema变更），删除旧数据库并重新创建
            print("⚠️ 创建ModelContainer失败: \(error)")
            print("🗑️ 删除旧数据库并重新创建...")
            
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                print("✅ 成功重新创建ModelContainer")
            } catch {
                fatalError("无法创建ModelContainer: \(error)")
            }
        }
        
        // 先从缓存加载订阅状态（快速启动）- 必须在所有属性初始化后调用
        subscriptionManager.loadStatusFromCache()
        
        // 数据迁移：确保至少有一个默认账本
        Task { @MainActor in
            migrateDefaultLedger()
            
            // 执行数据迁移检查
            DataMigration.migrateIfNeeded(context: modelContainer.mainContext)
        }
    }
    
    /// 迁移逻辑：确保至少有一个默认账本
    @MainActor
    private func migrateDefaultLedger() {
        let context = modelContainer.mainContext
        
        do {
            let descriptor = FetchDescriptor<Ledger>(
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            let ledgers = try context.fetch(descriptor)
            
            // 检查是否有默认账本
            let hasDefault = ledgers.contains { $0.isDefault }
            
            if !hasDefault && !ledgers.isEmpty {
                // 如果没有默认账本，将第一个账本设为默认
                ledgers[0].isDefault = true
                try context.save()
                print("🔧 数据迁移：已将第一个账本设为默认")
            }
        } catch {
            print("⚠️ 迁移默认账本失败: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// 保存当前账本ID到共享容器
    func saveCurrentLedgerID() {
        guard let ledgerId = currentLedger?.id else { return }
        let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        sharedDefaults?.set(ledgerId.uuidString, forKey: "currentLedgerId")
    }
    
    /// 应用主题
    @MainActor
    private func applyTheme(_ ledger: Ledger) {
        // 更新全局tint color
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.tintColor = UIColor(hexString: ledger.colorHex)
            }
        }
    }
    
    /// 记录访问时间
    private func updateLastAccessedAt(_ ledger: Ledger) {
        let context = modelContainer.mainContext
        // 注意: 这里需要确保Ledger有lastAccessedAt字段
        // 目前Ledger没有这个字段,我们稍后会添加
        do {
            try context.save()
        } catch {
            print("⚠️ 保存访问时间失败: \(error)")
        }
    }
    
    /// 获取默认账本
    @MainActor
    func loadDefaultLedger() -> Ledger? {
        let context = modelContainer.mainContext
        
        // 1. 优先加载标记为默认的账本（满足冷启动定位默认账本的需求）
        let defaultDescriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.isDefault == true && $0.isArchived == false }
        )
        if let ledger = try? context.fetch(defaultDescriptor).first {
            print("📖 加载默认账本: \(ledger.name)")
            return ledger
        }
        
        // 2. 如果没有默认账本，尝试加载上次使用的账本（从UserDefaults中读取）
        if let savedLedgerId = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.string(forKey: "currentLedgerId"),
           let uuid = UUID(uuidString: savedLedgerId) {
            let descriptor = FetchDescriptor<Ledger>(
                predicate: #Predicate { $0.id == uuid && $0.isArchived == false }
            )
            if let ledger = try? context.fetch(descriptor).first {
                print("📖 加载上次使用的账本: \(ledger.name)")
                return ledger
            } else {
                print("⚠️ 上次使用的账本已归档或不存在，尝试加载第一个可用账本")
            }
        }
        
        // 3. 返回第一个未归档的账本（兜底）
        let firstDescriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        if let ledger = try? context.fetch(firstDescriptor).first {
            print("📖 加载第一个可用账本: \(ledger.name)")
            return ledger
        }
        
        print("⚠️ 没有可用的账本")
        return nil
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init?(hexString: String) {
        var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
