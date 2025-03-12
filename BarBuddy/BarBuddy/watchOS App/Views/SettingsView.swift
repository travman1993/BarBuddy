//
//  SettingsView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI
import WatchKit

struct WatchSettingsView: View {
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    
    @State private var showingSyncMessage = false
    @State private var isSyncing = false
    
    var body: some View {
        List {
            // Sync with iPhone
            Button {
                syncWithiPhone()
            } label: {
                HStack {
                    Label("Sync with iPhone", systemImage: "arrow.triangle.2.circlepath")
                    
                    if isSyncing {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .disabled(isSyncing)
            
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
                    ScrollView {
                        Text(Constants.Strings.disclaimerText)
                            .font(.caption2)
                            .padding()
                    }
                    .navigationTitle("Disclaimer")
                } label: {
                    Text("Disclaimer")
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Syncing Complete", isPresented: $showingSyncMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Data has been synced with your iPhone.")
        }
    }
    
    private func syncWithiPhone() {
        guard !isSyncing else { return }
        
        isSyncing = true
        
        Task {
            await userViewModel.synchronizeData()
            
            await MainActor.run {
                isSyncing = false
                showingSyncMessage = true
            }
            
            WKInterfaceDevice.current().play(.success)
        }
    }
}

struct WatchProfileView: View {
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    
    var body: some View {
        List {
            // User info
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
            
            HStack {
                Text("Age")
                Spacer()
                Text("\(userViewModel.currentUser.age)")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Profile")
    }
}
