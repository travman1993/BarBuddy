
import Foundation

extension Date {
    // Format date to string using specified format
    func formatted(using format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    // Format time as 12-hour clock (e.g., "3:45 PM")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    
    // Format date as short date (e.g., "Jun 15")
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
    
    // Format date and time (e.g., "Jun 15, 3:45 PM")
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: self)
    }
    
    // Return day of week as string
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    // Check if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    // Check if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    // Check if date is within last week
    var isWithinLastWeek: Bool {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return self >= oneWeekAgo
    }
    
    // Return "Today", "Yesterday" or date string
    var relativeString: String {
        if isToday {
            return "Today, \(timeString)"
        } else if isYesterday {
            return "Yesterday, \(timeString)"
        } else if isWithinLastWeek {
            return "\(dayOfWeek), \(timeString)"
        } else {
            return dateTimeString
        }
    }
    
    // Start of day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    // End of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}
