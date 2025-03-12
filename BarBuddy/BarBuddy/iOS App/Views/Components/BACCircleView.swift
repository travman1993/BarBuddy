import SwiftUI

struct BACCircleView: View {
    let bac: Double
    var size: CGFloat = 100
    var showPercentage: Bool = true
    var animateOnAppear: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    private var maxBAC: Double = 0.25 // Maximum BAC for the circle (full circle)
    
    private var progress: Double {
        min(bac / maxBAC, 1.0)
    }
    
    private var color: Color {
        switch bac {
        case _ where bac >= Constants.BAC.highThreshold:
            return .dangerBAC
        case _ where bac >= Constants.BAC.legalLimit:
            return .dangerBAC
        case _ where bac >= Constants.BAC.cautionThreshold:
            return .cautionBAC
        default:
            return .safeBAC
        }
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    color.opacity(0.3),
                    lineWidth: 8
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animateOnAppear ? CGFloat(animatedProgress) : CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(animateOnAppear ? .easeOut(duration: 1.0) : .none, value: animatedProgress)
            
            // BAC display
            if showPercentage {
                VStack(spacing: 0) {
                    Text(bac.bacString)
                        .font(.system(size: size * 0.24, weight: .bold))
                        .foregroundColor(color)
                    
                    Text("%")
                        .font(.system(size: size * 0.12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animateOnAppear {
                // Start with 0 progress
                animatedProgress = 0
                
                // Animate to the actual progress
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animatedProgress = progress
                }
            } else {
                // Set to actual progress without animation
                animatedProgress = progress
            }
        }
        .onChange(of: bac) { newValue in
            // Update progress when BAC changes
            if animateOnAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedProgress = min(newValue / maxBAC, 1.0)
                }
            } else {
                animatedProgress = min(newValue / maxBAC, 1.0)
            }
        }
    }
}

struct BACLevelIndicator: View {
    let bac: Double
    var size: CGFloat = 160
    var showLabels: Bool = true
    
    var body: some View {
        ZStack {
            // Circle with BAC percentage
            BACCircleView(
                bac: bac,
                size: size,
                showPercentage: true,
                animateOnAppear: true
            )
            
            // Level indicators around the circle
            if showLabels {
                ZStack {
                    // Safe level
                    BACLevelLabel(
                        text: "Safe",
                        angle: -135,
                        radius: size * 0.65,
                        color: .safeBAC,
                        isHighlighted: bac < Constants.BAC.cautionThreshold
                    )
                    
                    // Caution level
                    BACLevelLabel(
                        text: "Caution",
                        angle: -45,
                        radius: size * 0.65,
                        color: .cautionBAC,
                        isHighlighted: bac >= Constants.BAC.cautionThreshold && bac < Constants.BAC.legalLimit
                    )
                    
                    // Warning level
                    BACLevelLabel(
                        text: "Warning",
                        angle: 45,
                        radius: size * 0.65,
                        color: .dangerBAC,
                        isHighlighted: bac >= Constants.BAC.legalLimit && bac < Constants.BAC.highThreshold
                    )
                    
                    // Danger level
                    BACLevelLabel(
                        text: "Danger",
                        angle: 135,
                        radius: size * 0.65,
                        color: .dangerBAC,
                        isHighlighted: bac >= Constants.BAC.highThreshold
                    )
                }
            }
        }
    }
}

struct BACLevelLabel: View {
    let text: String
    let angle: Double
    let radius: CGFloat
    let color: Color
    let isHighlighted: Bool
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: isHighlighted ? .bold : .regular))
            .foregroundColor(isHighlighted ? color : .secondary)
            .position(
                x: radius * cos(angle * .pi / 180),
                y: radius * sin(angle * .pi / 180)
            )
            .scaleEffect(isHighlighted ? 1.2 : 1.0)
    }
}

struct SimpleBACDisplay: View {
    let bac: Double
    var showLabel: Bool = true
    
    var body: some View {
        VStack(spacing: 4) {
            Text(bac.bacString)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(
                    bac >= Constants.BAC.legalLimit ? Color.dangerBAC :
                    bac >= Constants.BAC.cautionThreshold ? Color.cautionBAC :
                    Color.safeBAC
                )
            
            if showLabel {
                Text("Current BAC")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BACCircleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Basic BAC circle
            BACCircleView(bac: 0.072)
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Basic BAC Circle")
            
            // Full BAC level indicator
            BACLevelIndicator(bac: 0.072)
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("BAC Level Indicator")
            
            // Different BAC levels
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    BACCircleView(bac: 0.02, size: 80)
                    BACCircleView(bac: 0.06, size: 80)
                    BACCircleView(bac: 0.09, size: 80)
                    BACCircleView(bac: 0.18, size: 80)
                }
                
                // Simple text display
                HStack(spacing: 20) {
                    SimpleBACDisplay(bac: 0.02)
                    SimpleBACDisplay(bac: 0.06)
                    SimpleBACDisplay(bac: 0.09)
                    SimpleBACDisplay(bac: 0.18)
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Different BAC Levels")
            
            // Larger size example
            BACLevelIndicator(bac: 0.15, size: 200)
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Large BAC Indicator")
        }
    }
}
