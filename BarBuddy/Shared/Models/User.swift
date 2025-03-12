import Foundation

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    case other
    
    var id: String { self.rawValue }
    
    // Body water constant based on gender (used in BAC calculation)
    var bodyWaterConstant: Double {
        switch self {
        case .male:
            return 0.68
        case .female:
            return 0.55
        case .other:
            return 0.615 // Average of male and female constants
        }
    }
    
    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .other:
            return "Other"
        }
    }
}

struct User: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String?
    var gender: Gender
    var weight: Double // in pounds
    var age: Int
    var hasAcceptedDisclaimer: Bool = false
    var emergencyContactIds: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Computed property for displaying weight
    var displayWeight: String {
        return String(format: "%.0f lbs", weight)
    }
    
    // Default user for previews and initial state
    static let example = User(
        name: "Example User",
        gender: .male,
        weight: 180,
        age: 30,
        hasAcceptedDisclaimer: true
    )
}
