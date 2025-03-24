//
//  EmergencyContactManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import SwiftUI
import Contacts
import ContactsUI
import MessageUI

class EmergencyContactManager: NSObject, ObservableObject {
    static let shared = EmergencyContactManager()
    
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var isShowingContactPicker = false
    @Published var isShowingMessageComposer = false
    @Published var selectedContact: EmergencyContact?
    @Published var messageText = ""
    
    override init() {
        super.init()
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
    
    func sendEmergencyBACUpdate(bac: Double, timeUntilSober: TimeInterval) {
        // Get only contacts that have automatic texts enabled
        let eligibleContacts = emergencyContacts.filter { $0.sendAutomaticTexts }
        
        if eligibleContacts.isEmpty {
            return
        }
        
        // Format message
        let soberTime = formatTimeInterval(timeUntilSober)
        let message = "BarBuddy Automatic Alert: My current BAC is \(String(format: "%.3f", bac)). I'll be safe to drive in approximately \(soberTime)."
        
        for contact in eligibleContacts {
            sendMessage(to: contact, message: message)
        }
    }
    
    func sendSafetyCheckInMessage(to contact: EmergencyContact) {
        let message = "Hi, just checking in to let you know I made it home safely. (Sent via BarBuddy)"
        sendMessage(to: contact, message: message)
    }
    
    func sendCustomMessage(to contact: EmergencyContact, message: String) {
        sendMessage(to: contact, message: message)
    }
    
    func sendCurrentLocation(to contact: EmergencyContact) {
        // In a real app, this would get the user's location
        // and format it as a message with coordinates or a map link
        let message = "BarBuddy Emergency: I need help. Here is my current location: [Location would be included here]"
        sendMessage(to: contact, message: message)
    }
    
    func sendMessage(to contact: EmergencyContact, message: String) {
        self.selectedContact = contact
        self.messageText = message
        self.isShowingMessageComposer = true
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
        
        if hours > 0 {
            return "\(hours) hours and \(minutes) minutes"
        } else {
            return "\(minutes) minutes"
        }
    }
}

// MARK: - Message Composer Delegate

extension EmergencyContactManager: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Contact Picker UI

struct ContactPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onSelectContact: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onSelectContact(contact)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Message Composer UI

struct MessageComposerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var recipients: [String]
    var body: String
    var delegate: MFMessageComposeViewControllerDelegate
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.recipients = recipients
        composer.body = body
        composer.messageComposeDelegate = delegate
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
}

// MARK: - Emergency Contact Detail View

struct EmergencyContactDetailView: View {
    @ObservedObject var contactManager: EmergencyContactManager
    @State private var contact: EmergencyContact
    @State private var isEditMode = false
    @Environment(\.presentationMode) var presentationMode
    
    init(contact: EmergencyContact, contactManager: EmergencyContactManager) {
        self.contactManager = contactManager
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
                Toggle("Send BAC updates automatically", isOn: $contact.sendAutomaticTexts)
                
                if contact.sendAutomaticTexts {
                    Text("This contact will receive automatic updates when your BAC exceeds 0.08 or after your fifth standard drink.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !isEditMode {
                Section(header: Text("Actions")) {
                    Button(action: {
                        contactManager.callEmergencyContact(contact)
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                            Text("Call \(contact.name)")
                        }
                    }
                    
                    Button(action: {
                        contactManager.sendSafetyCheckInMessage(to: contact)
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                            Text("Send Safety Check-in")
                        }
                    }
                    
                    Button(action: {
                        contactManager.sendCurrentLocation(to: contact)
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            Text("Send Current Location")
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
                    contactManager.updateContact(contact)
                }
                isEditMode.toggle()
            }
        )
    }
}

// MARK: - Emergency Contacts List View

struct EmergencyContactsListView: View {
    @ObservedObject var contactManager = EmergencyContactManager.shared
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contactManager.emergencyContacts) { contact in
                    NavigationLink(destination: EmergencyContactDetailView(contact: contact, contactManager: contactManager)) {
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
                AddEmergencyContactView(contactManager: contactManager)
            }
            .sheet(isPresented: $contactManager.isShowingContactPicker) {
                ContactPickerView { contact in
                    let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
                    let newContact = EmergencyContact(
                        name: "\(contact.givenName) \(contact.familyName)",
                        phoneNumber: phoneNumber,
                        relationshipType: "Other",
                        sendAutomaticTexts: false
                    )
                    contactManager.addContact(newContact)
                }
            }
            .sheet(isPresented: $contactManager.isShowingMessageComposer) {
                if MFMessageComposeViewController.canSendText() && contactManager.selectedContact != nil {
                    MessageComposerView(
                        recipients: [contactManager.selectedContact!.phoneNumber],
                        body: contactManager.messageText,
                        delegate: contactManager
                    )
                } else {
                    Text("Messaging is not available on this device")
                        .padding()
                }
            }
        }
    }
}

// MARK: - Add Emergency Contact View

struct AddEmergencyContactView: View {
    @ObservedObject var contactManager: EmergencyContactManager
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var relationshipType = "Friend"
    @State private var sendAutomaticTexts = false
    @Environment(\.presentationMode) var presentationMode
    
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
                    Toggle("Send automatic BAC updates", isOn: $sendAutomaticTexts)
                    
                    if sendAutomaticTexts {
                        Text("This contact will receive automatic text messages with your BAC when it exceeds certain thresholds.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Select from Contacts") {
                        contactManager.isShowingContactPicker = true
                        presentationMode.wrappedValue.dismiss()
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
                        contactManager.addContact(newContact)
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
    @ObservedObject var contactManager = EmergencyContactManager.shared
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
                        contactManager.callEmergencyServices()
                    },
                    .default(Text("Contact Emergency Contact")) {
                        if let firstContact = contactManager.emergencyContacts.first {
                            contactManager.callEmergencyContact(firstContact)
                        }
                    },
                    .default(Text("Send Location to Contacts")) {
                        for contact in contactManager.emergencyContacts {
                            contactManager.sendCurrentLocation(to: contact)
                        }
                    },
                    .default(Text("Get a Ride")) {
                        // This would open a rideshare view
                    },
                    .cancel()
                ]
            )
        }
    }
}
