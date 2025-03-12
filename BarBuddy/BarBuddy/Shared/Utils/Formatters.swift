import Foundation

struct Formatters {
    static let bacFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        return formatter
    }()
    
    static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    static let volumeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    static func formatBAC(_ bac: Double) -> String {
        return bacFormatter.string(from: NSNumber(value: bac)) ?? "0.000"
    }
    
    static func formatWeight(_ weight: Double, isMetric: Bool) -> String {
        let unit = isMetric ? "kg" : "lbs"
        return "\(weightFormatter.string(from: NSNumber(value: weight)) ?? "0") \(unit)"
    }
    
    static func formatPercent(_ percent: Double) -> String {
        return "\(percentFormatter.string(from: NSNumber(value: percent)) ?? "0.0")%"
    }
    
    static func formatVolume(_ volume: Double, isMetric: Bool) -> String {
        let unit = isMetric ? "ml" : "oz"
        return "\(volumeFormatter.string(from: NSNumber(value: volume)) ?? "0.0") \(unit)"
    }
    
    static func formatStandardDrinks(_ standardDrinks: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        let result = formatter.string(from: NSNumber(value: standardDrinks)) ?? "0.0"
        return "\(result) \(standardDrinks == 1.0 ? "standard drink" : "standard drinks")"
    }
    
    static func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours) hr \(String(format: "%02d", mins)) min"
        } else {
            return "\(mins) min"
        }
    }
}
