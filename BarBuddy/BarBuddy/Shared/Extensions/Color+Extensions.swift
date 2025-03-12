import SwiftUI

extension Color {
    // Create a color from hex code
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Return a hex string representation of the color
    var hexString: String {
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0
        
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    
    // Colors by BAC level
    static var safeBAC: Color {
        Color("SafeBACColor", bundle: nil)
    }
    
    static var cautionBAC: Color {
        Color("CautionBACColor", bundle: nil)
    }
    
    static var dangerBAC: Color {
        Color("DangerBACColor", bundle: nil)
    }
    
    // Get color based on BAC level
    static func forBACLevel(_ level: BACLevel) -> Color {
        switch level {
        case .safe:
            return safeBAC
        case .caution:
            return cautionBAC
        case .warning, .danger:
            return dangerBAC
        }
    }
}
