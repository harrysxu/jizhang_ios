//
//  SubscriptionView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/27.
//
//  订阅页面

import SwiftUI
import StoreKit

/// 订阅页面
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    @State private var selectedProduct: Product?
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    
    private var subscriptionManager: SubscriptionManager {
        appState.subscriptionManager
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SimpleCloseNavigationBar(title: "升级高级版")
            
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    // 头部 - 当前状态
                    headerSection
                    
                    // 功能对比
                    featureComparisonSection
                    
                    // 订阅选项
                    subscriptionOptionsSection
                    
                    // 恢复购买
                    restorePurchaseSection
                    
                    // 条款说明
                    termsSection
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.xl)
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("恢复购买", isPresented: $showRestoreAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
        .alert("购买失败", isPresented: $showPurchaseError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(purchaseErrorMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.m) {
            // 图标
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 当前状态
            if subscriptionManager.subscriptionStatus.isPremium {
                VStack(spacing: Spacing.xs) {
                    Text("您已是\(subscriptionManager.subscriptionStatus.displayName)用户")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if case .premium(let expiresAt) = subscriptionManager.subscriptionStatus,
                       let expiry = expiresAt {
                        Text("有效期至: \(expiry.formatted(date: .long, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(spacing: Spacing.xs) {
                    Text("解锁全部功能")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("升级高级版，享受完整记账体验")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.l)
    }
    
    // MARK: - Feature Comparison Section
    
    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("功能对比")
                .font(.headline)
                .padding(.horizontal, Spacing.xs)
            
            VStack(spacing: 0) {
                // 表头
                HStack {
                    Text("功能")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("免费版")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 60)
                    
                    Text("高级版")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .frame(width: 60)
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .background(Color(.secondarySystemGroupedBackground))
                
                Divider()
                
                // 基础功能 - 免费版支持
                FeatureRow(name: "基础记账", freeAccess: true, premiumAccess: true)
                FeatureRow(name: "基础统计", freeAccess: true, premiumAccess: true)
                FeatureRow(name: "单个账本", freeValue: "1个", premiumValue: "无限")
                FeatureRow(name: "记录数量", freeValue: "有限", premiumValue: "无限")
                
                // 高级功能 - 仅Pro支持
                FeatureRow(name: "iCloud同步", freeAccess: false, premiumAccess: true)
                FeatureRow(name: "账本备份", freeAccess: false, premiumAccess: true)
                FeatureRow(name: "数据导出", freeAccess: false, premiumAccess: true)
                FeatureRow(name: "完整报表", freeAccess: false, premiumAccess: true)
                FeatureRow(name: "自定义账户", freeAccess: false, premiumAccess: true)
                FeatureRow(name: "自定义分类", freeAccess: false, premiumAccess: true)
                FeatureRow(name: "预算管理", freeAccess: false, premiumAccess: true, isLast: true)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }
    
    // MARK: - Subscription Options Section
    
    private var subscriptionOptionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("选择方案")
                .font(.headline)
                .padding(.horizontal, Spacing.xs)
            
            if subscriptionManager.isLoadingProducts {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, Spacing.xxl)
                    Spacer()
                }
            } else if subscriptionManager.availableProducts.isEmpty {
                // 产品加载失败时显示默认价格
                VStack(spacing: Spacing.m) {
                    SubscriptionOptionCard(
                        title: "月订阅",
                        price: "¥6",
                        period: "/月",
                        description: "按月付费，随时取消",
                        isSelected: false,
                        isBestValue: false,
                        action: {}
                    )
                    
                    SubscriptionOptionCard(
                        title: "年订阅",
                        price: "¥38",
                        period: "/年",
                        description: "相当于每月¥3.2，节省47%",
                        isSelected: false,
                        isBestValue: true,
                        action: {}
                    )
                    
                    SubscriptionOptionCard(
                        title: "买断",
                        price: "¥99",
                        period: "",
                        description: "一次付费，终身使用",
                        isSelected: false,
                        isBestValue: false,
                        action: {}
                    )
                }
                .opacity(0.6)
                
                Text("无法连接到App Store，请检查网络后重试")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.s)
            } else {
                VStack(spacing: Spacing.m) {
                    // 月订阅
                    if let monthly = subscriptionManager.monthlyProduct {
                        SubscriptionOptionCard(
                            title: "月订阅",
                            price: monthly.displayPrice,
                            period: "/月",
                            description: "按月付费，随时取消",
                            isSelected: selectedProduct?.id == monthly.id,
                            isBestValue: false
                        ) {
                            selectedProduct = monthly
                        }
                    }
                    
                    // 年订阅
                    if let yearly = subscriptionManager.yearlyProduct {
                        SubscriptionOptionCard(
                            title: "年订阅",
                            price: yearly.displayPrice,
                            period: "/年",
                            description: "相当于每月¥3.2，节省47%",
                            isSelected: selectedProduct?.id == yearly.id,
                            isBestValue: true
                        ) {
                            selectedProduct = yearly
                        }
                    }
                    
                    // 买断
                    if let lifetime = subscriptionManager.lifetimeProduct {
                        SubscriptionOptionCard(
                            title: "买断",
                            price: lifetime.displayPrice,
                            period: "",
                            description: "一次付费，终身使用",
                            isSelected: selectedProduct?.id == lifetime.id,
                            isBestValue: false
                        ) {
                            selectedProduct = lifetime
                        }
                    }
                }
                
                // 购买按钮
                Button {
                    Task {
                        await purchase()
                    }
                } label: {
                    HStack {
                        if subscriptionManager.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(selectedProduct != nil ? "立即订阅" : "请选择方案")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
                    .background(
                        Capsule()
                            .fill(selectedProduct != nil ? Color.orange : Color.gray)
                    )
                    .foregroundStyle(.white)
                }
                .disabled(selectedProduct == nil || subscriptionManager.isPurchasing)
                .padding(.top, Spacing.s)
            }
        }
    }
    
    // MARK: - Restore Purchase Section
    
    private var restorePurchaseSection: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            HStack {
                if subscriptionManager.isPurchasing {
                    ProgressView()
                        .tint(.primary)
                } else {
                    Text("恢复购买")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
        .disabled(subscriptionManager.isPurchasing)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: Spacing.s) {
            Text("订阅说明")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text("""
            • 订阅将自动续期，除非在当前订阅期结束前至少24小时关闭自动续期
            • 账户将在当前订阅期结束前24小时内收取续期费用
            • 您可以在App Store账户设置中管理订阅和关闭自动续期
            • 购买确认后，款项将从您的Apple ID账户中扣除
            """)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
        }
        .padding(.top, Spacing.m)
    }
    
    // MARK: - Actions
    
    private func purchase() async {
        guard let product = selectedProduct else { return }
        
        let success = await subscriptionManager.purchase(product)
        
        if success {
            dismiss()
        } else if let error = subscriptionManager.errorMessage {
            purchaseErrorMessage = error
            showPurchaseError = true
        }
    }
    
    private func restorePurchases() async {
        let success = await subscriptionManager.restorePurchases()
        
        if success {
            restoreMessage = "恢复成功！您已恢复为\(subscriptionManager.subscriptionStatus.displayName)用户"
        } else {
            restoreMessage = subscriptionManager.errorMessage ?? "没有找到可恢复的购买记录"
        }
        
        showRestoreAlert = true
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let name: String
    var freeAccess: Bool? = nil
    var premiumAccess: Bool? = nil
    var freeValue: String? = nil
    var premiumValue: String? = nil
    var isLast: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 免费版列
                if let value = freeValue {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(width: 60)
                } else if let access = freeAccess {
                    Image(systemName: access ? "checkmark" : "xmark")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(access ? .green : .secondary)
                        .frame(width: 60)
                }
                
                // 高级版列
                if let value = premiumValue {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .frame(width: 60)
                } else if let access = premiumAccess {
                    Image(systemName: access ? "checkmark" : "xmark")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(access ? .orange : .secondary)
                        .frame(width: 60)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            
            if !isLast {
                Divider()
                    .padding(.leading, Spacing.m)
            }
        }
    }
}

// MARK: - Subscription Option Card

private struct SubscriptionOptionCard: View {
    let title: String
    let price: String
    let period: String
    let description: String
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                // 选择指示器
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .orange : .secondary)
                
                // 信息
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if isBestValue {
                            Text("推荐")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.s)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 价格
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SubscriptionView()
        .environment(AppState())
}
