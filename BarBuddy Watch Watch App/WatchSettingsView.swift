//
//  WatchSettingsView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/22/25.
//
import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var showingWeightInput = false
    
    var body: some View {
        List {
            Section(header: Text("User Profile")) {
                Button {
                    showingWeightInput = true
                } label: {
                    HStack {
                        Label("Weight", systemImage: "scalemass")
                        Spacer()
                        Text("\(Int(sessionManager.userWeight)) lbs")
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Label("Gender", systemImage: "person")
                    Spacer()
                    Text(sessionManager.userGender.capitalized)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("App Info")) {
                HStack {
                    Label("Last Sync", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    if let lastSync = sessionManager.lastSyncTime {
                        Text(timeAgoString(lastSync))
                            .foregroundColor(.gray)
                    } else {
                        Text("Never")
                            .foregroundColor(.gray)
                    }
                }
                
                Button {
                    sessionManager.requestInitialData()
                } label: {
                    Label("Sync Now", systemImage: "arrow.clockwise")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .sheet(isPresented: $showingWeightInput) {
            WeightInputView(currentWeight: sessionManager.userWeight)
                .environmentObject(sessionManager)
        }
    }
    
    private func timeAgoString(_ date: Date) -> String {
        let seconds = -date.timeIntervalSinceNow
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        }
    }
}
