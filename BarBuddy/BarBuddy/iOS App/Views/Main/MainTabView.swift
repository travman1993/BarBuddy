import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label(Constants.Strings.homeTabLabel, systemImage: "house.fill")
                }
                .tag(0)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Label(Constants.Strings.historyTabLabel, systemImage: "clock.fill")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label(Constants.Strings.settingsTabLabel, systemImage: "gear")
                }
                .tag(2)
        }
        .onAppear {
            // Load user drinks when tab view appears
            Task {
                await drinkViewModel.loadRecentDrinks(userId: userViewModel.currentUser.id)
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(DrinkViewModel())
            .environmentObject(UserViewModel())
            .environmentObject(BACViewModel())
            .environmentObject(SettingsViewModel())
    }
}
