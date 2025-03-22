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
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var showingAddContactSheet = false
    @State private var showingPurchaseView = false
    @State private var showingDisclaimerView = false
    @State private var showingAboutView = false
    
    var body: some View {
        Form {
            // Personal Information Section
            Section(header: Text("Personal Information"), footer: Text("Weight and gender are used to calculate your BAC more accurately.")) {
                VStack(alignment: .leading) {
                    Text("Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(Int(weight)) lbs")
                            .frame(width: 70, alignment: .leading)
                        
                        Slider(value: $weight, in: 80...400, step: 1)
                            // Fixed onChange syntax for iOS 17.0+
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
                // Fixed onChange syntax for iOS 17.0+
                .onChange(of: gender) {
                    // Update user profile when gender changes
                    updateUserProfile()
                }
            }
            
            // Emergency Contacts Section
            Section(header: Text("Emergency Contacts")) {
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
            Section(header: Text("Notifications")) {
                Toggle("Hydration Reminders", isOn: .constant(true))
                Toggle("BAC Level Alerts", isOn: .constant(true))
                Toggle("Auto-Text When Safe", isOn: .constant(false))
            }
            
            // Apple Watch Settings
            Section(header: Text("Apple Watch")) {
                Toggle("Enable Quick Logging", isOn: .constant(true))
                Toggle("Haptic Feedback", isOn: .constant(true))
                Toggle("Complication Display", isOn: .constant(true))
            }
            
            // App Settings
            Section(header: Text("App Settings")) {
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
            Section(header: Text("About & Support")) {
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
        .onAppear {
            // Load current user profile when view appears
            loadUserProfile()
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
    
    // Load user profile from drinkTracker
    private func loadUserProfile() {
        weight = drinkTracker.userProfile.weight
        gender = drinkTracker.userProfile.gender
        emergencyContacts = drinkTracker.userProfile.emergencyContacts
    }
    
    // Update user profile in drinkTracker
    private func updateUserProfile() {
        let updatedProfile = UserProfile(
            weight: weight,
            gender: gender,
            emergencyContacts: emergencyContacts
        )
        drinkTracker.updateUserProfile(updatedProfile)
    }
    
    // Delete emergency contact
    private func deleteContact(at offsets: IndexSet) {
        emergencyContacts.remove(atOffsets: offsets)
        updateUserProfile()
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
                
                Section(header: Text("Automatic Texts"), footer: Text("If enabled, this contact will receive automatic text messages when you reach certain BAC levels.")) {
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

// Disclaimer View
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
                        
                        Text("BAC Estimation")
                            .font(.headline)
                        
                        Text("BarBuddy provides an estimate of your blood alcohol content (BAC) based on the information you provide. This estimate is not intended to be a precise measurement of your actual BAC and should not be relied upon to determine whether you are legally able to drive.")
                        
                        Text("Not a Substitute for Judgment")
                            .font(.headline)
                        
                        Text("BarBuddy is not a substitute for your own judgment or for a professional grade breathalyzer or blood test. Many factors can affect your BAC, including but not limited to: your rate of alcohol consumption, your metabolism, what and when you've eaten, your hydration level, medications you may be taking, and your overall health.")
                        
                        Text("Do Not Drink and Drive")
                            .font(.headline)
                        
                        Text("Never drive or operate machinery if you have consumed any amount of alcohol, regardless of what BarBuddy or any app indicates. The only safe BAC when driving is 0.00%.")
                    }
                    
                    Group {
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
                    
                    BulletPoint(text: "Track your drinks and estimate BAC")
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
