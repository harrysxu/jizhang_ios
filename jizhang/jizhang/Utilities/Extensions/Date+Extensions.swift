//
//  Date+Extensions.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import Foundation

extension Date {
    /// 是否为今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 是否为昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 是否为本周
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// 是否为本月
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// 是否为本年
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// 格式化为显示字符串
    /// - Parameter format: 格式(默认: yyyy-MM-dd)
    /// - Returns: 格式化后的字符串
    func toString(format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    
    /// 格式化为完整的中文日期时间格式
    var toChineseDateTimeString: String {
        return toString(format: "yyyy年MM月dd日 HH:mm")
    }
    
    /// 智能显示日期(今天/昨天/具体日期)
    var smartDescription: String {
        if isToday {
            return "今天"
        } else if isYesterday {
            return "昨天"
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: self)
        } else if isThisYear {
            return toString(format: "MM月dd日")
        } else {
            return toString(format: "yyyy年MM月dd日")
        }
    }
    
    /// 格式化为时间字符串 (HH:mm)
    var timeString: String {
        return toString(format: "HH:mm")
    }
    
    /// 合并日期和时间
    /// - Parameters:
    ///   - date: 日期部分
    ///   - time: 时间部分
    /// - Returns: 合并后的日期
    static func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second
        
        return calendar.date(from: combined) ?? date
    }
    
    /// 获取月初日期
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }
    
    /// 获取月末日期
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }
    
    /// 获取当天开始时间(00:00:00)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 获取当天结束时间(23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}
