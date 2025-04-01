import SwiftUI


struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                if #available(iOS 16.0, *) {
                    NavigationSplitView {
                        sidebarContent
                            .navigationTitle("BarBuddy")
                    } detail: {
                        selectedTabView()
                    }
                    .navigationSplitViewStyle(.balanced)
                } else {
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
                TabView(selection: $selectedTab) {
                    NavigationView { DashboardView() }
                        .tabItem { Label("Dashboard", systemImage: "gauge") }
                        .tag(0)

                    NavigationView { DrinkLogView() }
                        .tabItem { Label("Log Drink", systemImage: "plus.circle") }
                        .tag(1)

                    NavigationView { HistoryView() }
                        .tabItem { Label("History", systemImage: "clock") }
                        .tag(2)

                    NavigationView { ShareView() } // Ensure ShareView.swift is correctly referenced
                        .tabItem { Label("Share", systemImage: "person.2") }
                        .tag(3)

                    NavigationView { SettingsView() }
                        .tabItem { Label("Settings", systemImage: "gear") }
                        .tag(4)
                }
            }
        }
    }
    
    private var sidebarContent: some View {
        List {
            NavigationLink(destination: DashboardView()) { Label("Dashboard", systemImage: "gauge") }
            NavigationLink(destination: DrinkLogView()) { Label("Log Drink", systemImage: "plus.circle") }
            NavigationLink(destination: HistoryView()) { Label("History", systemImage: "clock") }
            NavigationLink(destination: ShareView()) { Label("Share", systemImage: "person.2") }
            NavigationLink(destination: SettingsView()) { Label("Settings", systemImage: "gear") }
        }
    }
    
    @ViewBuilder
    private func selectedTabView() -> some View {
        switch selectedTab {
        case 0: DashboardView()
        case 1: DrinkLogView()
        case 2: HistoryView()
        case 3: ShareView()
        case 4: SettingsView()
        default: DashboardView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(DrinkTracker())
    }
}

#Preview {
    ContentView()
}


