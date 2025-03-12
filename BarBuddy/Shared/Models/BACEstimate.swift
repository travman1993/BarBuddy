import Foundation

enum BACLevel: String, Codable {
    case safe     // Below caution threshold
    case caution  // Between caution and legal limit
    case warning  // At or above legal limit but below high threshold
    case danger   // High BAC
}

struct BACEstimate: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var bac: Double           // Current BAC level
    var timestamp: Date       // When this estimation was made
    var soberTime: Date       // Estimated time when BAC will be 0
    var legalTime: Date       // Estimated time when BAC will be below legal limit
    var drinkIds: [String]    // IDs of drinks included in this calculation
    
    // Get BAC level category
    var level: BACLevel {
        if bac >= Constants.BAC.highThreshold {
            return .danger
        } else if bac >= Constants.BAC.legalLimit {
            return .warning
        } else if bac >= Constants.BAC.cautionThreshold {
            return .caution
        } else {
            return .safe
        }
    }
    
    // Minutes until BAC is below legal limit
    var minutesUntilLegal: Int {
        let difference = legalTime.timeIntervalSince(Date())
        return difference < 0 ? 0 : Int(difference / 60)
    }
    
    // Minutes until completely sober
    var minutesUntilSober: Int {
        let difference = soberTime.timeIntervalSince(Date())
        return difference < 0 ? 0 : Int(difference / 60)
    }
    
    // Format time remaining until legal BAC
    var timeUntilLegalFormatted: String {
        if bac < Constants.BAC.legalLimit {
            return "You are under the legal limit"
        }
        
        let hours = minutesUntilLegal / 60
        let minutes = minutesUntilLegal % 60
        
        if hours > 0 {
            return "\(hours) hr \(String(format: "%02d", minutes)) min"
        } else {
            return "\(String(format: "%02d", minutes)) min"
        }
    }
    
    // Format time remaining until completely sober
    var timeUntilSoberFormatted: String {
        if bac <= 0 {
            return "You are sober"
        }
        
        let hours = minutesUntilSober / 60
        let minutes = minutesUntilSober % 60
        
        if hours > 0 {
            return "\(hours) hr \(String(format: "%02d", minutes)) min"
        } else {
            return "\(String(format: "%02d", minutes)) min"
        }
    }
    
    // Safety advice based on BAC level
    var advice: String {
        switch level {
        case .safe:
            return "You appear to be at a low BAC level. Remember that impairment can begin with the first drink."
        case .caution:
            return "You are approaching the legal limit. It's recommended to slow down or stop drinking and consider arranging a ride if needed."
        case .warning:
            return "You are at or above the legal limit for driving. DO NOT drive. Consider calling a ride-sharing service or a friend."
        case .danger:
            return "Your BAC is at a high level. DO NOT drive under any circumstances. Stay hydrated and consider getting medical help if you feel unwell."
        }
    }
    
    // Create an empty BAC estimate (sober)
    static func empty() -> BACEstimate {
        let now = Date()
        return BACEstimate(
            bac: 0.0,
            timestamp: now,
            soberTime: now,
            legalTime: now,
            drinkIds: []
        )
    }
    
    // Example for previews
    static let example = BACEstimate(
        bac: 0.072,
        timestamp: Date(),
        soberTime: Date().addingTimeInterval(4 * 60 * 60), // 4 hours from now
        legalTime: Date().addingTimeInterval(30 * 60),     // 30 minutes from now
        drinkIds: ["drink1", "drink2"]
    )
}
