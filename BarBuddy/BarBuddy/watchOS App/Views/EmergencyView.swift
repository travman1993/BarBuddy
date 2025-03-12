//
//  EmergencyView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI
import WatchKit

struct WatchEmergencyView: View {
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = "Failed to send alert. Please try again."
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // SOS Button
                Button {
                    sendEmergencyAlert()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "sos")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        
                        Text("Emergency Alert")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Check-in Button
                Button {
                    sendCheckIn()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        
                        Text("Check In")
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Ride share button
                Button {
                    getRide()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        Text("Get a Ride")
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
        .navigationTitle("Emergency")
        .alert("Emergency Alert Sent", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your emergency contacts have been notified.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func sendEmergencyAlert() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                try await userViewModel.sendEmergencyAlert()
                
                // Haptic feedback
                WKInterfaceDevice.current().play(.success)
                
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send alert: \(error.localizedDescription)"
                    showingError = true
                }
                
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
    
    private func sendCheckIn() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                try await userViewModel.sendCheckIn()
                
                // Haptic feedback
                WKInterfaceDevice.current().play(.success)
                
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send check-in: \(error.localizedDescription)"
                    showingError = true
                }
                
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
    
    private func getRide() {
        // Open companion app on iPhone for ride sharing
        #if os(watchOS)
        WKExtension.shared().openParentApplication(["action": "getRide"]) { _, _ in }
        #endif
    }
}
