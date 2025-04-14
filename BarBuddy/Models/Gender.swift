//
//  Gender.swift
//  BarBuddy
//

import Foundation

/**
 * .
 *
 *
 *
 */
public enum Gender: String, Codable, CaseIterable, Hashable {
    /// Male biological factors
    case male = "Male"
    
    /// Female biological factors
    case female = "Female"
    
    /**
     * Body water constant 
     */
    public var bodyWaterConstant: Double {
        switch self {
        case .male: return 0.68
        case .female: return 0.55
        }
    }
}
