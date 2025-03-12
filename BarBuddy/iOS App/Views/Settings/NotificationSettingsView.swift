import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @State private var notificationsAuthorized = false
    @State private var isCheckingStatus = true
    @State private var isLoading = false
    @State private var showingPermissionAlert = false
    
    private let notificationService = NotificationService()
    
    var body: some View {
        Form {
            Section(header: Text("Status")) {
                HStack {
                    Text("Notifications")
                    Spacer()
                    if isCheckingStatus {
                        ProgressView()
                    } else {
                        Text(notificationsAuthorized ? "Enabled" : "Disabled")
                            .foregroundColor(notificationsAuthorized ? .green : .red)
                    }
                }
                
                if !notificationsAuthorized {
                    Button("Enable Notifications") {
                        requestPermissions()
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if notificationsAuthorized {
                Section(header: Text("Safety Notifications")) {
                    Toggle("BAC Updates", isOn: $settingsViewModel.settings.enableBACUpdates)
                        .onChange(of: settingsViewModel.settings.enableBACUpdates) { _ in
                            saveSettings()
                        }
                    
                    Toggle("Safety Alerts", isOn: $settingsViewModel.settings.enableSafetyAlerts)
                        .onChange(of: settingsViewModel.settings.enableSafetyAlerts) { _ in
                            saveSettings()
                        }
                }
                
                Section(header: Text("Check-In Notifications")) {
                    Toggle("Check-In Reminders", isOn: $settingsViewModel.settings.enableCheckInReminders)
                        .onChange(of: settingsViewModel.settings.enableCheckInReminders) { _ in
                            saveSettings()
                        }
                    
                    Toggle("Hydration Reminders", isOn: $settingsViewModel.settings.enableHydrationReminders)
                        .onChange(of: settingsViewModel.settings.enableHydrationReminders) { _ in
                            saveSettings()
                        }
                }
                
                Section(header: Text("Apple Watch")) {
                    Toggle("Watch App Notifications", isOn: $settingsViewModel.settings.enableWatchAppNotifications)
                        .onChange(of: settingsViewModel.settings.enableWatchAppNotifications) { _ in
                            saveSettings()
                        }
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            checkNotificationStatus()
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    .shadow(radius: 5)
            }
        }
        .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Please enable notifications in Settings to receive important BAC updates and safety alerts.")
        }
    }
    
    private func checkNotificationStatus() {
        isCheckingStatus = true
        
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAuthorized = settings.authorizationStatus == .authorized
                self.isCheckingStatus = false
            }
        }
    }
    
    private func requestPermissions() {
        isLoading = true
        
        Task {
            let granted = await notificationService.requestPermissions()
            
            await MainActor.run {
                notificationsAuthorized = granted
                isLoading = false
                
                if granted {
                    notificationService.setUpNotificationCategories()
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func saveSettings() {
        isLoading = true
        
        Task {
            await settingsViewModel.updateSettings()
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView()
                .environmentObject(SettingsViewModel())
        }
    }
}
