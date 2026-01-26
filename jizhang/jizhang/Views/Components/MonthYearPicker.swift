//
//  MonthYearPicker.swift
//  jizhang
//
//  Created by Cursor on 2026/1/26.
//

import SwiftUI

// MARK: - Month Year Picker

/// 月份年份选择器 (参考UI样式: 2026-01 格式)
struct MonthYearPicker: View {
    
    // MARK: - Properties
    
    @Binding var selectedDate: Date
    @State private var showPicker = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            // 左箭头
            Button(action: moveToPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 中间日期文字（点击可打开选择器）
            Button(action: {
                showPicker = true
            }) {
                Text(formattedDate)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 右箭头
            Button(action: moveToNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.m)
        .sheet(isPresented: $showPicker) {
            MonthYearPickerSheet(selectedDate: $selectedDate)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 格式化日期为 "2026-01" 格式
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Methods
    
    /// 移动到上一个月
    private func moveToPreviousMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            withAnimation {
                selectedDate = newDate
            }
        }
    }
    
    /// 移动到下一个月
    private func moveToNextMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            withAnimation {
                selectedDate = newDate
            }
        }
    }
}

// MARK: - Month Year Picker Sheet

/// 月份年份选择器弹窗
struct MonthYearPickerSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    @State private var tempYear: Int
    @State private var tempMonth: Int
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate.wrappedValue)
        self._tempYear = State(initialValue: components.year ?? 2026)
        self._tempMonth = State(initialValue: components.month ?? 1)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 年份选择器
                VStack(alignment: .leading, spacing: 8) {
                    Text("年份")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(yearRange, id: \.self) { year in
                                YearChip(
                                    year: year,
                                    isSelected: tempYear == year
                                ) {
                                    withAnimation {
                                        tempYear = year
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 60)
                }
                .padding(.top)
                
                Divider()
                    .padding(.vertical, Spacing.m)
                
                // 月份网格
                VStack(alignment: .leading, spacing: 8) {
                    Text("月份")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                        spacing: 12
                    ) {
                        ForEach(1...12, id: \.self) { month in
                            MonthChip(
                                month: month,
                                isSelected: tempMonth == month
                            ) {
                                tempMonth = month
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("选择月份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        applySelection()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Computed Properties
    
    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear + 1))
    }
    
    // MARK: - Methods
    
    private func applySelection() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = tempYear
        components.month = tempMonth
        components.day = 1
        
        if let newDate = calendar.date(from: components) {
            selectedDate = newDate
        }
        
        dismiss()
    }
}

// MARK: - Year Chip

private struct YearChip: View {
    let year: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(year)年")
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.primaryBlue : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Month Chip

private struct MonthChip: View {
    let month: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(month)月")
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.primaryBlue : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedDate = Date()
    
    VStack {
        MonthYearPicker(selectedDate: $selectedDate)
        
        Text("选中日期: \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
            .padding()
        
        Spacer()
    }
    .padding()
}
