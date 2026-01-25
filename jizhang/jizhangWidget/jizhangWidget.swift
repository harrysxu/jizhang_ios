//
//  jizhangWidget.swift
//  jizhangWidget
//
//  Created by Cursor on 2026/1/24.
//

import WidgetKit
import SwiftUI

struct jizhangWidget: Widget {
    let kind: String = "jizhangWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayExpenseProvider()) { entry in
            jizhangWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("今日支出")
        .description("查看今日支出和快速记账")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct jizhangWidgetEntryView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}
