//
//  MainView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

// MainView.swift
import SwiftUI

struct MainView: View {
    @EnvironmentObject private var bacViewModel: WatchBACViewModel
    @EnvironmentObject private var drinkViewModel: WatchDrinkViewModel
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    
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
        }
        .tabViewStyle(PageTabViewStyle())
        .onAppear {
            // Load data when the view appears
            Task {
                await bacViewModel.refreshBAC()
                await drinkViewModel.loadRecentDrinks(userId: userViewModel.currentUser.id)
            }
        }
    }
}
