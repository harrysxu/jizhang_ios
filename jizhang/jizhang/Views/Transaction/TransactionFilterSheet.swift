//
//  TransactionFilterSheet.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI
import SwiftData

// MARK: - Time Range Enum

enum TransactionTimeRange: String, CaseIterable {
    case thisMonth = "本月"
    case lastMonth = "上月"
    case last3Months = "近3个月"
    case last6Months = "近半年"
    case thisYear = "今年"
    case custom = "自定义"
    
    var displayName: String {
        rawValue
    }
    
    func dateRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (start, now)
            
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth))!
            let end = calendar.date(byAdding: .day, value: -1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            return (start, end)
            
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
            
        case .last6Months:
            let start = calendar.date(byAdding: .month, value: -6, to: now)!
            return (start, now)
            
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return (start, now)
            
        case .custom:
            return nil
        }
    }
}

// MARK: - Transaction Filter

struct TransactionFilter {
    var timeRange: TransactionTimeRange = .thisMonth
    var startDate: Date = Date()
    var endDate: Date = Date()
    
    func matches(_ transaction: Transaction) -> Bool {
        // 时间范围
        if timeRange == .custom {
            if transaction.date < startDate || transaction.date > endDate {
                return false
            }
        } else if let range = timeRange.dateRange() {
            if transaction.date < range.start || transaction.date > range.end {
                return false
            }
        }
        
        return true
    }
    
    var isActive: Bool {
        timeRange != .thisMonth
    }
}

// MARK: - Transaction Filter Sheet

struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filter: TransactionFilter
    
    var body: some View {
        NavigationStack {
            Form {
                // 时间范围
                Section("时间范围") {
                    Picker("时间", selection: $filter.timeRange) {
                        ForEach(TransactionTimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    
                    if filter.timeRange == .custom {
                        DatePicker("开始日期", selection: $filter.startDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                        DatePicker("结束日期", selection: $filter.endDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("重置") {
                        filter = TransactionFilter()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    TransactionFilterSheet(filter: .constant(TransactionFilter()))
}
