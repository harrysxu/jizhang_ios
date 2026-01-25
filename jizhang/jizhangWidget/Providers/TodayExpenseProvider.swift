//
//  TodayExpenseProvider.swift
//  jizhangWidget
//
//  Created by Cursor on 2026/1/24.
//

import WidgetKit
import SwiftUI

/// Widget Timeline Entry
struct WidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

/// Today Expense Timeline Provider
struct TodayExpenseProvider: TimelineProvider {
    // MARK: - TimelineProvider Methods
    
    /// Placeholder: Widget首次加载时显示的占位符
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            data: WidgetData(
                todayExpense: 256.00,
                todayIncome: 0,
                monthExpense: 3245.50,
                monthIncome: 8900.00,
                todayBudget: 200.00,
                monthBudget: 6000.00,
                budgetUsagePercentage: 0.54,
                recentTransactions: [
                    WidgetTransaction(
                        id: UUID(),
                        amount: 45.00,
                        categoryName: "午餐",
                        categoryIcon: "fork.knife",
                        date: Date(),
                        type: "expense",
                        note: "公司食堂"
                    ),
                    WidgetTransaction(
                        id: UUID(),
                        amount: 12.50,
                        categoryName: "交通",
                        categoryIcon: "bus",
                        date: Date().addingTimeInterval(-3600),
                        type: "expense",
                        note: nil
                    ),
                    WidgetTransaction(
                        id: UUID(),
                        amount: 85.00,
                        categoryName: "购物",
                        categoryIcon: "cart",
                        date: Date().addingTimeInterval(-7200),
                        type: "expense",
                        note: "超市采购"
                    )
                ],
                lastUpdateTime: Date(),
                ledgerName: "我的账本"
            )
        )
    }
    
    /// Snapshot: Widget Gallery预览
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        if context.isPreview {
            // Gallery预览使用占位数据
            completion(placeholder(in: context))
        } else {
            // 真实快照 (尽快返回)
            Task {
                let entry = await fetchData()
                completion(entry)
            }
        }
    }
    
    /// Timeline: 定时刷新策略
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        Task {
            let entry = await fetchData()
            
            // 下次刷新时间: 30分钟后
            let nextUpdateDate = Calendar.current.date(
                byAdding: .minute,
                value: 30,
                to: Date()
            )!
            
            let timeline = Timeline(
                entries: [entry],
                policy: .after(nextUpdateDate)
            )
            
            completion(timeline)
        }
    }
    
    // MARK: - Data Fetching
    
    /// 获取Widget数据
    private func fetchData() async -> WidgetEntry {
        do {
            let widgetData = try await WidgetDataService.shared.fetchWidgetData()
            return WidgetEntry(date: Date(), data: widgetData)
        } catch {
            print("❌ Widget数据获取失败: \(error.localizedDescription)")
            // 返回空数据
            return WidgetEntry(date: Date(), data: WidgetData.empty())
        }
    }
}
