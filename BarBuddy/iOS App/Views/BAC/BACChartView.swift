import SwiftUI

struct BACChartView: View {
    let bacEstimate: BACEstimate
    let contributingDrinks: [Drink]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.standardPadding) {
            // Header
            Text("BAC Timeline")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Chart View
            BACLineChartView(bacEstimate: bacEstimate, drinks: contributingDrinks)
                .frame(height: 220)
                .padding(.vertical)
            
            // Legend
            VStack(alignment: .leading, spacing: 8) {
                Text("Legend")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    LegendItem(color: Color.dangerBAC, label: "Above legal limit")
                    LegendItem(color: Color.cautionBAC, label: "Caution")
                    LegendItem(color: Color.safeBAC, label: "Safe range")
                }
                
                LegendItem(color: .gray, label: "Drink added", isDot: true)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            
            // Contributing drinks
            VStack(alignment: .leading, spacing: 8) {
                Text("Contributing Drinks")
                    .font(.headline)
                
                if contributingDrinks.isEmpty {
                    Text("No drinks are currently affecting your BAC")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(contributingDrinks) { drink in
                        ContributingDrinkRow(drink: drink)
                        
                        if drink.id != contributingDrinks.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .padding()
    }
}

struct BACLineChartView: View {
    let bacEstimate: BACEstimate
    let drinks: [Drink]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background grid
                VStack(spacing: 0) {
                    ForEach(0..<4) { i in
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        if i < 3 {
                            Spacer()
                        }
                    }
                }
                
                // Legal limit line
                Rectangle()
                    .fill(Color.red.opacity(0.4))
                    .frame(height: 1)
                    .offset(y: -geometry.size.height * (CGFloat(Constants.BAC.legalLimit) / 0.2))
                
                // BAC line
                Path { path in
                    // Determine time points and corresponding BAC values
                    let now = Date()
                    let hoursUntilSober = bacEstimate.minutesUntilSober / 60.0
                    let bacAtPresent = bacEstimate.bac
                    
                    // Start point (current time and BAC)
                    let startX: CGFloat = 0
                    let startY = geometry.size.height * (1.0 - CGFloat(bacAtPresent) / 0.2)
                    
                    path.move(to: CGPoint(x: startX, y: startY))
                    
                    // End point (sober time and 0 BAC)
                    let endX = geometry.size.width
                    let endY = geometry.size.height
                    
                    // Draw a line from current BAC to 0 BAC
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                bacEstimate.bac >= Constants.BAC.legalLimit ? Color.dangerBAC :
                                bacEstimate.bac >= Constants.BAC.cautionThreshold ? Color.cautionBAC :
                                Color.safeBAC,
                                Color.safeBAC
                            ]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 3
                )
                
                // Drink markers
                ForEach(drinks) { drink in
                    let timeSinceDrink = now.timeIntervalSince(drink.timestamp)
                    let totalTime = bacEstimate.soberTime.timeIntervalSince(now) + timeSinceDrink
                    let xPosition = geometry.size.width * (1 - CGFloat(timeSinceDrink) / CGFloat(totalTime))
                    
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .position(x: xPosition, y: geometry.size.height)
                }
                
                // BAC labels
                VStack(alignment: .leading, spacing: 0) {
                    Text("0.20%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("0.15%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Constants.BAC.legalLimit.bacString)")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text("0.00%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
                
                // Time labels
                HStack(spacing: 0) {
                    Text("Now")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if bacEstimate.bac > Constants.BAC.legalLimit {
                        Text("Legal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .position(
                                x: geometry.size.width * (CGFloat(bacEstimate.minutesUntilLegal) / CGFloat(bacEstimate.minutesUntilSober)),
                                y: 0
                            )
                    }
                    
                    Text("Sober")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, -20)
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    var isDot: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            if isDot {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 4)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ContributingDrinkRow: View {
    let drink: Drink
    
    var body: some View {
        HStack {
            // Drink icon
            Image(systemName: drink.type.systemIconName)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // Drink details
            VStack(alignment: .leading, spacing: 2) {
                Text(drink.displayName)
                    .font(.subheadline)
                
                Text("\(drink.standardDrinks, specifier: "%.1f") standard drinks • \(drink.timestamp.timeString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time since drink
            Text(drink.timestamp.relativeString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct BACChartView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            BACChartView(
                bacEstimate: BACEstimate.example,
                contributingDrinks: [
                    Drink.example(type: .beer),
                    Drink.example(type: .wine),
                    Drink.example(type: .liquor)
                ]
            )
        }
    }
}
