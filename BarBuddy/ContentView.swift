import SwiftUI


struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad/tablet layout
                NavigationSplitView {
                    sidebarContent
                        .navigationTitle("BarBuddy")
                } detail: {
                    GeometryReader { geometry in
                        NavigationStack {
                            selectedTabView()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                // iPhone layout
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

                    NavigationView { ShareView() }
                        .tabItem { Label("Share", systemImage: "person.2") }
                        .tag(3)

                    NavigationView { SettingsView() }
                        .tabItem { Label("Settings", systemImage: "gear") }
                        .tag(4)
                }
            }
        }
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
    }
    
    private var sidebarContent: some View {
        List {
            Button {
                selectedTab = 0
            } label: {
                Label("Dashboard", systemImage: "gauge")
                    .foregroundColor(selectedTab == 0 ? .accentColor : .primary)
            }
            .padding(.vertical, 8)
            
            Button {
                selectedTab = 1
            } label: {
                Label("Log Drink", systemImage: "plus.circle")
                    .foregroundColor(selectedTab == 1 ? .accentColor : .primary)
            }
            .padding(.vertical, 8)
            
            Button {
                selectedTab = 2
            } label: {
                Label("History", systemImage: "clock")
                    .foregroundColor(selectedTab == 2 ? .accentColor : .primary)
            }
            .padding(.vertical, 8)
            
            Button {
                selectedTab = 3
            } label: {
                Label("Share", systemImage: "person.2")
                    .foregroundColor(selectedTab == 3 ? .accentColor : .primary)
            }
            .padding(.vertical, 8)
            
            Button {
                selectedTab = 4
            } label: {
                Label("Settings", systemImage: "gear")
                    .foregroundColor(selectedTab == 4 ? .accentColor : .primary)
            }
            .padding(.vertical, 8)
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


