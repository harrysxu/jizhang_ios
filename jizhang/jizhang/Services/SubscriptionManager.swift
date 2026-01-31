//
//  SubscriptionManager.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//
//  订阅管理服务 - 使用 StoreKit 2

import Foundation
import StoreKit

/// 订阅状态枚举
enum SubscriptionStatus: Equatable {
    case free                           // 免费用户
    case premium(expiresAt: Date?)      // 订阅用户（月/年）
    case lifetime                       // 买断用户
    
    var isPremium: Bool {
        // 测试环境默认为高级会员
        #if DEBUG
        return true
        #else
        switch self {
        case .free:
            return false
        case .premium, .lifetime:
            return true
        }
        #endif
    }
    
    var displayName: String {
        switch self {
        case .free:
            return "免费版"
        case .premium:
            return "高级版"
        case .lifetime:
            return "终身版"
        }
    }
}

/// 付费功能枚举
enum PremiumFeature: String, CaseIterable {
    case accountManagement = "账户管理"
    case categoryManagement = "分类管理"
    case budgetManagement = "预算管理"
    case exportData = "数据导出"
    case exportLedger = "导出账本"
    case importLedger = "导入账本"
    case deleteLedger = "删除账本"
    case resetLedger = "重置账本"
    case comparisonReport = "对比分析"
    case trendReport = "趋势分析"
    case accountStatistics = "账户统计"
    case cloudSync = "iCloud同步"
    
    var description: String {
        switch self {
        case .accountManagement:
            return "自定义账户，管理多个银行卡、现金等"
        case .categoryManagement:
            return "自定义收支分类，个性化记账"
        case .budgetManagement:
            return "设置预算目标，控制支出"
        case .exportData:
            return "导出CSV数据，备份或分析"
        case .exportLedger:
            return "将账本数据导出为备份文件"
        case .importLedger:
            return "从备份文件导入账本数据"
        case .deleteLedger:
            return "删除不需要的账本"
        case .resetLedger:
            return "重置账本数据"
        case .comparisonReport:
            return "月度/年度对比分析"
        case .trendReport:
            return "净资产趋势分析"
        case .accountStatistics:
            return "账户收支统计"
        case .cloudSync:
            return "多设备同步，数据云端备份"
        }
    }
    
    var iconName: String {
        switch self {
        case .accountManagement:
            return "creditcard"
        case .categoryManagement:
            return "folder"
        case .budgetManagement:
            return "chart.pie"
        case .exportData:
            return "square.and.arrow.up"
        case .exportLedger:
            return "square.and.arrow.up.on.square"
        case .importLedger:
            return "square.and.arrow.down.on.square"
        case .deleteLedger:
            return "trash"
        case .resetLedger:
            return "arrow.counterclockwise"
        case .comparisonReport:
            return "chart.bar.doc.horizontal"
        case .trendReport:
            return "chart.line.uptrend.xyaxis"
        case .accountStatistics:
            return "building.columns"
        case .cloudSync:
            return "icloud"
        }
    }
}

/// 订阅管理器
@Observable
class SubscriptionManager {
    
    // MARK: - Debug Settings
    
    /// ⚠️ 环境配置说明：
    /// - DEBUG 模式（测试环境）：默认为高级会员，所有付费功能均可使用
    /// - RELEASE 模式（正式环境）：会员系统正常生效，需要购买订阅
    /// 
    /// 如需在测试环境中测试付费限制，请将 testSubscriptionSystem 设置为 true
    #if DEBUG
    static let testSubscriptionSystem: Bool = false  // true = 测试付费限制，false = 默认高级会员
    #endif
    
    // MARK: - Properties
    
    /// 当前订阅状态
    private(set) var subscriptionStatus: SubscriptionStatus = .free
    
    /// 可用的产品列表
    private(set) var availableProducts: [Product] = []
    
    /// 是否正在加载产品
    private(set) var isLoadingProducts: Bool = false
    
    /// 是否正在购买
    private(set) var isPurchasing: Bool = false
    
    /// 错误信息
    private(set) var errorMessage: String?
    
    /// 产品ID集合
    private let productIDs: Set<String> = [
        SubscriptionProducts.monthlyID,
        SubscriptionProducts.yearlyID,
        SubscriptionProducts.lifetimeID
    ]
    
    /// 交易监听任务
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Initialization
    
    init() {
        // 启动交易监听
        transactionListener = listenForTransactions()
        
        // 加载产品和检查订阅状态
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 检查是否有权限使用某功能
    func hasAccess(to feature: PremiumFeature) -> Bool {
        // 测试环境：默认拥有所有权限（除非开启了付费测试）
        #if DEBUG
        if !Self.testSubscriptionSystem {
            return true
        }
        #endif
        
        // 正式环境或测试付费限制时：检查订阅状态
        return subscriptionStatus.isPremium
    }
    
    /// 购买产品
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 验证交易
                let transaction = try checkVerified(verification)
                
                // 更新订阅状态
                await updateSubscriptionStatus()
                
                // 完成交易
                await transaction.finish()
                
                isPurchasing = false
                return true
                
            case .userCancelled:
                isPurchasing = false
                return false
                
            case .pending:
                // 交易等待审批（如家长控制）
                isPurchasing = false
                errorMessage = "购买正在等待审批"
                return false
                
            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            isPurchasing = false
            errorMessage = "购买失败: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 恢复购买
    @MainActor
    func restorePurchases() async -> Bool {
        isPurchasing = true
        errorMessage = nil
        
        do {
            // 同步App Store的购买记录
            try await AppStore.sync()
            
            // 更新订阅状态
            await updateSubscriptionStatus()
            
            isPurchasing = false
            
            // 检查是否成功恢复
            if subscriptionStatus.isPremium {
                return true
            } else {
                errorMessage = "没有找到可恢复的购买记录"
                return false
            }
        } catch {
            isPurchasing = false
            errorMessage = "恢复失败: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 刷新订阅状态
    @MainActor
    func refreshStatus() async {
        await updateSubscriptionStatus()
    }
    
    // MARK: - Product Helpers
    
    /// 获取月订阅产品
    var monthlyProduct: Product? {
        availableProducts.first { $0.id == SubscriptionProducts.monthlyID }
    }
    
    /// 获取年订阅产品
    var yearlyProduct: Product? {
        availableProducts.first { $0.id == SubscriptionProducts.yearlyID }
    }
    
    /// 获取买断产品
    var lifetimeProduct: Product? {
        availableProducts.first { $0.id == SubscriptionProducts.lifetimeID }
    }
    
    // MARK: - Private Methods
    
    /// 加载产品
    @MainActor
    private func loadProducts() async {
        isLoadingProducts = true
        
        do {
            let products = try await Product.products(for: productIDs)
            availableProducts = products.sorted { product1, product2 in
                // 按价格排序：月 < 年 < 买断
                product1.price < product2.price
            }
        } catch {
            errorMessage = "加载产品失败: \(error.localizedDescription)"
        }
        
        isLoadingProducts = false
    }
    
    /// 更新订阅状态
    @MainActor
    private func updateSubscriptionStatus() async {
        // 检查当前的权益
        var hasLifetime = false
        var subscriptionExpiry: Date? = nil
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                switch transaction.productID {
                case SubscriptionProducts.lifetimeID:
                    // 买断
                    hasLifetime = true
                    
                case SubscriptionProducts.monthlyID, SubscriptionProducts.yearlyID:
                    // 订阅 - 检查过期时间
                    if let expirationDate = transaction.expirationDate {
                        if subscriptionExpiry == nil || expirationDate > subscriptionExpiry! {
                            subscriptionExpiry = expirationDate
                        }
                    }
                    
                default:
                    break
                }
            } catch {
                // 验证失败，跳过
                continue
            }
        }
        
        // 确定最终状态
        if hasLifetime {
            subscriptionStatus = .lifetime
        } else if let expiry = subscriptionExpiry, expiry > Date() {
            subscriptionStatus = .premium(expiresAt: expiry)
        } else {
            subscriptionStatus = .free
        }
        
        // 保存状态到 UserDefaults（用于快速启动时的状态判断）
        saveStatusToCache()
    }
    
    /// 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self = self else { continue }
                do {
                    let transaction = try await self.checkVerifiedInBackground(result)
                    
                    // 更新订阅状态
                    await self.updateSubscriptionStatus()
                    
                    // 完成交易
                    await transaction?.finish()
                } catch {
                    // 验证失败
                    continue
                }
            }
        }
    }
    
    /// 验证交易（后台线程版本）
    private func checkVerifiedInBackground(_ result: VerificationResult<StoreKit.Transaction>) async throws -> StoreKit.Transaction? {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    /// 验证交易
    private func checkVerified(_ result: VerificationResult<StoreKit.Transaction>) throws -> StoreKit.Transaction {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    /// 保存状态到缓存
    private func saveStatusToCache() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        
        switch subscriptionStatus {
        case .free:
            defaults?.set("free", forKey: "subscriptionStatus")
            defaults?.removeObject(forKey: "subscriptionExpiry")
            
        case .premium(let expiresAt):
            defaults?.set("premium", forKey: "subscriptionStatus")
            if let expiry = expiresAt {
                defaults?.set(expiry, forKey: "subscriptionExpiry")
            }
            
        case .lifetime:
            defaults?.set("lifetime", forKey: "subscriptionStatus")
            defaults?.removeObject(forKey: "subscriptionExpiry")
        }
    }
    
    /// 从缓存加载状态（快速启动用）
    func loadStatusFromCache() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let status = defaults?.string(forKey: "subscriptionStatus") ?? "free"
        
        switch status {
        case "lifetime":
            subscriptionStatus = .lifetime
        case "premium":
            let expiry = defaults?.object(forKey: "subscriptionExpiry") as? Date
            if let expiry = expiry, expiry > Date() {
                subscriptionStatus = .premium(expiresAt: expiry)
            } else {
                subscriptionStatus = .free
            }
        default:
            subscriptionStatus = .free
        }
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// 清除本地缓存的订阅状态（用于测试）
    /// 注意：这只会清除本地缓存，不会删除App Store的购买记录
    /// 要重新测试购买流程，需要在沙盒测试环境中删除测试账号的订阅
    func clearLocalSubscriptionCache() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        defaults?.removeObject(forKey: "subscriptionStatus")
        defaults?.removeObject(forKey: "subscriptionExpiry")
        subscriptionStatus = .free
        print("✅ 已清除本地订阅缓存")
    }
    
    /// 打印当前订阅状态的详细信息（用于调试）
    func printSubscriptionDetails() async {
        print("\n=== 订阅状态详情 ===")
        print("当前状态: \(subscriptionStatus)")
        
        print("\n当前权益列表:")
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                print("- 产品ID: \(transaction.productID)")
                print("  购买日期: \(transaction.purchaseDate)")
                if let expirationDate = transaction.expirationDate {
                    print("  过期日期: \(expirationDate)")
                    print("  是否已过期: \(expirationDate <= Date())")
                } else {
                    print("  过期日期: 无（买断产品）")
                }
                print("  交易ID: \(transaction.id)")
                print("")
            } catch {
                print("- 验证失败: \(error)")
            }
        }
        
        print("可用产品:")
        for product in availableProducts {
            print("- \(product.displayName): \(product.displayPrice)")
            print("  ID: \(product.id)")
        }
        
        print("===================\n")
    }
    #endif
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "交易验证失败"
        case .productNotFound:
            return "未找到产品"
        case .purchaseFailed:
            return "购买失败"
        }
    }
}
