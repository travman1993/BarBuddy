//
//  ContentView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var drinkTracker = DrinkTracker()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home / Dashboard View
            DashboardView()
                .environmentObject(drinkTracker)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }
                .tag(0)
            
            // Drink Log View
            DrinkLogView()
                .environmentObject(drinkTracker)
                .tabItem {
                    Label("Log Drink", systemImage: "plus.circle")
                }
                .tag(1)
            
            // History View
            HistoryView()
                .environmentObject(drinkTracker)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(2)
            
            // Share View
            ShareView()
                .environmentObject(drinkTracker)
                .tabItem {
                    Label("Share", systemImage: "person.2")
                }
                .tag(3)
            
            // Settings View
            SettingsView()
                .environmentObject(drinkTracker)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .onAppear {
            // Show disclaimer on first launch
            if !UserDefaults.standard.bool(forKey: "hasSeenDisclaimer") {
                // Present disclaimer alert or sheet
                UserDefaults.standard.set(true, forKey: "hasSeenDisclaimer")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
