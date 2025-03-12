//
//  SettingsView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    
    @State private var showingSyncMessage = false
    
    var body: some View {
        NavigationView {
            List {
                // Sync with iPhone
                Button {
                    syncWithiPhone()
                } label: {
                    Label("Sync with iPhone", systemImage: "arrow.triangle.2.circlepath")
                }
                
                // User Profile
                NavigationLink {
                    WatchProfileView()
                } label: {
                    Label("Profile", systemImage: "person.circle")
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Constants.App.version)
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink {
                        Text(Constants.Strings.disclaimerText)
                            .font(.caption2)
                            .padding()
                    } label: {
                        Text("Disclaimer")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Syncing with iPhone", isPresented: $showingSyncMessage) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Data is being synced with your iPhone. Any pending changes will be updated.")
            }
        }
    }
    
    private func syncWithiPhone() {
        Task {
            await userViewModel.synchronizeData()
            showingSyncMessage = true
        }
    }
}

struct WatchProfileView: View {
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    
    var body: some View {
        List {
            HStack {
                Text("Name")
                Spacer()
                Text(userViewModel.currentUser.name ?? "Not set")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Gender")
                Spacer()
                Text(userViewModel.currentUser.gender.displayName)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Weight")
                Spacer()
                Text(userViewModel.currentUser.displayWeight)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Profile")
    }
}

struct WatchSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        WatchSettingsView()
            .environmentObject(WatchUserViewModel())
    }
}
