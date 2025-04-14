#if os(iOS)
import Foundation
import SwiftUI

class EmergencyContactManager: ObservableObject {
    static let shared = EmergencyContactManager()
    
    @Published var emergencyContacts: [EmergencyContact] = []
    
    private init() {
        loadContacts()
    }
    
    // MARK: - Contact Management
    
    func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: "emergencyContacts") {
            if let decoded = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
                self.emergencyContacts = decoded
            }
        }
    }
    
    func saveContacts() {
        if let encoded = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(encoded, forKey: "emergencyContacts")
        }
    }
    
    func addContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveContacts()
    }
    
    func updateContact(_ contact: EmergencyContact) {
        if let index = emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
            emergencyContacts[index] = contact
            saveContacts()
        }
    }
    
    func removeContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        saveContacts()
    }
    
    // MARK: - Emergency Messaging
    
    func sendSafetyCheckInMessage(to contact: EmergencyContact) {
        let message = "Hi, just checking in to let you know I made it home safely. (Sent via BarBuddy)"
        sendMessage(to: contact, message: message)
    }
    
    func sendCustomMessage(to contact: EmergencyContact, message: String) {
        sendMessage(to: contact, message: message)
    }
    
    func sendCurrentLocation(to contact: EmergencyContact) {
        let message = "BarBuddy Emergency: I need help. Here is my current location: [Location would be included here]"
        sendMessage(to: contact, message: message)
    }
    
    func sendMessage(to contact: EmergencyContact, message: String) {
        // Implement message sending logic
        print("Sending message to \(contact.name): \(message)")
    }
    
    // MARK: - Emergency Call
    
    func callEmergencyContact(_ contact: EmergencyContact) {
        let formattedNumber = contact.phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(formattedNumber)") {
            UIApplication.shared.open(url)
        }
    }
    
    func callEmergencyServices() {
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        return hours > 0 
            ? "\(hours) hours and \(minutes) minutes" 
            : "\(minutes) minutes"
    }
}

// MARK: - Emergency Contacts List View

struct EmergencyContactsListView: View {
    @StateObject private var contactManager = EmergencyContactManager.shared
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contactManager.emergencyContacts) { contact in
                    NavigationLink(destination: EmergencyContactDetailView(contact: contact)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(contact.name)
                                    .font(.headline)
                                
                                if contact.sendAutomaticTexts {
                                    Image(systemName: "message.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                            }
                            
                            Text(contact.relationshipType)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let contact = contactManager.emergencyContacts[index]
                        contactManager.removeContact(contact)
                    }
                }
                
                Button(action: {
                    showingAddContact = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Add Emergency Contact")
                    }
                }
            }
            .navigationTitle("Emergency Contacts")
            .sheet(isPresented: $showingAddContact) {
                AddEmergencyContactView()
            }
        }
    }
}

// MARK: - Emergency Contact Detail View

struct EmergencyContactDetailView: View {
    @State private var contact: EmergencyContact
    @State private var isEditMode = false
    @Environment(\.presentationMode) var presentationMode
    
    init(contact: EmergencyContact) {
        _contact = State(initialValue: contact)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Contact Information")) {
                if isEditMode {
                    TextField("Name", text: $contact.name)
                    TextField("Phone Number", text: $contact.phoneNumber)
                        .keyboardType(.phonePad)
                    
                    Picker("Relationship", selection: $contact.relationshipType) {
                        Text("Friend").tag("Friend")
                        Text("Family").tag("Family")
                        Text("Significant Other").tag("Significant Other")
                        Text("Roommate").tag("Roommate")
                        Text("Other").tag("Other")
                    }
                } else {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(contact.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Phone Number")
                        Spacer()
                        Text(contact.phoneNumber)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Relationship")
                        Spacer()
                        Text(contact.relationshipType)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Automatic Alerts")) {
                Toggle("Send updates automatically", isOn: $contact.sendAutomaticTexts)
                
                if contact.sendAutomaticTexts {
                    Text("This contact will receive automatic updates when you exceed 0.08.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !isEditMode {
                Section(header: Text("Actions")) {
                    Button(action: {
                        EmergencyContactManager.shared.callEmergencyContact(contact)
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                            Text("Call \(contact.name)")
                        }
                    }
                    
                    Button(action: {
                        EmergencyContactManager.shared.sendSafetyCheckInMessage(to: contact)
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                            Text("Send Safety Check-in")
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditMode ? "Edit Contact" : contact.name)
        .navigationBarItems(
            trailing: Button(isEditMode ? "Save" : "Edit") {
                if isEditMode {
                    // Save changes
                    EmergencyContactManager.shared.updateContact(contact)
                }
                isEditMode.toggle()
            }
        )
    }
}

// MARK: - Add Emergency Contact View

struct AddEmergencyContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var relationshipType = "Friend"
    @State private var sendAutomaticTexts = false
    
    var isValidContact: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    Picker("Relationship", selection: $relationshipType) {
                        Text("Friend").tag("Friend")
                        Text("Family").tag("Family")
                        Text("Significant Other").tag("Significant Other")
                        Text("Roommate").tag("Roommate")
                        Text("Other").tag("Other")
                    }
                }
                
                Section(header: Text("Options")) {
                    Toggle("Send automatic updates", isOn: $sendAutomaticTexts)
                    
                    if sendAutomaticTexts {
                        Text("This contact will receive automatic text messages when it exceeds certain thresholds.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Save Contact") {
                        let newContact = EmergencyContact(
                            name: name,
                            phoneNumber: phoneNumber,
                            relationshipType: relationshipType,
                            sendAutomaticTexts: sendAutomaticTexts
                        )
                        EmergencyContactManager.shared.addContact(newContact)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isValidContact)
                }
            }
            .navigationTitle("Add Emergency Contact")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Emergency Button View

struct EmergencyButtonView: View {
    @State private var showingEmergencyOptions = false
    
    var body: some View {
        Button(action: {
            showingEmergencyOptions = true
        }) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text("Emergency")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(10)
        }
        .actionSheet(isPresented: $showingEmergencyOptions) {
            ActionSheet(
                title: Text("Emergency Options"),
                message: Text("What do you need help with?"),
                buttons: [
                    .default(Text("Call 911")) {
                        EmergencyContactManager.shared.callEmergencyServices()
                    },
                    .default(Text("Contact Emergency Contact")) {
                        if let firstContact = EmergencyContactManager.shared.emergencyContacts.first {
                            EmergencyContactManager.shared.callEmergencyContact(firstContact)
                        }
                    },
                    .default(Text("Send Location to Contacts")) {
                        for contact in EmergencyContactManager.shared.emergencyContacts {
                            EmergencyContactManager.shared.sendCurrentLocation(to: contact)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
}
#endif
