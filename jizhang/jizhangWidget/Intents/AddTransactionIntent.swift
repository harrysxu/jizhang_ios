//
//  AddTransactionIntent.swift
//  jizhangWidget
//
//  Created by Cursor on 2026/1/24.
//

import AppIntents
import Foundation

/// 快速记账Intent (iOS 17+ 交互式Widget)
@available(iOS 17.0, *)
struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "快速记账"
    static var description: IntentDescription = IntentDescription("打开App并开始记账")
    
    /// 打开类型
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // 由于 openAppWhenRun = true，系统会自动打开App
        // 可以在 AppDelegate 或 SceneDelegate 中处理具体的导航
        return .result()
    }
}
