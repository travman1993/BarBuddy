//
//  SettingsView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var weight: Double = 160.0
    @State private var gender: Gender = .male
    @State private var drinkLimit: Double = 4.0  // Added drink limit state
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var showingAddContactSheet = false
    @State private var showingPurchaseView = false
    @State private var showingDisclaimerView = false
    @State private var showingAboutView = false
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        Form {
            // Personal Information Section
            Section(header: Text("PERSONAL INFORMATION"), footer: Text("Weight and Gender")) {
                VStack(alignment: .leading) {
                    Text("Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(Int(weight)) lbs")
                            .frame(width: 70, alignment: .leading)
                        
                        Slider(value: $weight, in: 80...400, step: 1)
                            .onChange(of: weight) {
                                // Update user profile when weight changes
                                updateUserProfile()
                            }
                    }
                }
                
                Picker("Gender", selection: $gender) {
                    Text("Male").tag(Gender.male)
                    Text("Female").tag(Gender.female)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: gender) {
                    // Update user profile when gender changes
                    updateUserProfile()
                }
            }
            
            // Drink Limit Section (New)
            Section(header: Text("DRINK SETTINGS")) {
                VStack(alignment: .leading) {
                    Text("Drink Limit")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(String(format: "%.1f", drinkLimit)) drinks")
                            .frame(width: 90, alignment: .leading)
                        
                        Slider(value: $drinkLimit, in: 1...20, step: 0.5)
                            .onChange(of: drinkLimit) {
                                // Update drink limit when slider changes
                                drinkTracker.updateDrinkLimit(drinkLimit)
                            }
                    }
                }
                
                Text("The app will notify you when you approach or reach this limit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Emergency Contacts Section
            Section(header: Text("EMERGENCY CONTACTS")) {
                ForEach(emergencyContacts) { contact in
                    EmergencyContactRow(contact: contact)
                }
                .onDelete(perform: deleteContact)
                
                Button(action: {
                    showingAddContactSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Add Emergency Contact")
                    }
                }
            }
            
            // Notification Settings
            Section(header: Text("NOTIFICATIONS")) {
                Toggle("Hydration Reminders", isOn: $settingsManager.enableHydrationReminders)
                Toggle("Auto-Text When Safe", isOn: $settingsManager.enableMorningCheckIns)
            }
                        
            // Apple Watch Settings
            Section(header: Text("APPLE WATCH")) {
                Toggle("Enable Quick Logging", isOn: $settingsManager.watchQuickAdd)
                Toggle("Haptic Feedback", isOn: $settingsManager.watchComplication)
                Toggle("Complication Display", isOn: $settingsManager.syncWithAppleWatch)
            }

            // App Settings
            Section(header: Text("APP SETTINGS")) {
                Button("View Legal Disclaimer") {
                    showingDisclaimerView = true
                }
                
                Button("Clear All Drink Data") {
                    // Add confirmation alert in real app
                    drinkTracker.clearDrinks()
                }
                .foregroundColor(.red)
            }
            
            // About & Support
            Section(header: Text("ABOUT & SUPPORT")) {
                Button("About BarBuddy") {
                    showingAboutView = true
                }
                
                Link("Rate on App Store", destination: URL(string: "https://apps.apple.com")!)
                
                Link("Send Feedback", destination: URL(string: "mailto:support@barbuddy.app")!)
                
                Text("Version 1.0")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .background(Color("AppBackground"))
        .onAppear {
            // Load current user profile and drink limit when view appears
            loadUserProfile()
            loadDrinkLimit()
        }
        .sheet(isPresented: $showingAddContactSheet) {
            AddContactView { newContact in
                // Add new contact and update profile
                emergencyContacts.append(newContact)
                updateUserProfile()
            }
        }
        .sheet(isPresented: $showingDisclaimerView) {
            DisclaimerView()
        }
        .sheet(isPresented: $showingAboutView) {
            AboutView()
        }
    }
    
    private func deleteContact(at offsets: IndexSet) {
        emergencyContacts.remove(atOffsets: offsets)
        updateUserProfile()
    }
    
    // Load user profile from drinkTracker
    private func loadUserProfile() {
        // Load from drinkTracker
        weight = drinkTracker.userProfile.weight
        gender = drinkTracker.userProfile.gender
        emergencyContacts = drinkTracker.userProfile.emergencyContacts
        
        // Also sync with AppSettingsManager
        settingsManager.weight = weight
        settingsManager.gender = gender
    }
    
    // Load drink limit from drinkTracker
    private func loadDrinkLimit() {
        drinkLimit = drinkTracker.drinkLimit
    }
    
    // Update user profile in drinkTracker and AppSettingsManager
    private func updateUserProfile() {
        let updatedProfile = UserProfile(
            weight: weight,
            gender: gender,
            emergencyContacts: emergencyContacts
        )
        
        // Update drinkTracker
        drinkTracker.updateUserProfile(updatedProfile)
        
        // Update settings manager for consistency
        settingsManager.weight = weight
        settingsManager.gender = gender
        settingsManager.saveSettings()
    }
}


// Emergency Contact Row
struct EmergencyContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contact.name)
                    .font(.headline)
                
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if contact.sendAutomaticTexts {
                Image(systemName: "message.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// Add Contact View
struct AddContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var relationship: String = "Friend"
    @State private var sendAutomaticTexts: Bool = false
    
    private let relationshipOptions = [
            "Friend",
            "Family",
            "Significant Other",
            "Roommate",
            "Other"
        ]
    
    let onAdd: (EmergencyContact) -> Void
    
    var isValidContact: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Details")) {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    Picker("Relationship", selection: $relationship) {
                        Text("Friend").tag("Friend")
                        Text("Family").tag("Family")
                        Text("Significant Other").tag("Significant Other")
                        Text("Roommate").tag("Roommate")
                        Text("Other").tag("Other")
                    }
                }
                
                Section(header: Text("Automatic Texts"), footer: Text("If enabled, this contact will receive automatic text messages when you reach certain levels.")) {
                    Toggle("Send Automatic Texts", isOn: $sendAutomaticTexts)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let newContact = EmergencyContact(
                        name: name,
                        phoneNumber: phoneNumber,
                        relationshipType: relationship,
                        sendAutomaticTexts: sendAutomaticTexts
                    )
                    onAdd(newContact)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!isValidContact)
            )
        }
    }
}

// Update the Disclaimer view in SettingsView.swift
struct DisclaimerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("BarBuddy Disclaimer")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Not a Medical Device")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text("BarBuddy is not a medical device and has not been evaluated by the FDA or any regulatory agency. It is designed for informational and educational purposes only.")
                            .foregroundColor(.primary)
                        
                        Text("Never Drink and Drive")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text("Never drive or operate machinery if you have consumed any amount of alcohol, regardless of what BarBuddy indicates. The only safe level when driving is 0.00%. Legal driving limits vary by jurisdiction, and exceeding them may result in serious legal consequences.")
                    }
                    
                    Group {
                        Text("Not a Substitute for Professional Advice")
                            .font(.headline)
                        
                        Text("This app is not a substitute for professional medical or legal advice. Consult healthcare providers for questions about alcohol consumption and health, and legal professionals for advice on alcohol-related laws.")
                        
                        Text("Emergency Features")
                            .font(.headline)
                        
                        Text("The emergency contact and rideshare features are provided as conveniences and are not guaranteed to function in all circumstances. Never rely solely on BarBuddy in an emergency situation.")
                        
                        Text("Limitation of Liability")
                            .font(.headline)
                        
                        Text("The developers of BarBuddy are not responsible for any actions you take while using this app, including but not limited to decisions regarding alcohol consumption, driving, or other potentially dangerous activities.")
                        
                        Text("By using BarBuddy, you acknowledge these limitations and agree to use the app responsibly.")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
            }
            .navigationTitle("Legal Disclaimer")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// About View
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "wineglass")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("BarBuddy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personal drinking companion")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer().frame(height: 20)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("BarBuddy helps you:")
                        .font(.headline)
                    
                    BulletPoint(text: "Track your drinks")
                    BulletPoint(text: "Make safer decisions about drinking")
                    BulletPoint(text: "Share your status with friends")
                    BulletPoint(text: "Get home safely with rideshare integration")
                    BulletPoint(text: "Set up emergency contacts")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
                
                Text("Made with ❤️ by BarBuddy Team")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("© 2025 BarBuddy. All rights reserved.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("About")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.headline)
                .padding(.trailing, 5)
            
            Text(text)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(DrinkTracker())
    }
}
