//
//  SafetyStatus.swift
//  BarBuddy
//

import SwiftUI

/**
 * Represents the safety status based on the user's current level.
 */
public enum SafetyStatus: String, Codable, Hashable {
    /// Drink count is below 75% of limit
    case safe = "Under Limit"
    
    /// Drink count is between 75% and 100% of limit
    case borderline = "Approaching Limit"
    
    /// Drink count has reached or exceeded limit
    case unsafe = "Limit Reached"
    
    /**
     * Color associated with each safety status for UI representation.
     */
    public var color: Color {
        switch self {
        case .safe: return .safe
        case .borderline: return .warning
        case .unsafe: return .danger
        }
    }
    
    /**
     * System image icon associated with each safety status.
     */
    public var systemImage: String {
        switch self {
        case .safe: return "checkmark.circle"
        case .borderline: return "exclamationmark.triangle"
        case .unsafe: return "xmark.octagon"
        }
    }
}
