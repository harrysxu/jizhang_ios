//
//  HapticManager.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import UIKit

// MARK: - Haptic Manager

/// 触觉反馈管理器
enum HapticManager {
    
    // MARK: - Impact Feedback
    
    /// 轻触反馈 (用于轻量级交互)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// 中等触感 (用于常规交互)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 重触感 (用于重要操作)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// 柔和触感 (iOS 13+)
    @available(iOS 13.0, *)
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// 硬触感 (iOS 13+)
    @available(iOS 13.0, *)
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// 通用冲击反馈
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// 选择变更反馈 (用于选择器、分段控制等)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    /// 成功反馈
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 警告反馈
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// 错误反馈
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Convenience Methods
    
    /// 按钮点击反馈
    static func buttonTap() {
        light()
    }
    
    /// FAB按钮点击
    static func fabTap() {
        medium()
    }
    
    /// 分类选择反馈
    static func categorySelect() {
        light()
    }
    
    /// Tab切换反馈
    static func tabSwitch() {
        selection()
    }
    
    /// 保存成功反馈
    static func saveSuccess() {
        success()
    }
    
    /// 删除操作反馈
    static func delete() {
        if #available(iOS 13.0, *) {
            rigid()
        } else {
            heavy()
        }
    }
    
    /// 长按反馈
    static func longPress() {
        medium()
    }
    
    /// 滑动刷新反馈
    static func pullToRefresh() {
        light()
    }
}

// MARK: - Haptic Extensions

extension HapticManager {
    /// 预加载触觉引擎 (在需要快速响应的场景调用)
    static func prepare(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
    }
    
    /// 预加载选择反馈
    static func prepareSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
    }
    
    /// 预加载通知反馈
    static func prepareNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
    }
}

// MARK: - View Extension

import SwiftUI

extension View {
    /// 添加轻触反馈
    func hapticLight() -> some View {
        self.onTapGesture {
            HapticManager.light()
        }
    }
    
    /// 添加中等触觉反馈
    func hapticMedium() -> some View {
        self.onTapGesture {
            HapticManager.medium()
        }
    }
    
    /// 添加重触觉反馈
    func hapticHeavy() -> some View {
        self.onTapGesture {
            HapticManager.heavy()
        }
    }
    
    /// 添加选择反馈
    func hapticSelection() -> some View {
        self.onTapGesture {
            HapticManager.selection()
        }
    }
}

// MARK: - Usage Examples in Comments

/*
 使用示例:
 
 1. 按钮点击
 Button("保存") {
     HapticManager.buttonTap()
     // 保存操作
 }
 
 2. FAB按钮
 FABButton {
     HapticManager.fabTap()
     showAddSheet = true
 }
 
 3. 分类选择
 CategoryGridItem(category: category) {
     HapticManager.categorySelect()
     selectedCategory = category
 }
 
 4. Tab切换
 TabView(selection: $selectedTab) {
     // ...
 }
 .onChange(of: selectedTab) {
     HapticManager.tabSwitch()
 }
 
 5. 保存成功
 Task {
     try await save()
     HapticManager.saveSuccess()
 }
 
 6. 删除操作
 Button(role: .destructive) {
     HapticManager.delete()
     deleteItem()
 } label: {
     Label("删除", systemImage: "trash")
 }
 
 7. 预加载(性能优化)
 .onAppear {
     HapticManager.prepare(style: .light)
 }
 */
