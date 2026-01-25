//
//  AppShortcuts.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import AppIntents

/// 简记账 App快捷指令注册
@available(iOS 16.0, *)
struct LuminaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "在\(.applicationName)记一笔",
                "用\(.applicationName)添加支出",
                "打开\(.applicationName)记账"
            ],
            shortTitle: "记一笔",
            systemImageName: "plus.circle.fill"
        )
        
        AppShortcut(
            intent: GetTodayExpenseIntent(),
            phrases: [
                "在\(.applicationName)查看今日支出",
                "用\(.applicationName)查看今天花了多少",
                "\(.applicationName)今日花费"
            ],
            shortTitle: "今日支出",
            systemImageName: "chart.bar.fill"
        )
        
        AppShortcut(
            intent: GetBudgetIntent(),
            phrases: [
                "在\(.applicationName)查看预算",
                "用\(.applicationName)查询预算",
                "\(.applicationName)预算情况"
            ],
            shortTitle: "查预算",
            systemImageName: "creditcard.fill"
        )
    }
    
    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
