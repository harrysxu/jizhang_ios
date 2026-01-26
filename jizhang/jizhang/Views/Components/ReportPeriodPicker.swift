//
//  ReportPeriodPicker.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI

// MARK: - Report Period

/// 报表周期
enum ReportPeriod: String, CaseIterable {
    case week = "按周"
    case month = "按月"
    case year = "按年"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Report Period Picker

/// 报表周期选择器 (参考UI样式: 周/月/年三段式)
struct ReportPeriodPicker: View {
    
    // MARK: - Properties
    
    @Binding var selectedPeriod: ReportPeriod
    @Binding var selectedDate: Date
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Spacing.m) {
            // 周期选择器
            Picker("周期", selection: $selectedPeriod) {
                ForEach(ReportPeriod.allCases, id: \.self) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.m)
            
            // 日期导航
            HStack {
                Button(action: moveToPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(formattedDateRange)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: moveToNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, Spacing.m)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 格式化日期范围显示
    private var formattedDateRange: String {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .week:
            // 显示周范围: 2026年第4周 (01-20 ~ 01-26)
            let weekOfYear = calendar.component(.weekOfYear, from: selectedDate)
            let year = calendar.component(.year, from: selectedDate)
            
            if let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)),
               let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd"
                return "\(year)年第\(weekOfYear)周 (\(formatter.string(from: weekStart)) ~ \(formatter.string(from: weekEnd)))"
            }
            return "\(year)年第\(weekOfYear)周"
            
        case .month:
            // 显示月份: 2026-01
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: selectedDate)
            
        case .year:
            // 显示年份: 2026年
            let year = calendar.component(.year, from: selectedDate)
            return "\(year)年"
        }
    }
    
    /// 获取当前选择的日期范围
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .week:
            // 周: 从周一到周日
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            return (weekStart, weekEnd)
            
        case .month:
            // 月: 从1号到月末
            let components = calendar.dateComponents([.year, .month], from: selectedDate)
            let monthStart = calendar.date(from: components)!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            return (monthStart, monthEnd)
            
        case .year:
            // 年: 从1月1日到12月31日
            let year = calendar.component(.year, from: selectedDate)
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            let yearStart = calendar.date(from: startComponents)!
            
            var endComponents = DateComponents()
            endComponents.year = year
            endComponents.month = 12
            endComponents.day = 31
            let yearEnd = calendar.date(from: endComponents)!
            
            return (yearStart, yearEnd)
        }
    }
    
    // MARK: - Methods
    
    /// 移动到上一个周期
    private func moveToPrevious() {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .week:
            if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                withAnimation {
                    selectedDate = newDate
                }
            }
        case .month:
            if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                withAnimation {
                    selectedDate = newDate
                }
            }
        case .year:
            if let newDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) {
                withAnimation {
                    selectedDate = newDate
                }
            }
        }
    }
    
    /// 移动到下一个周期
    private func moveToNext() {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .week:
            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                withAnimation {
                    selectedDate = newDate
                }
            }
        case .month:
            if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                withAnimation {
                    selectedDate = newDate
                }
            }
        case .year:
            if let newDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) {
                withAnimation {
                    selectedDate = newDate
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var period: ReportPeriod = .month
    @Previewable @State var date = Date()
    
    VStack {
        ReportPeriodPicker(selectedPeriod: $period, selectedDate: $date)
        
        Spacer()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("选中周期: \(period.displayName)")
            Text("日期范围:")
            let range = ReportPeriodPicker(selectedPeriod: $period, selectedDate: $date).dateRange
            Text("开始: \(range.start.formatted(date: .abbreviated, time: .omitted))")
            Text("结束: \(range.end.formatted(date: .abbreviated, time: .omitted))")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
}
