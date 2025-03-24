//
//  WatchApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/22/25.
//
#if os(watchOS)
import SwiftUI
import WatchConnectivity

@main
struct WatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var drinkTracker = DrinkTracker()
    @State private var isLoading = true
    
    init() {
        // Connect DrinkTracker to WatchSessionManager
        sessionManager.setDrinkTracker(drinkTracker)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(sessionManager)
                    .environmentObject(drinkTracker)
                    .opacity(isLoading ? 0 : 1)
                
                if isLoading {
                    LoadingView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Simulate initial loading and data fetch
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
