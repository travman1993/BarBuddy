//
//  ContentView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI

struct ContentView: View {
    // Important: Do not create a new DrinkTracker here since it will be provided by BarBuddyApp
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home / Dashboard View
            NavigationView {
                DashboardView()
            }
            .environmentObject(drinkTracker)
            .tabItem {
                Label("Dashboard", systemImage: "gauge")
            }
            .tag(0)
            
            // Drink Log View
            NavigationView {
                DrinkLogView()
            }
            .environmentObject(drinkTracker)
            .tabItem {
                Label("Log Drink", systemImage: "plus.circle")
            }
            .tag(1)
            
            // History View
            NavigationView {
                HistoryView()
            }
            .environmentObject(drinkTracker)
            .tabItem {
                Label("History", systemImage: "clock")
            }
            .tag(2)
            
            // Share View
            NavigationView {
                ShareView()
            }
            .environmentObject(drinkTracker)
            .tabItem {
                Label("Share", systemImage: "person.2")
            }
            .tag(3)
            
            // Settings View
            NavigationView {
                SettingsView()
            }
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

#Preview {
    ContentView()
        .environmentObject(DrinkTracker())
}
