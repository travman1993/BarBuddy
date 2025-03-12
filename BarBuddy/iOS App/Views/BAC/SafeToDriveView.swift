import SwiftUI

struct SafeToDriveView: View {
    let bacEstimate: BACEstimate
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @State private var showingRideOptionsSheet = false
    
    var body: some View {
        VStack(spacing: Constants.UI.standardPadding) {
            // Header
            Text("Safe to Drive?")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            // Current BAC and status
            VStack(spacing: 12) {
                // Current BAC circle
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 4) {
                        Text(bacEstimate.bac.bacString)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(statusColor)
                        
                        Text("Current BAC")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Status text
                Text(statusMessage)
                    .font(.headline)
                    .foregroundColor(statusColor)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(Constants.UI.cornerRadius)
            }
            .padding()
            
            // Time details
            VStack(spacing: 8) {
                if bacEstimate.bac > 0 {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.secondary)
                        
                        Text(bacEstimate.bac >= Constants.BAC.legalLimit ?
                             "Legal to drive in \(bacEstimate.timeUntilLegalFormatted)" :
                             "Completely sober in \(bacEstimate.timeUntilSoberFormatted)")
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                }
                
                // Safety advice
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(statusColor)
                    
                    Text(bacEstimate.advice)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
            }
            
            // Actions
            if bacEstimate.bac >= Constants.BAC.cautionThreshold {
                Button {
                    showingRideOptionsSheet = true
                } label: {
                    Label("Find a Safe Ride Home", systemImage: "car.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(Constants.UI.cornerRadius)
                }
                .padding(.top)
            }
            
            // Disclaimer
            Text("Remember: The safest amount of alcohol to consume before driving is zero.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top)
        }
        .padding()
        .navigationTitle("Safe to Drive")
        .sheet(isPresented: $showingRideOptionsSheet) {
            RideOptionsView() // This will need to be implemented elsewhere
        }
    }
    
    // Status color based on BAC level
    private var statusColor: Color {
        if bacEstimate.bac >= Constants.BAC.legalLimit {
            return Color.dangerBAC
        } else if bacEstimate.bac >= Constants.BAC.cautionThreshold {
            return Color.cautionBAC
        } else {
            return Color.safeBAC
        }
    }
    
    // Status message based on BAC level
    private var statusMessage: String {
        if bacEstimate.bac >= Constants.BAC.legalLimit {
            return "DO NOT DRIVE"
        } else if bacEstimate.bac >= Constants.BAC.cautionThreshold {
            return "NOT RECOMMENDED TO DRIVE"
        } else if bacEstimate.bac > 0 {
            return "LEGAL TO DRIVE\nBut any alcohol may impair ability"
        } else {
            return "SAFE TO DRIVE"
        }
    }
}

struct SafeToDriveView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Above legal limit
            SafeToDriveView(bacEstimate: BACEstimate(
                bac: 0.09,
                timestamp: Date(),
                soberTime: Date().addingTimeInterval(6 * 60 * 60),
                legalTime: Date().addingTimeInterval(1 * 60 * 60),
                drinkIds: []
            ))
            
            // Caution level
            SafeToDriveView(bacEstimate: BACEstimate(
                bac: 0.06,
                timestamp: Date(),
                soberTime: Date().addingTimeInterval(4 * 60 * 60),
                legalTime: Date(),
                drinkIds: []
            ))
            
            // Low BAC
            SafeToDriveView(bacEstimate: BACEstimate(
                bac: 0.02,
                timestamp: Date(),
                soberTime: Date().addingTimeInterval(1.5 * 60 * 60),
                legalTime: Date(),
                drinkIds: []
            ))
            
            // Sober
            SafeToDriveView(bacEstimate: BACEstimate(
                bac: 0.0,
                timestamp: Date(),
                soberTime: Date(),
                legalTime: Date(),
                drinkIds: []
            ))
        }
        .environmentObject(SettingsViewModel())
    }
}
