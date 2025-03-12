import Foundation

struct EmergencyContact: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var userId: String
    var name: String
    var phoneNumber: String
    var isPrimary: Bool = false
    var enableAutoCheckIn: Bool = true
    var enableEmergencyAlerts: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Format phone number for display
    var formattedPhoneNumber: String {
        // Simple US format: (xxx) xxx-xxxx
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if cleaned.count == 10 {
            return "(\(cleaned.prefix(3))) \(cleaned.dropFirst(3).prefix(3))-\(cleaned.dropFirst(6))"
        } else if cleaned.count == 11 && cleaned.first == "1" {
            let withoutCountryCode = String(cleaned.dropFirst())
            return "(\(withoutCountryCode.prefix(3))) \(withoutCountryCode.dropFirst(3).prefix(3))-\(withoutCountryCode.dropFirst(6))"
        }
        return phoneNumber // Return as is if not recognizable format
    }
    
    // Example contact for previews
    static let example = EmergencyContact(
        userId: "exampleUser",
        name: "Jane Doe",
        phoneNumber: "5551234567",
        isPrimary: true
    )
}
