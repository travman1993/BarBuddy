//
//  WeightEntryView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/12/25.
//

import SwiftUI

struct WeightEntryView: View {
    var coordinator: OnboardingCoordinator? = nil
    
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var weight: Double = 160.0
    @State private var isMetric: Bool = false
    @State private var showingNextScreen = false
    
    // Min and max weights
    private let minWeight: Double = isMetric ? 30.0 : 66.0  // 30kg = ~66lbs
    private let maxWeight: Double = isMetric ? 200.0 : 440.0  // 200kg = ~440lbs
    
    var body: some View {
        VStack(spacing: Constants.UI.largePadding) {
            // Progress indicator
            ProgressIndicator(currentStep: 2, totalSteps: 3)
                .padding(.top)
            
            // Title
            Text("Enter Your Weight")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            // Description
            Text("Your weight is an important factor in calculating your Blood Alcohol Content (BAC).")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Weight display
            Text("\(Int(weight))")
                .font(.system(size: 60, weight: .bold))
                .padding()
            
            // Units toggle
            HStack {
                Text("Units:")
                    .font(.headline)
                
                Picker("Units", selection: $isMetric) {
                    Text("lbs").tag(false)
                    Text("kg").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
                .onChange(of: isMetric) { newValue in
                    convertWeight(to: newValue)
                }
            }
            .padding()
            
            // Weight slider
            VStack {
                Slider(value: $weight, in: minWeight...maxWeight, step: 1)
                    .padding(.horizontal)
                
                HStack {
                    Text("\(Int(minWeight))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(maxWeight))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: Constants.UI.standardPadding) {
                Button {
                    if let coordinator = coordinator {
                        coordinator.showGenderSelection() // Go back to gender selection
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
                    // Save weight
                    saveWeight()
                    
                    // Navigate to next screen
                    if let coordinator = coordinator {
                        coordinator.showUserInfo()
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
            UserInfoView()
        }
    }
    
    private func convertWeight(to metric: Bool) {
        if metric {
            // Convert lbs to kg
            weight = (weight * 0.453592).rounded()
        } else {
            // Convert kg to lbs
            weight = (weight * 2.20462).rounded()
        }
    }
    
    private func saveWeight() {
        // If metric, convert to pounds for storage
        let weightInPounds = isMetric ? (weight * 2.20462) : weight
        
        Task {
            try? await userViewModel.updateUserProfile(weight: weightInPounds)
        }
    }
}

struct WeightEntryView_Previews: PreviewProvider {
    static var previews: some View {
        WeightEntryView()
            .environmentObject(UserViewModel())
    }
}
