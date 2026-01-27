//
//  TimeRangePicker.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

enum TimeRange: String, CaseIterable {
    case thisMonth = "本月"
    case lastMonth = "上月"
    case last3Months = "近3个月"
    case last6Months = "近半年"
    case thisYear = "今年"
    case custom = "自定义"
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)
            
        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            let end = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
            return (start, end)
            
        case .last3Months:
            let end = now
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, end)
            
        case .last6Months:
            let end = now
            let start = calendar.date(byAdding: .month, value: -6, to: now)!
            return (start, end)
            
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let end = now
            return (start, end)
            
        case .custom:
            return (now, now)
        }
    }
}

struct TimeRangePicker: View {
    @Binding var selectedRange: TimeRange
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date
    @State private var showCustomDatePicker = false
    
    var body: some View {
        VStack(spacing: Spacing.m) {
            // 快捷选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(TimeRange.allCases.filter { $0 != .custom }, id: \.self) { range in
                        Button {
                            selectedRange = range
                        } label: {
                            Text(range.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedRange == range ? .semibold : .regular)
                                .foregroundStyle(selectedRange == range ? .white : .primary)
                                .padding(.horizontal, Spacing.m)
                                .padding(.vertical, Spacing.s)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.small)
                                        .fill(selectedRange == range ? Color.primaryBlue : Color.gray.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 自定义按钮
                    Button {
                        showCustomDatePicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(TimeRange.custom.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedRange == .custom ? .semibold : .regular)
                            Image(systemName: "calendar")
                                .font(.caption)
                        }
                        .foregroundStyle(selectedRange == .custom ? .white : .primary)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(selectedRange == .custom ? Color.primaryBlue : Color.gray.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.m)
            }
            
            // 显示当前选择的日期范围
            if selectedRange == .custom {
                HStack {
                    Text(customStartDate.formatted(date: .abbreviated, time: .omitted))
                    Text("至")
                        .foregroundStyle(.secondary)
                    Text(customEndDate.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showCustomDatePicker) {
            CustomDateRangeSheet(
                startDate: $customStartDate,
                endDate: $customEndDate,
                onConfirm: {
                    selectedRange = .custom
                    showCustomDatePicker = false
                }
            )
        }
    }
}

struct CustomDateRangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SheetNavigationBar(
                title: "自定义时间范围",
                confirmText: "确定",
                confirmDisabled: endDate < startDate
            ) {
                onConfirm()
            }
            
            Form {
                Section {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.medium])
    }
}

#Preview {
    @Previewable @State var selectedRange: TimeRange = .thisMonth
    @Previewable @State var customStart = Date()
    @Previewable @State var customEnd = Date()
    
    TimeRangePicker(
        selectedRange: $selectedRange,
        customStartDate: $customStart,
        customEndDate: $customEnd
    )
}
