//
//  WatchBarBuddyApp.swift
//  BarBuddy Watch Watch App
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI
import WatchConnectivity

// No @main attribute here
struct BarBuddyWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchAppView()
                .environmentObject(sessionManager)
        }
    }
}

// Simple ContentView that doesn't rely on complex features
struct WatchAppView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    
    var body: some View {
        VStack {
            Text("BAC: \(String(format: "%.3f", 0.0))")
                .font(.title)
            
            Button("Add Drink") {
             
            }
        }
    }
}
