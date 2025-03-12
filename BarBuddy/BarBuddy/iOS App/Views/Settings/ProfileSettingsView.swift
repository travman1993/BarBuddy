import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @State private var name: String = ""
    @State private var gender: Gender = .male
    @State private var weight: Double = 160.0
    @State private var age: Int = 25
    @State private var isMetric: Bool = false
    
    @State private var isLoading: Bool = false
    @State private var showingSaved: Bool = false
    @State private var error: String? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $name)
                    .autocapitalization(.words)
                
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                
                // Age picker
                Picker("Age", selection: $age) {
                    ForEach(18...100, id: \.self) { age in
                        Text("\(age)").tag(age)
                    }
                }
            }
            
            Section(header: Text("Weight")) {
                // Units toggle
                Picker("Units", selection: $isMetric) {
                    Text("Pounds (lbs)").tag(false)
                    Text("Kilograms (kg)").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: isMetric) { newValue in
                    // Convert weight when changing units
                    if newValue {
                        // Convert lbs to kg
                        weight = (weight * 0.453592).rounded(toPlaces: 1)
                    } else {
                        // Convert kg to lbs
                        weight = (weight * 2.20462).rounded(toPlaces: 1)
                    }
                }
                
                // Weight input
                HStack {
                    Text("Weight")
                    Spacer()
                    Text("\(weight, specifier: "%.1f") \(isMetric ? "kg" : "lbs")")
                }
                
                // Weight slider
                Slider(
                    value: $weight,
                    in: isMetric ? 30...200 : 66...440,
                    step: isMetric ? 0.5 : 1
                )
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Account Created")
                    Spacer()
                    Text(userViewModel.currentUser.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = error {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Section {
                Button(action: saveProfile) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Profile")
        .onAppear(perform: loadUserData)
        .alert("Profile Updated", isPresented: $showingSaved) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func loadUserData() {
        // Load current user data
        let user = userViewModel.currentUser
        name = user.name ?? ""
        gender = user.gender
        
        // Check if we should use metric units
        isMetric = settingsViewModel.settings.useMetricUnits
        
        // Convert weight to the right units
        weight = isMetric ?
            user.weight * 0.453592 : // Convert lbs to kg if metric
            user.weight              // Keep as lbs if imperial
        
        age = user.age
    }
    
    private func saveProfile() {
        isLoading = true
        error = nil
        
        // Convert weight to pounds for storage if needed
        let weightInPounds = isMetric ? (weight * 2.20462) : weight
        
        Task {
            do {
                // Update user profile
                try await userViewModel.updateUserProfile(
                    name: name.isEmpty ? nil : name,
                    gender: gender,
                    weight: weightInPounds,
                    age: age
                )
                
                // Update metric setting if changed
                if isMetric != settingsViewModel.settings.useMetricUnits {
                    await settingsViewModel.updateSettings(useMetricUnits: isMetric)
                }
                
                await MainActor.run {
                    isLoading = false
                    showingSaved = true
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to save profile: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileSettingsView()
                .environmentObject(UserViewModel())
                .environmentObject(SettingsViewModel())
        }
    }
}
