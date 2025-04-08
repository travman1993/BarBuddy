//
//  SafetyStatus.swift
//  BarBuddy
//

import SwiftUI

/**
 * Represents the safety status based on the user's current BAC level.
 */
public enum SafetyStatus: String, Codable, Hashable {
    /// BAC is below 0.04%, generally considered safe for most activities
    case safe = "Safe to Drive"
    
    /// BAC is between 0.04% and 0.08%, approaching legal limits
    case borderline = "Borderline"
    
    /// BAC is above 0.08%, exceeding legal driving limits in most jurisdictions
    case unsafe = "Call a Ride"
    
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
