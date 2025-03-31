//
//  AdaptiveLayoutModifiers.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/31/25.
//
import SwiftUI

struct AdaptiveScreenModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            // For iPad: center content with max width
            content
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

extension View {
    func adaptiveLayout() -> some View {
        self.modifier(AdaptiveScreenModifier())
    }
}

struct AdaptiveGridColumns {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible()), count: count)
    }
}
