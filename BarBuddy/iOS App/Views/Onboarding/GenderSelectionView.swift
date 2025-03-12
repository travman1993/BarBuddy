//
//  GenderSelectionView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/12/25.
//

import SwiftUI

struct GenderSelectionView: View {
    var coordinator: OnboardingCoordinator? = nil
    
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var selectedGender: Gender = .male
    @State private var showingNextScreen = false
    
    var body: some View {
        VStack(spacing: Constants.UI.largePadding) {
            // Progress indicator
            ProgressIndicator(currentStep: 1, totalSteps: 3)
                .padding(.top)
            
            // Title
            Text("Select Your Biological Sex")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            // Description
            Text("This helps us calculate your Blood Alcohol Content (BAC) more accurately. Different biological sexes process alcohol differently.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Gender selection
            VStack(spacing: Constants.UI.standardPadding) {
                ForEach(Gender.allCases) { gender in
                    GenderOption(
                        gender: gender,
                        isSelected: selectedGender == gender,
                        action: {
                            selectedGender = gender
                        }
                    )
                }
            }
            .padding()
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: Constants.UI.standardPadding) {
                Button {
                    if let coordinator = coordinator {
                        coordinator.start() // Go back to welcome
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
                    // Save gender selection
                    Task {
                        try? await userViewModel.updateUserProfile(gender: selectedGender)
                    }
                    
                    // Navigate to next screen
                    if let coordinator = coordinator {
                        coordinator.showWeightEntry()
                    } else {
                        showingNextScreen = true
                    }
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.cornerRadius)
                }
            }
            .padding()
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingNextScreen) {
            WeightEntryView()
        }
    }
}

struct GenderOption: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(gender.displayName)
                    .font(.headline)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

struct GenderSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        GenderSelectionView()
            .environmentObject(UserViewModel())
    }
}
