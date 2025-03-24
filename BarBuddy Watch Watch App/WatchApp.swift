#if os(watchOS)
import SwiftUI
import WatchConnectivity

@main
struct WatchApp: App {
    // Create shared instances that will be passed to views
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var drinkTracker = DrinkTracker()
    @StateObject private var viewModel: DrinkTrackerViewModel
    @State private var isLoading = true
    
    init() {
        // Initialize the view model with the drink tracker
        let tracker = DrinkTracker()
        _drinkTracker = StateObject(wrappedValue: tracker)
        _viewModel = StateObject(wrappedValue: DrinkTrackerViewModel(drinkTracker: tracker))
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                TabView {
                    // Main Dashboard View
                    DashboardView()
                        .environmentObject(viewModel)  // Use the view model instead of drinkTracker
                        .tabItem {
                            Label("Dashboard", systemImage: "gauge")
                        }
                    
                    // Quick Add View
                    QuickAddView()
                        .environmentObject(viewModel)  // Use the view model
                        .environmentObject(sessionManager)
                        .tabItem {
                            Label("Add Drink", systemImage: "plus")
                        }
                }
                .opacity(isLoading ? 0 : 1)
                
                // Loading View
                if isLoading {
                    LoadingView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Simulate loading time
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isLoading = false
                    }
                    
                    // Request initial data from iPhone
                    sessionManager.requestInitialData()
                }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Image(systemName: "wineglass.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("BarBuddy")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 10)
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            ProgressView()
                .padding(.top, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            isAnimating = true
        }
    }
}
#endif
