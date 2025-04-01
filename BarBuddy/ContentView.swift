import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout with sidebar
                if #available(iOS 16.0, *) {
                    NavigationSplitView {
                        enhancedSidebarContent
                            .navigationTitle("BarBuddy")
                            .background(Color.appBackground)
                    } detail: {
                        selectedTabView()
                            .background(Color.appBackground)
                    }
                    .navigationSplitViewStyle(.balanced)
                } else {
                    // Fallback for iOS 15 and earlier
                    NavigationView {
                        HStack(spacing: 0) {
                            enhancedSidebarContent
                                .frame(width: 250)
                                .navigationTitle("BarBuddy")
                                .background(Color.appBackground)
                            
                            selectedTabView()
                                .background(Color.appBackground)
                        }
                    }
                }
            } else {
                // iPhone layout with tab bar
                TabView(selection: $selectedTab) {
                    NavigationView {
                        EnhancedDashboardView()
                            .navigationTitle("Dashboard")
                            .background(Color.appBackground)
                    }
                    .tabItem {
                        Label("Dashboard", systemImage: "gauge")
                    }
                    .tag(0)
                    
                    NavigationView {
                        EnhancedDrinkLogView()
                            .navigationTitle("Log Drink")
                            .background(Color.appBackground)
                    }
                    .tabItem {
                        Label("Log Drink", systemImage: "plus.circle")
                    }
                    .tag(1)
                    
                    NavigationView {
                        HistoryView()
                            .navigationTitle("History")
                            .background(Color.appBackground)
                    }
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }
                    .tag(2)
                    
                    NavigationView {
                        ShareView()
                            .navigationTitle("Share")
                            .background(Color.appBackground)
                    }
                    .tabItem {
                        Label("Share", systemImage: "person.2")
                    }
                    .tag(3)
                    
                    NavigationView {
                        SettingsView()
                            .navigationTitle("Settings")
                            .background(Color.appBackground)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
                }
                .accentColor(Color.accent)
            }
        }
    }
    
    @ViewBuilder
    private var enhancedSidebarContent: some View {
        List {
            NavigationLink(destination: EnhancedDashboardView().navigationTitle("Dashboard")) {
                Label("Dashboard", systemImage: "gauge")
                    .foregroundColor(.appTextPrimary)
            }
            
            NavigationLink(destination: EnhancedDrinkLogView().navigationTitle("Log Drink")) {
                Label("Log Drink", systemImage: "plus.circle")
                    .foregroundColor(.appTextPrimary)
            }
            
            NavigationLink(destination: HistoryView().navigationTitle("History")) {
                Label("History", systemImage: "clock")
                    .foregroundColor(.appTextPrimary)
            }
            
            NavigationLink(destination: ShareView().navigationTitle("Share")) {
                Label("Share", systemImage: "person.2")
                    .foregroundColor(.appTextPrimary)
            }
            
            NavigationLink(destination: SettingsView().navigationTitle("Settings")) {
                Label("Settings", systemImage: "gear")
                    .foregroundColor(.appTextPrimary)
            }
        }
        .listStyle(SidebarListStyle())
        .accentColor(Color.accent)
        .background(Color.appBackground)
    }
    
    @ViewBuilder
    private func selectedTabView() -> some View {
        switch selectedTab {
        case 0:
            EnhancedDashboardView()
                .navigationTitle("Dashboard")
        case 1:
            EnhancedDrinkLogView()
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
            EnhancedDashboardView()
                .navigationTitle("Dashboard")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DrinkTracker())
    }
}
#Preview {
    ContentView()
}


