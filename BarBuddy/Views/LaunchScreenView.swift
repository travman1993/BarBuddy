import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Explicitly use Color.appBackground from Color extension
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo
                Image(systemName: "wineglass")
                    .font(.system(size: 80))
                    .foregroundColor(Color.accent)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.accent.opacity(0.1))
                            .frame(width: 150, height: 150)
                    )
                
                // App name
                Text("BarBuddy")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)
                
                // Tagline
                Text("Your Personal Drinking Companion")
                    .font(.system(size: 17))
                    .foregroundColor(Color.appTextSecondary)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
