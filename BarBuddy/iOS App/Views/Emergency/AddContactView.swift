import SwiftUI
import Contacts

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var emergencyViewModel: EmergencyViewModel
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var isPrimary: Bool = false
    @State private var enableAutoCheckIn: Bool = true
    @State private var enableEmergencyAlerts: Bool = true
    
    @State private var isLoading: Bool = false
    @State private var showingContactPicker: Bool = false
    @State private var error: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .onChange(of: phoneNumber) { newValue in
                            // Format phone number as user types
                            phoneNumber = formatPhoneNumber(newValue)
                        }
                    
                    Button {
                        showingContactPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.blue)
                            Text("Choose from Contacts")
                        }
                    }
                }
                
                Section(header: Text("Contact Settings")) {
                    Toggle("Set as Primary Contact", isOn: $isPrimary)
                    
                    Toggle("Enable Check-in Messages", isOn: $enableAutoCheckIn)
                        .tint(.blue)
                    
                    Toggle("Enable Emergency Alerts", isOn: $enableEmergencyAlerts)
                        .tint(.blue)
                }
                
                Section(footer: Text("Your emergency contact will receive messages when you check in or send emergency alerts through the app.")) {
                    EmptyView()
                }
                
                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Emergency Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Saving contact...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(Constants.UI.cornerRadius)
                        .shadow(radius: 5)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { selectedContact in
                    if let selectedContact = selectedContact {
                        name = selectedContact.name
                        phoneNumber = selectedContact.phoneNumber
                    }
                }
            }
        }
    }
    
    private func saveContact() {
        guard !name.isEmpty, !phoneNumber.isEmpty else {
            error = "Please enter both name and phone number."
            return
        }
        
        // Clean phone number
        let cleanedPhoneNumber = phoneNumber.filter { $0.isNumber }
        guard cleanedPhoneNumber.count >= 10 else {
            error = "Please enter a valid phone number."
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                _ = try await emergencyViewModel.addContact(
                    userId: userViewModel.currentUser.id,
                    name: name,
                    phoneNumber: cleanedPhoneNumber,
                    isPrimary: isPrimary,
                    enableAutoCheckIn: enableAutoCheckIn,
                    enableEmergencyAlerts: enableEmergencyAlerts
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to save contact: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let cleanedNumber = number.filter { $0.isNumber }
        
        if cleanedNumber.count <= 3 {
            return cleanedNumber
        } else if cleanedNumber.count <= 6 {
            return "(\(cleanedNumber.prefix(3))) \(cleanedNumber.dropFirst(3))"
        } else {
            return "(\(cleanedNumber.prefix(3))) \(cleanedNumber.dropFirst(3).prefix(3))-\(cleanedNumber.dropFirst(6).prefix(4))"
        }
    }
}

// Contact picker view that integrates with system contacts
struct ContactPickerView: UIViewControllerRepresentable {
    var completion: (ContactInfo?) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = context.coordinator
        return contactPicker
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.completion(nil)
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Extract name
            let name = [contact.givenName, contact.middleName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            
            // Extract phone number
            var phoneNumber = ""
            if let phoneNumberValue = contact.phoneNumbers.first?.value {
                phoneNumber = phoneNumberValue.stringValue
            }
            
            parent.completion(ContactInfo(name: name, phoneNumber: phoneNumber))
        }
    }
    
    struct ContactInfo {
        let name: String
        let phoneNumber: String
    }
}

struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView()
            .environmentObject(UserViewModel())
            .environmentObject(EmergencyViewModel())
    }
}
