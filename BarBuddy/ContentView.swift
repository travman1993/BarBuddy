import SwiftUI

struct ContentView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout with sidebar
                if #available(iOS 16.0, *) {
                    // Use NavigationSplitView for iOS 16+
                    NavigationSplitView {
                        sidebarContent
                            .navigationTitle("BarBuddy")
                    } detail: {
                        selectedTabView()
                            .environmentObject(drinkTracker)
                    }
                } else {
                    // Fallback for iOS 15 and earlier
                    NavigationView {
                        HStack(spacing: 0) {
                            sidebarContent
                                .frame(width: 250)
                                .navigationTitle("BarBuddy")
                            
                            selectedTabView()
                                .environmentObject(drinkTracker)
                        }
                    }
                }
            } else {
                // iPhone layout with tab bar
                TabView(selection: $selectedTab) {
                    NavigationView {
                        DashboardView()
                            .navigationTitle("Dashboard")
                    }
                    .tabItem {
                        Label("Dashboard", systemImage: "gauge")
                    }
                    .tag(0)
                    
                    NavigationView {
                        DrinkLogView()
                            .navigationTitle("Log Drink")
                    }
                    .tabItem {
                        Label("Log Drink", systemImage: "plus.circle")
                    }
                    .tag(1)
                    
                    NavigationView {
                        HistoryView()
                            .navigationTitle("History")
                    }
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }
                    .tag(2)
                    
                    NavigationView {
                        ShareView()
                            .navigationTitle("Share")
                    }
                    .tabItem {
                        Label("Share", systemImage: "person.2")
                    }
                    .tag(3)
                    
                    NavigationView {
                        SettingsView()
                            .navigationTitle("Settings")
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
                }
            }
        }
        .onAppear {
            // Show disclaimer on first launch
            if !UserDefaults.standard.bool(forKey: "hasSeenDisclaimer") {
                UserDefaults.standard.set(true, forKey: "hasSeenDisclaimer")
            }
        }
    }
    
    @ViewBuilder
    private var sidebarContent: some View {
        List(selection: $selectedTab) {
            NavigationLink(destination: DashboardView().navigationTitle("Dashboard"), tag: 0, selection: $selectedTab) {
                Label("Dashboard", systemImage: "gauge")
            }
            
            NavigationLink(destination: DrinkLogView().navigationTitle("Log Drink"), tag: 1, selection: $selectedTab) {
                Label("Log Drink", systemImage: "plus.circle")
            }
            
            NavigationLink(destination: HistoryView().navigationTitle("History"), tag: 2, selection: $selectedTab) {
                Label("History", systemImage: "clock")
            }
            
            NavigationLink(destination: ShareView().navigationTitle("Share"), tag: 3, selection: $selectedTab) {
                Label("Share", systemImage: "person.2")
            }
            
            NavigationLink(destination: SettingsView().navigationTitle("Settings"), tag: 4, selection: $selectedTab) {
                Label("Settings", systemImage: "gear")
            }
        }
    }
    
    @ViewBuilder
    private func selectedTabView() -> some View {
        switch selectedTab {
        case 0:
            DashboardView()
                .navigationTitle("Dashboard")
        case 1:
            DrinkLogView()
                .navigationTitle("Log Drink")
        case 2:
            HistoryView()
                .navigationTitle("History")
        case 3:
            ShareView()
                .navigationTitle("Share")
        case 4:
            SettingsView()
                .navigationTitle("Settings")
        default:
            DashboardView()
                .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DrinkTracker())
}
