import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    
    @State private var isLoading = false
    @State private var showingSaved = false
    
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("App Theme", selection: $colorScheme) {
                    Text("System Default").tag("system")
                    Text("Light Mode").tag("light")
                    Text("Dark Mode").tag("dark")
                }
                .pickerStyle(DefaultPickerStyle())
                .onChange(of: colorScheme) { newValue in
                    // Update settings if selecting dark mode explicitly
                    if newValue == "dark" && !settingsViewModel.settings.useDarkMode {
                        updateDarkMode(true)
                    } else if newValue == "light" && settingsViewModel.settings.useDarkMode {
                        updateDarkMode(false)
                    }
                }
            }
            
            Section(header: Text("Units")) {
                Toggle("Use Metric Units", isOn: $settingsViewModel.settings.useMetricUnits)
                    .onChange(of: settingsViewModel.settings.useMetricUnits) { _ in
                        saveSettings()
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(settingsViewModel.settings.useMetricUnits ? "Kilograms (kg)" : "Pounds (lbs)")
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(settingsViewModel.settings.useMetricUnits ? "Milliliters (ml)" : "Fluid Ounces (oz)")
                        .font(.body)
                }
            }
            
            Section(header: Text("Display")) {
                Toggle("Show BAC on Home Screen", isOn: $settingsViewModel.settings.showBAConHomeScreen)
                    .onChange(of: settingsViewModel.settings.showBAConHomeScreen) { _ in
                        saveSettings()
                    }
                
                Toggle("Show Emergency Button", isOn: $settingsViewModel.settings.showEmergencyButtonOnHomeScreen)
                    .onChange(of: settingsViewModel.settings.showEmergencyButtonOnHomeScreen) { _ in
                        saveSettings()
                    }
            }
        }
        .navigationTitle("Appearance")
        .overlay {
            if isLoading {
                ProgressView()
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    .shadow(radius: 5)
            }
        }
        .alert("Settings Saved", isPresented: $showingSaved) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func updateDarkMode(_ useDarkMode: Bool) {
        Task {
            await settingsViewModel.updateSettings(useDarkMode: useDarkMode)
        }
    }
    
    private func saveSettings() {
        isLoading = true
        
        Task {
            await settingsViewModel.updateSettings()
            
            await MainActor.run {
                isLoading = false
                showingSaved = true
            }
        }
    }
}

struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppearanceSettingsView()
                .environmentObject(SettingsViewModel())
        }
    }
}
