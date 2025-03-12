import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    private let settingsService = SettingsService()
    
    @Published var settings: Settings = Settings.default
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        isLoading = true
        
        Task {
            do {
                let loadedSettings = try await settingsService.getSettings()
                
                await MainActor.run {
                    settings = loadedSettings
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load settings: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    func updateSettings() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            try await settingsService.saveSettings(settings)
            
            await MainActor.run {
                isLoading = false
            }
            
            // Log event
            Analytics.shared.logEvent(.settingsChanged)
        } catch {
            await MainActor.run {
                self.error = "Failed to save settings: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func toggleDarkMode() {
        settings.useDarkMode.toggle()
        
        Task {
            await updateSettings()
        }
    }
    
    func toggleUnits() {
        settings.useMetricUnits.toggle()
        
        Task {
            await updateSettings()
        }
    }
    
    func updateNotificationSettings(
        enableSafetyAlerts: Bool? = nil,
        enableCheckInReminders: Bool? = nil,
        enableBACUpdates: Bool? = nil,
        enableHydrationReminders: Bool? = nil
    ) {
        if let enableSafetyAlerts = enableSafetyAlerts {
            settings.enableSafetyAlerts = enableSafetyAlerts
        }
        
        if let enableCheckInReminders = enableCheckInReminders {
            settings.enableCheckInReminders = enableCheckInReminders
        }
        
        if let enableBACUpdates = enableBACUpdates {
            settings.enableBACUpdates = enableBACUpdates
        }
        
        if let enableHydrationReminders = enableHydrationReminders {
            settings.enableHydrationReminders = enableHydrationReminders
        }
        
        Task {
            await updateSettings()
        }
    }
    
    func updatePrivacySettings(
        saveLocationData: Bool? = nil,
        analyticsEnabled: Bool? = nil
    ) {
        if let saveLocationData = saveLocationData {
            settings.saveLocationData = saveLocationData
        }
        
        if let analyticsEnabled = analyticsEnabled {
            settings.analyticsEnabled = analyticsEnabled
            Analytics.shared.setEnabled(analyticsEnabled)
        }
        
        Task {
            await updateSettings()
        }
    }
    
    func resetToDefaults() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            settings = Settings.default
            try await settingsService.resetToDefaults()
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to reset settings: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // Helpers for formatted values
    func getFormattedWeight(_ weight: Double) -> String {
        return weight.weightString(isMetric: settings.useMetricUnits)
    }
    
    func getFormattedVolume(_ volume: Double) -> String {
        return volume.volumeString(isMetric: settings.useMetricUnits)
    }
    
    func convertWeight(_ weight: Double, toMetric: Bool = false) -> Double {
        return settingsService.convertWeight(weight, toMetric: toMetric)
    }
}
