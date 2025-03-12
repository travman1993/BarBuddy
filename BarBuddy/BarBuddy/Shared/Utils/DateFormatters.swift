import Foundation

struct DateFormatters {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    static let shortDayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    static func formatTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    static func formatShortDate(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }
    
    static func formatDateTime(_ date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }
    
    static func formatDayOfWeek(_ date: Date) -> String {
        return dayOfWeekFormatter.string(from: date)
    }
    
    static func formatRelative(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today, \(formatTime(date))"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday, \(formatTime(date))"
        } else if date > Calendar.current.date(byAdding: .day, value: -7, to: Date())! {
            return "\(shortDayOfWeekFormatter.string(from: date)), \(formatTime(date))"
        } else {
            return formatDateTime(date)
        }
    }
}
