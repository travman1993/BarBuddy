import SwiftUI

struct BACTimerView: View {
    let bacEstimate: BACEstimate
    
    @State private var progress: CGFloat = 0
    @State private var timeRemaining: String = ""
    @State private var timerDescription: String = ""
    @State private var timerColor: Color = .blue
    
    // Timer for updating the countdown
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: Constants.UI.smallPadding) {
            // Header
            Text("Time Remaining")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Timer ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timerColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)
                
                // Center text
                VStack(spacing: 4) {
                    Text(timeRemaining)
                        .font(.system(size: 24, weight: .bold))
                    
                    Text(timerDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .frame(height: 180)
            .padding()
            
            // Safety message
            if bacEstimate.bac > 0 {
                Text(bacEstimate.advice)
                    .font(.caption)
                    .foregroundColor(timerColor)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(timerColor.opacity(0.1))
                    .cornerRadius(Constants.UI.cornerRadius)
            }
        }
        .padding()
        .onAppear(perform: updateTimer)
        .onReceive(timer) { _ in
            updateTimer()
        }
    }
    
    private func updateTimer() {
        if bacEstimate.bac <= 0 {
            // Already sober
            progress = 1.0
            timeRemaining = "0:00"
            timerDescription = "You are sober"
            timerColor = Color.safeBAC
            return
        }
        
        let now = Date()
        
        if bacEstimate.bac > Constants.BAC.legalLimit {
            // Above legal limit - count down to legal
            let totalSeconds = bacEstimate.legalTime.timeIntervalSince(bacEstimate.timestamp)
            let secondsRemaining = max(0, bacEstimate.legalTime.timeIntervalSince(now))
            
            progress = 1.0 - CGFloat(secondsRemaining / totalSeconds)
            timerDescription = "Until legal to drive"
            timerColor = Color.dangerBAC
            
            // Format time remaining
            let hours = Int(secondsRemaining) / 3600
            let minutes = (Int(secondsRemaining) % 3600) / 60
            
            if hours > 0 {
                timeRemaining = "\(hours):\(String(format: "%02d", minutes))"
            } else {
                timeRemaining = "0:\(String(format: "%02d", minutes))"
            }
        } else {
            // Below legal limit - count down to sober
            let totalSeconds = bacEstimate.soberTime.timeIntervalSince(bacEstimate.timestamp)
            let secondsRemaining = max(0, bacEstimate.soberTime.timeIntervalSince(now))
            
            progress = 1.0 - CGFloat(secondsRemaining / totalSeconds)
            timerDescription = "Until completely sober"
            timerColor = bacEstimate.bac >= Constants.BAC.cautionThreshold ? Color.cautionBAC : Color.safeBAC
            
            // Format time remaining
            let hours = Int(secondsRemaining) / 3600
            let minutes = (Int(secondsRemaining) % 3600) / 60
            
            if hours > 0 {
                timeRemaining = "\(hours):\(String(format: "%02d", minutes))"
            } else {
                timeRemaining = "0:\(String(format: "%02d", minutes))"
            }
        }
    }
}

struct BACTimerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Above legal limit example
            BACTimerView(bacEstimate: BACEstimate(
                bac: 0.09,
                timestamp: Date(),
                soberTime: Date().addingTimeInterval(6 * 60 * 60),
                legalTime: Date().addingTimeInterval(1 * 60 * 60),
                drinkIds: []
            ))
            
            // Below legal limit example
            BACTimerView(bacEstimate: BACEstimate(
                bac: 0.06,
                timestamp: Date(),
                soberTime: Date().addingTimeInterval(4 * 60 * 60),
                legalTime: Date(),
                drinkIds: []
            ))
            
            // Sober example
            BACTimerView(bacEstimate: BACEstimate(
                bac: 0.0,
                timestamp: Date(),
                soberTime: Date(),
                legalTime: Date(),
                drinkIds: []
            ))
        }
        .previewLayout(.sizeThatFits)
    }
}
