import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @State private var showingResetConfirmation = false
    @State private var showingSignOutConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // Account Section
                Section(header: Text("Account")) {
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                            Text("Profile Settings")
                        }
                    }
                    
                    NavigationLink(destination: EmergencyContactsView()) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("Emergency Contacts")
                        }
                    }
                }
                
                // Appearance Section
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $settingsViewModel.settings.useDarkMode)
                        .onChange(of: settingsViewModel.settings.useDarkMode) { _ in
                            settingsViewModel.toggleDarkMode()
                        }
                }
                
                // Units Section
                Section(header: Text("Units")) {
                    Toggle("Use Metric Units", isOn: $settingsViewModel.settings.useMetricUnits)
                        .onChange(of: settingsViewModel.settings.useMetricUnits) { _ in
                            settingsViewModel.toggleUnits()
                        }
                }
                
                // Notification Section
                Section(header: Text("Notifications")) {
                    Toggle("Safety Alerts", isOn: $settingsViewModel.settings.enableSafetyAlerts)
                        .onChange(of: settingsViewModel.settings.enableSafetyAlerts) { newValue in
                            settingsViewModel.updateNotificationSettings(enableSafetyAlerts: newValue)
                        }
                    
                    Toggle("Check-in Reminders", isOn: $settingsViewModel.settings.enableCheckInReminders)
                        .onChange(of: settingsViewModel.settings.enableCheckInReminders) { newValue in
                            settingsViewModel.updateNotificationSettings(enableCheckInReminders: newValue)
                        }
                    
                    Toggle("BAC Updates", isOn: $settingsViewModel.settings.enableBACUpdates)
                        .onChange(of: settingsViewModel.settings.enableBACUpdates) { newValue in
                            settingsViewModel.updateNotificationSettings(enableBACUpdates: newValue)
                        }
                    
                    Toggle("Hydration Reminders", isOn: $settingsViewModel.settings.enableHydrationReminders)
                        .onChange(of: settingsViewModel.settings.enableHydrationReminders) { newValue in
                            settingsViewModel.updateNotificationSettings(enableHydrationReminders: newValue)
                        }
                }
                
                // Privacy Section
                Section(header: Text("Privacy")) {
                    Toggle("Save Location Data", isOn: $settingsViewModel.settings.saveLocationData)
                        .onChange(of: settingsViewModel.settings.saveLocationData) { newValue in
                            settingsViewModel.updatePrivacySettings(saveLocationData: newValue)
                        }
                    
                    Toggle("Usage Analytics", isOn: $settingsViewModel.settings.analyticsEnabled)
                        .onChange(of: settingsViewModel.settings.analyticsEnabled) { newValue in
                            settingsViewModel.updatePrivacySettings(analyticsEnabled: newValue)
                        }
                }
                
                // Watch App Settings
                if WKExtension.isSupported {
                    Section(header: Text("Apple Watch")) {
                        Toggle("Watch Notifications", isOn: $settingsViewModel.settings.enableWatchAppNotifications)
                            .onChange(of: settingsViewModel.settings.enableWatchAppNotifications) { _ in
                                Task {
                                    await settingsViewModel.updateSettings()
                                }
                            }
                        
                        Toggle("Show BAC on Watch Face", isOn: $settingsViewModel.settings.showComplicationOnWatchFace)
                            .onChange(of: settingsViewModel.settings.showComplicationOnWatchFace) { _ in
                                Task {
                                    await settingsViewModel.updateSettings()
                                }
                            }
                    }
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Constants.App.version + " (\(Constants.App.build))")
                            .foregroundColor(.gray)
                    }
                    
                    Button {
                        if let url = URL(string: Constants.App.websiteURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Website")
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button {
                        if let url = URL(string: Constants.App.privacyPolicyURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button {
                        if let url = URL(string: "mailto:\(Constants.App.supportEmail)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Advanced Section
                Section {
                    Button("Reset Settings") {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.orange)
                    
                    Button("Sign Out") {
                        showingSignOutConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Settings?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task {
                        await settingsViewModel.resetToDefaults()
                    }
                }
            } message: {
                Text("This will reset all settings to their default values. This cannot be undone.")
            }
            .alert("Sign Out?", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await userViewModel.signOut()
                    }
                }
            } message: {
                Text("This will remove all your data from this device. Are you sure you want to sign out?")
            }
            .overlay {
                if settingsViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

// Helper to check if Apple Watch is available
struct WKExtension {
    static var isSupported: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserViewModel())
            .environmentObject(SettingsViewModel())
    }
}
