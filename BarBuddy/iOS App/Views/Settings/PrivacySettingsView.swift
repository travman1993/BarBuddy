import SwiftUI
import CoreLocation

struct PrivacySettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @State private var locationAuthorized = false
    @State private var isCheckingLocationStatus = true
    @State private var isLoading = false
    @State private var showingLocationAlert = false
    
    private let locationService = LocationService()
    
    var body: some View {
        Form {
            Section(header: Text("Data Collection")) {
                Toggle("Save Location Data", isOn: $settingsViewModel.settings.saveLocationData)
                    .onChange(of: settingsViewModel.settings.saveLocationData) { newValue in
                        if newValue {
                            requestLocationPermission()
                        } else {
                            saveSettings()
                        }
                    }
                
                Text("Location data helps provide context to your drink logs and enables emergency features")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Enable Analytics", isOn: $settingsViewModel.settings.analyticsEnabled)
                    .onChange(of: settingsViewModel.settings.analyticsEnabled) { newValue in
                        Analytics.shared.setEnabled(newValue)
                        saveSettings()
                    }
                
                Text("Anonymous usage data helps us improve the app")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Location Status")) {
                HStack {
                    Text("Location Access")
                    Spacer()
                    if isCheckingLocationStatus {
                        ProgressView()
                    } else {
                        Text(locationAuthorized ? "Granted" : "Not Granted")
                            .foregroundColor(locationAuthorized ? .green : .red)
                    }
                }
                
                if !locationAuthorized && settingsViewModel.settings.saveLocationData {
                    Button("Enable Location") {
                        requestLocationPermission()
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section(header: Text("Your Data")) {
                // Show data usage explanation
                NavigationLink(destination: DataUsageView()) {
                    Text("How We Use Your Data")
                }
                
                // Export or delete data
                NavigationLink(destination: DataManagementView()) {
                    Text("Export or Delete Your Data")
                }
            }
        }
        .navigationTitle("Privacy & Data")
        .onAppear {
            checkLocationStatus()
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
        .alert("Enable Location", isPresented: $showingLocationAlert) {
            Button("Cancel", role: .cancel) {
                // If they cancel, turn off the location setting
                settingsViewModel.settings.saveLocationData = false
                saveSettings()
            }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Location access is required for this feature. Please enable location access in Settings.")
        }
    }
    
    private func checkLocationStatus() {
        isCheckingLocationStatus = true
        
        locationService.requestLocationPermission { status in
            DispatchQueue.main.async {
                self.locationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
                self.isCheckingLocationStatus = false
            }
        }
    }
    
    private func requestLocationPermission() {
        isLoading = true
        
        locationService.requestLocationPermission { status in
            DispatchQueue.main.async {
                self.locationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
                self.isLoading = false
                
                if !self.locationAuthorized {
                    self.showingLocationAlert = true
                } else {
                    self.saveSettings()
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

struct DataUsageView: View {
    var body: some View {
        List {
            Section(header: Text("Location Data")) {
                Text("When enabled, your location data is used to:")
                    .font(.subheadline)
                    .padding(.bottom, 4)
                
                BulletPointView(text: "Provide context for your drink logs")
                BulletPointView(text: "Enable emergency features to send your location to emergency contacts")
                BulletPointView(text: "Help find ride services in your area")
                
                Text("Location data is stored locally on your device and is not shared with third parties except when explicitly sending an emergency alert.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Section(header: Text("Analytics")) {
                Text("When enabled, anonymous analytics include:")
                    .font(.subheadline)
                    .padding(.bottom, 4)
                
                BulletPointView(text: "App usage patterns (which features you use)")
                BulletPointView(text: "Performance metrics")
                BulletPointView(text: "General device information")
                
                Text("Analytics data is anonymized and does not include personally identifiable information or sensitive health data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Section(header: Text("Health Data")) {
                Text("BarBuddy uses the following health-related data:")
                    .font(.subheadline)
                    .padding(.bottom, 4)
                
                BulletPointView(text: "Weight (for BAC calculations)")
                BulletPointView(text: "Gender (for BAC calculations)")
                BulletPointView(text: "Age (for demographic information)")
                BulletPointView(text: "Drink consumption (for BAC tracking)")
                
                Text("All health data is stored locally on your device. You can export or delete this data at any time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Data Usage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BulletPointView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
            
            Text(text)
                .font(.body)
        }
    }
}

struct DataManagementView: View {
    @State private var isExporting = false
    @State private var isDeleting = false
    @State private var showingDeleteConfirmation = false
    @State private var showingExportSuccess = false
    @State private var showingDeleteSuccess = false
    
    var body: some View {
        List {
            Section(header: Text("Export Data")) {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        
                        Text("Export All Data")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting || isDeleting)
                
                Text("This will create a file with all your drink logs, settings, and user information that you can save.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Delete Data")) {
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        
                        Text("Delete All Data")
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        if isDeleting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting || isDeleting)
                
                Text("This will permanently delete all your data from this device. This action cannot be undone.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Manage Your Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteData()
            }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
        .alert("Data Exported", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data has been exported successfully.")
        }
        .alert("Data Deleted", isPresented: $showingDeleteSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All your data has been permanently deleted.")
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            showingExportSuccess = true
        }
    }
    
    private func deleteData() {
        isDeleting = true
        
        // Simulate delete process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isDeleting = false
            showingDeleteSuccess = true
            
            // In a real app, you would actually delete all user data here
            // and possibly restart the app to the onboarding flow
        }
    }
}

struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacySettingsView()
                .environmentObject(SettingsViewModel())
        }
    }
}
