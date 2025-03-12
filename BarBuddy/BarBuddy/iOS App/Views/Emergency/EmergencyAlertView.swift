//
//  EmergencyAlertView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

struct EmergencyAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var emergencyViewModel: EmergencyViewModel
    
    @State private var customMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showingConfirmation: Bool = false
    @State private var error: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.UI.standardPadding) {
                    // Emergency Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.top, Constants.UI.largePadding)
                    
                    // Title
                    Text("Emergency Alert")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, Constants.UI.smallPadding)
                    
                    // Description
                    Text("This will send an alert to all your emergency contacts with your current location and a message.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Current contacts list
                    if !emergencyViewModel.contacts.isEmpty {
                        ContactsList(contacts: emergencyViewModel.contacts)
                    } else {
                        Text("No emergency contacts configured")
                            .italic()
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    
                    // Custom message input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a custom message (optional):")
                            .font(.headline)
                        
                        TextEditor(text: $customMessage)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(Constants.UI.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Send button
                    Button {
                        sendEmergencyAlert()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("SEND EMERGENCY ALERT")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
                    .padding(.horizontal)
                    .disabled(isLoading || emergencyViewModel.contacts.isEmpty)
                    
                    // Cancel button
                    Button("Cancel") {
                        dismiss()
                    }
                    .padding()
                    .disabled(isLoading)
                    
                    if let error = error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .alert("Alert Sent", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your emergency alert has been sent to your contacts.")
        }
    }
    
    private func sendEmergencyAlert() {
        guard !emergencyViewModel.contacts.isEmpty else {
            error = "You need to add emergency contacts first"
            return
        }
        
        isLoading = true
        error = nil
        
        let message = customMessage.isEmpty ? nil : customMessage
        
        Task {
            do {
                try await emergencyViewModel.sendEmergencyAlert(
                    userId: userViewModel.currentUser.id,
                    userName: userViewModel.currentUser.name ?? "User"
                )
                
                await MainActor.run {
                    isLoading = false
                    showingConfirmation = true
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to send alert: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct ContactsList: View {
    let contacts: [EmergencyContact]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emergency Contacts")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(contacts) { contact in
                HStack {
                    Text(contact.name)
                        .fontWeight(contact.isPrimary ? .bold : .regular)
                    
                    if contact.isPrimary {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(contact.formattedPhoneNumber)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                if contact.id != contacts.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .padding(.horizontal)
    }
}

struct EmergencyAlertView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyAlertView()
            .environmentObject(UserViewModel())
            .environmentObject({
                let viewModel = EmergencyViewModel()
                viewModel.contacts = [
                    EmergencyContact.example,
                    EmergencyContact(
                        userId: "example",
                        name: "John Smith",
                        phoneNumber: "5551234567"
                    )
                ]
                return viewModel
            }())
    }
}
