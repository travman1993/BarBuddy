//
//  OnboardingViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import Foundation
import Combine

class OnboardingViewModel: ObservableObject {
    // User data fields
    @Published var name: String = ""
    @Published var gender: Gender = .male
    @Published var weight: Double = 160.0
    @Published var age: Int = 25
    @Published var isMetric: Bool = false
    
    // Onboarding state
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    // User service
    private let userService = UserService()
    private let settingsService = SettingsService()
    
    // Step enum for tracking onboarding progress
    enum OnboardingStep {
        case welcome
        case gender
        case weight
        case userInfo
        case completed
    }
    
    // MARK: - Methods
    
    /// Advance to the next onboarding step
    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .gender
        case .gender:
            currentStep = .weight
        case .weight:
            currentStep = .userInfo
        case .userInfo:
            completeOnboarding()
        case .completed:
            break
        }
    }
    
    /// Go back to the previous onboarding step
    func previousStep() {
        switch currentStep {
        case .welcome:
            break // Already at first step
        case .gender:
            currentStep = .welcome
        case .weight:
            currentStep = .gender
        case .userInfo:
            currentStep = .weight
        case .completed:
            currentStep = .userInfo
        }
    }
    
    /// Save user data and complete onboarding
    func completeOnboarding() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Get current user ID or create a new one
                let userId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId) ?? UUID().uuidString
                
                // Save user ID if new
                if UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId) == nil {
                    UserDefaults.standard.set(userId, forKey: Constants.UserDefaultsKeys.currentUserId)
                }
                
                // Convert weight if needed
                let weightToSave = isMetric ? weight * 2.20462 : weight
                
                // Create or update user
                let user = try await userService.getUser(id: userId) ?? User(
                    id: userId,
                    gender: gender,
                    weight: weightToSave,
                    age: age
                )
                
                // Update user fields
                var updatedUser = user
                updatedUser.name = name.isEmpty ? nil : name
                updatedUser.gender = gender
                updatedUser.weight = weightToSave
                updatedUser.age = age
                
                // Save user
                _ = try await userService.updateUser(user: updatedUser)
                
                // Update settings for metric/imperial
                if isMetric {
                    var settings = try await settingsService.getSettings()
                    settings.useMetricUnits = true
                    try await settingsService.saveSettings(settings)
                }
                
                // Update onboarding flags
                UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasSeenOnboarding)
                
                await MainActor.run {
                    currentStep = .completed
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to save user data: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // Convert weight between units
    func toggleWeightUnit() {
        isMetric.toggle()
        if isMetric {
            // Convert lbs to kg
            weight = (weight * 0.453592).rounded(toPlaces: 1)
        } else {
            // Convert kg to lbs
            weight = (weight * 2.20462).rounded(toPlaces: 1)
        }
    }
    
    // Validate user input
    func validateInput() -> Bool {
        // Validate weight
        if weight <= 0 {
            error = "Please enter a valid weight"
            return false
        }
        
        // Validate age
        if age < 18 || age > 120 {
            error = "Please enter a valid age between 18 and 120"
            return false
        }
        
        error = nil
        return true
    }
}
