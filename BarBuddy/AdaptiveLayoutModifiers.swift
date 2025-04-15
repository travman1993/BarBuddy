//
//  AdaptiveLayoutModifiers.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/1/25.
//
import SwiftUI

// MARK: - Adaptive Layout Utilities
struct AdaptiveGridColumns {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// Generates grid columns based on device size class
    var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible()), count: count)
    }
}

// MARK: - Responsive Container
struct ResponsiveContainer<Content: View>: View {
    let content: () -> Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if horizontalSizeClass == .regular {
                    // iPad layout
                    VStack(spacing: 20) {
                        HStack(alignment: .top, spacing: 20) {
                            // Existing content, but add centering
                            VStack(spacing: 16) {
                                // Content
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    }
                } else {
                    // iPhone layout - full width
                    content()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Adaptive Spacing Utility
struct AdaptiveSpacing {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// Provides adaptive spacing based on device size
    var value: CGFloat {
        horizontalSizeClass == .regular ? 20 : 15
    }
}

// MARK: - Responsive Typography
struct ResponsiveFont {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// Adjusts font size based on device type
    func title(size: CGFloat) -> CGFloat {
        horizontalSizeClass == .regular ? size * 1.2 : size
    }
    
    func body(size: CGFloat) -> CGFloat {
        horizontalSizeClass == .regular ? size * 1.1 : size
    }
}

// MARK: - Layout Mode Detection
enum LayoutMode {
    case phone
    case tablet
    
    var isTablet: Bool {
        self == .tablet
    }
    
    var isPhone: Bool {
        self == .phone
    }
}

// MARK: - Layout Mode Environment Key
struct LayoutModeKey: EnvironmentKey {
    static let defaultValue: LayoutMode = .phone
}



// MARK: - Adaptive Layout Modifier
struct AdaptiveLayoutModifiers: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let maxWidth: CGFloat?
    
    init(maxWidth: CGFloat? = nil) {
        self.maxWidth = maxWidth
    }
    
    func body(content: Content) -> some View {
        Group {
            if horizontalSizeClass == .regular {
                // Full-width approach for iPad
                content
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
            } else {
                // iPhone layout
                content
            }
        }
    }
}

// MARK: - Adaptive Layout Extension
extension View {
    /// Applies adaptive layout with optional max width for tablets
    func adaptiveLayout(maxWidth: CGFloat? = nil) -> some View {
        self.modifier(AdaptiveLayoutModifiers(maxWidth: maxWidth))
    }
}

// MARK: - Responsive Stack
struct ResponsiveStack<Content: View>: View {
    let content: () -> Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // Horizontal stack for tablets
            HStack {
                content()
            }
        } else {
            // Vertical stack for phones
            VStack {
                content()
            }
        }
    }
}
