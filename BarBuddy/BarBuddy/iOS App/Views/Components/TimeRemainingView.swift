import SwiftUI

struct TimeRemainingView: View {
    let minutes: Int
    let description: String
    var color: Color = .blue
    var showProgressBar: Bool = true
    
    private var hours: Int {
        return minutes / 60
    }
    
    private var remainingMinutes: Int {
        return minutes % 60
    }
    
    private var formattedTime: String {
        if hours > 0 {
            return "\(hours) hr \(String(format: "%02d", remainingMinutes)) min"
        } else {
            return "\(remainingMinutes) min"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.smallPadding) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(color)
                
                Text(formattedTime)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "hourglass")
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if showProgressBar {
                ProgressBar(color: color)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

struct ProgressBar: View {
    let color: Color
    
    @State private var progress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: geometry.size.width, height: 6)
                    .cornerRadius(3)
                
                // Colored progress
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: 6)
                    .cornerRadius(3)
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.linear(duration: 2.0)) {
                progress = 0.25
            }
        }
    }
}

struct TimeRemainingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimeRemainingView(
                minutes: 145,
                description: "Until legal to drive",
                color: .red
            )
            
            TimeRemainingView(
                minutes: 30,
                description: "Until sober",
                color: .green,
                showProgressBar: false
            )
            
            TimeRemainingView(
                minutes: 0,
                description: "You are sober",
                color: .green
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
