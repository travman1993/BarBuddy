//
//  WatchMainView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

// MainView.swift
import SwiftUI
import WatchKit

struct WatchMainView: View {
    @EnvironmentObject private var bacViewModel: WatchBACViewModel
    @EnvironmentObject private var drinkViewModel: WatchDrinkViewModel
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    
    @State private var isRefreshing = false
    
    var body: some View {
        TabView {
            // BAC Tab
            NavigationView {
                WatchBACView()
            }
            .tag(0)
            
            // Quick Add Tab
            NavigationView {
                WatchQuickAddView()
            }
            .tag(1)
            
            // Emergency Tab
            NavigationView {
                WatchEmergencyView()
            }
            .tag(2)
            
            // Settings Tab
            NavigationView {
                WatchSettingsView()
            }
            .tag(3)
        }
        .tabViewStyle(PageTabViewStyle())
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        
        Task {
            await bacViewModel.refreshBAC()
            await drinkViewModel.loadRecentDrinks(userId: userViewModel.currentUser.id)
            isRefreshing = false
        }
    }
}

struct WatchMainView_Previews: PreviewProvider {
    static var previews: some View {
        WatchMainView()
            .environmentObject(WatchBACViewModel())
            .environmentObject(WatchDrinkViewModel())
            .environmentObject(WatchUserViewModel())
    }
}

struct WatchBACView_Previews: PreviewProvider {
    static var previews: some View {
        WatchBACView()
            .environmentObject(WatchBACViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
    }
}

struct WatchQuickAddView_Previews: PreviewProvider {
    static var previews: some View {
        WatchQuickAddView()
            .environmentObject(WatchDrinkViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
            .environmentObject(WatchBACViewModel.preview)
    }
}

struct WatchMainView_Previews: PreviewProvider {
    static var previews: some View {
        WatchMainView()
            .environmentObject(WatchBACViewModel.preview)
            .environmentObject(WatchDrinkViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
    }
}
