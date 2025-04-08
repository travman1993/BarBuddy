//
//  Gender.swift
//  BarBuddy
//

import Foundation

/**
 * Represents biological sex for BAC calculation purposes.
 *
 * Gender affects how the body processes alcohol due to differences in
 * body composition, particularly water content and enzyme levels.
 */
public enum Gender: String, Codable, CaseIterable, Hashable {
    /// Male biological factors
    case male = "Male"
    
    /// Female biological factors
    case female = "Female"
    
    /**
     * Body water constant used in Widmark formula for BAC calculation.
     */
    public var bodyWaterConstant: Double {
        switch self {
        case .male: return 0.68
        case .female: return 0.55
        }
    }
}
