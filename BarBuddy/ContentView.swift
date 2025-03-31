import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout with sidebar
                if #available(iOS 16.0, *) {
                    NavigationSplitView {
                        sidebarContent
                            .navigationTitle("BarBuddy")
                    } detail: {
                        selectedTabView()
                    }
                } else {
                    // Fallback for iOS 15 and earlier
                    NavigationView {
                        HStack(spacing: 0) {
                            sidebarContent
                                .frame(width: 250)
                                .navigationTitle("BarBuddy")
                            
                            selectedTabView()
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
    }
    
    @ViewBuilder
    private var sidebarContent: some View {
        List {
            NavigationLink(destination: DashboardView().navigationTitle("Dashboard")) {
                Label("Dashboard", systemImage: "gauge")
            }
            
            NavigationLink(destination: DrinkLogView().navigationTitle("Log Drink")) {
                Label("Log Drink", systemImage: "plus.circle")
            }
            
            NavigationLink(destination: HistoryView().navigationTitle("History")) {
                Label("History", systemImage: "clock")
            }
            
            NavigationLink(destination: ShareView().navigationTitle("Share")) {
                Label("Share", systemImage: "person.2")
            }
            
            NavigationLink(destination: SettingsView().navigationTitle("Settings")) {
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
}
