//
//  UserInfoView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/12/25.
//

import SwiftUI

struct UserInfoView: View {
    var coordinator: OnboardingCoordinator? = nil
    
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var name: String = ""
    @State private var age: Double = 25.0
    @State private var showingNextScreen = false
    @State private var isLoading = false
    
    // Age range
    private let minAge: Double = 18.0
    private let maxAge: Double = 100.0
    
    var body: some View {
        VStack(spacing: Constants.UI.largePadding) {
            // Progress indicator
            ProgressIndicator(currentStep: 3, totalSteps: 3)
                .padding(.top)
            
            // Title
            Text("Almost Done!")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name (Optional)")
                    .font(.headline)
                
                TextField("Enter your name", text: $name)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    .textContentType(.name)
                    .autocapitalization(.words)
            }
            .padding(.horizontal)
            
            // Age input
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Age")
                    .font(.headline)
                
                HStack {
                    Text("\(Int(age))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(width: 60)
                    
                    Slider(value: $age, in: minAge...maxAge, step: 1)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
            }
            .padding(.horizontal)
            
            // Description
            Text("Your information is stored locally on your device and is used only for calculating your BAC more accurately.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: Constants.UI.standardPadding) {
                Button {
                    if let coordinator = coordinator {
                        coordinator.showWeightEntry() // Go back to weight entry
                    } else {
                        // Navigate back
                        // In SwiftUI, this would normally be handled by NavigationView
                    }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .foregroundColor(.blue)
                        .cornerRadius(Constants.UI.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
                
                Button {
                    saveUserInfo()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(Constants.UI.cornerRadius)
                    } else {
                        Text("Complete Setup")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(Constants.UI.cornerRadius)
                    }
                }
                .disabled(isLoading)
            }
            .padding()
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingNextScreen) {
            DisclaimerView()
        }
    }
    
    private func saveUserInfo() {
        isLoading = true
        
        Task {
            do {
                try await userViewModel.updateUserProfile(
                    name: name.isEmpty ? nil : name,
                    age: Int(age)
                )
                
                // Mark onboarding as complete
                UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasSeenOnboarding)
                
                await MainActor.run {
                    isLoading = false
                    
                    // Navigate to disclaimer view
                    if let coordinator = coordinator {
                        coordinator.completeOnboarding()
                    } else {
                        showingNextScreen = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoView()
            .environmentObject(UserViewModel())
    }
}
