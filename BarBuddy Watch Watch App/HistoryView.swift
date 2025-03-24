//
//  HistoryView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/24/25.
//

#if os(watchOS)
import SwiftUI

// Simplified History View for Watch app - just enough to resolve references
struct HistoryView: View {
    enum TimeFrame: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        Text("History not available on Watch")
            .padding()
    }
}
#endif
