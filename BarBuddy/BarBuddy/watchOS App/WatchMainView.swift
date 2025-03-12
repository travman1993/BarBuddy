//
//  WatchMainView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

struct WatchMainView: View {
    @EnvironmentObject private var bacViewModel: WatchBACViewModel
    @EnvironmentObject private var drinkViewModel: WatchDrinkViewModel
    
    @State private var isRefreshing = false
    
    var body: some View {
        TabView {
            // BAC Tab
            WatchBACView()
            
            // Quick Add Tab
            WatchQuickAddView()
            
            // Emergency Tab
            WatchEmergencyView()
            
            // Settings Tab
            WatchSettingsView()
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
