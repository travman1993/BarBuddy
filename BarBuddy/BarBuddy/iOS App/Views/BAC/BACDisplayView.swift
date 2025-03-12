import SwiftUI

struct BACDisplayView: View {
    let bacEstimate: BACEstimate
    
    var body: some View {
        VStack(spacing: Constants.UI.smallPadding) {
            HStack {
                Text("Current BAC")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: BACInfoView()) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: Constants.UI.standardPadding) {
                // BAC Circle
                BACCircleView(bac: bacEstimate.bac)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Time until legal
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bacEstimate.timeUntilLegalFormatted)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(bacEstimate.bac < Constants.BAC.legalLimit ?
                             "Under legal limit" :
                             "Until legal to drive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Time until sober
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bacEstimate.timeUntilSoberFormatted)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Until completely sober")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            
            // Safety advice if BAC is above 0
            if bacEstimate.bac > 0 {
                Text(bacEstimate.advice)
                    .font(.caption)
                    .foregroundColor(Color.forBACLevel(bacEstimate.level))
                    .padding(.top, 8)
            }
        }
    }
}

struct BACCircleView: View {
    let bac: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.forBACLevel(bac >= Constants.BAC.highThreshold ? .danger :
                                     bac >= Constants.BAC.legalLimit ? .warning :
                                     bac >= Constants.BAC.cautionThreshold ? .caution : .safe)
                        .opacity(0.3),
                    lineWidth: 8
                )
            
            Circle()
                .trim(from: 0, to: min(CGFloat(bac / 0.25), 1.0))
                .stroke(
                    Color.forBACLevel(bac >= Constants.BAC.highThreshold ? .danger :
                                     bac >= Constants.BAC.legalLimit ? .warning :
                                     bac >= Constants.BAC.cautionThreshold ? .caution : .safe),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: bac)
            
            VStack(spacing: 0) {
                Text(bac.bacString)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.forBACLevel(bac >= Constants.BAC.highThreshold ? .danger :
                                                      bac >= Constants.BAC.legalLimit ? .warning :
                                                      bac >= Constants.BAC.cautionThreshold ? .caution : .safe))
                
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100, height: 100)
    }
}

struct BACDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        BACDisplayView(bacEstimate: BACEstimate.example)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
