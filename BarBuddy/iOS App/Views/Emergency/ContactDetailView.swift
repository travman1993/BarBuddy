import SwiftUI

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var emergencyViewModel: EmergencyViewModel
    
    let contact: EmergencyContact
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var isPrimary: Bool
    @State private var enableAutoCheckIn: Bool
    @State private var enableEmergencyAlerts: Bool
    
    @State private var isLoading: Bool = false
    @State private var isEditMode: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var error: String? = nil
    
    init(contact: EmergencyContact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phoneNumber = State(initialValue: contact.phoneNumber)
        _isPrimary = State(initialValue: contact.isPrimary)
        _enableAutoCheckIn = State(initialValue: contact.enableAutoCheckIn)
        _enableEmergencyAlerts = State(initialValue: contact.enableEmergencyAlerts)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.standardPadding) {
                // Contact Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Text(nameInitials)
                        .font(.system(size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding(.top)
                
                // Contact Name
                if isEditMode {
                    TextField("Name", text: $name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, Constants.UI.largePadding)
                } else {
                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // Contact Info
                VStack(spacing: Constants.UI.smallPadding) {
                    // Phone number
                    ContactInfoRow(
                        icon: "phone.fill",
                        title: "Phone",
                        value: isEditMode ? $phoneNumber : .constant(contact.formattedPhoneNumber),
                        isEditable: isEditMode
                    )
                    
                    // Primary status
                    ContactToggleRow(
                        icon: "star.fill",
                        title: "Primary Contact",
                        isOn: $isPrimary,
                        isEditable: isEditMode
                    )
                    
                    // Check-in status
                    ContactToggleRow(
                        icon: "checkmark.circle.fill",
                        title: "Check-in Messages",
                        isOn: $enableAutoCheckIn,
                        isEditable: isEditMode
                    )
                    
                    // Emergency alerts
                    ContactToggleRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Emergency Alerts",
                        isOn: $enableEmergencyAlerts,
                        isEditable: isEditMode
                    )
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
                .padding(.horizontal)
                
                // Call and Message Buttons
                HStack(spacing: Constants.UI.standardPadding) {
                    // Call button
                    Button {
                        callContact()
                    } label: {
                        Label("Call", systemImage: "phone.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(Constants.UI.cornerRadius)
                    }
                    
                    // Message button
                    Button {
                        messageContact()
                    } label: {
                        Label("Message", systemImage: "message.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(Constants.UI.cornerRadius)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                if isEditMode {
                    // Delete button
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Contact", systemImage: "trash")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(Constants.UI.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                }
                
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .padding(.vertical)
            .disabled(isLoading)
        }
        .navigationTitle("Contact Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditMode ? "Save" : "Edit") {
                    if isEditMode {
                        saveChanges()
                    } else {
                        isEditMode = true
                    }
                }
                .disabled(isLoading)
            }
            
            if isEditMode {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Reset to original values
                        name = contact.name
                        phoneNumber = contact.phoneNumber
                        isPrimary = contact.isPrimary
                        enableAutoCheckIn = contact.enableAutoCheckIn
                        enableEmergencyAlerts = contact.enableEmergencyAlerts
                        
                        isEditMode = false
                    }
                    .disabled(isLoading)
                }
            }
        }
        .alert("Delete Contact?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteContact()
            }
        } message: {
            Text("Are you sure you want to delete this emergency contact?")
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
    }
    
    private var nameInitials: String {
        let words = name.components(separatedBy: .whitespacesAndNewlines)
        let initials = words.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    private func saveChanges() {
        // Validate inputs
        guard !name.isEmpty else {
            error = "Name cannot be empty"
            return
        }
        
        let cleanedPhoneNumber = phoneNumber.filter { $0.isNumber }
        guard cleanedPhoneNumber.count >= 10 else {
            error = "Please enter a valid phone number"
            return
        }
        
        isLoading = true
        error = nil
        
        // Update contact
        var updatedContact = contact
        updatedContact.name = name
        updatedContact.phoneNumber = cleanedPhoneNumber
        updatedContact.isPrimary = isPrimary
        updatedContact.enableAutoCheckIn = enableAutoCheckIn
        updatedContact.enableEmergencyAlerts = enableEmergencyAlerts
        updatedContact.updatedAt = Date()
        
        Task {
            do {
                try await emergencyViewModel.updateContact(contact: updatedContact)
                
                await MainActor.run {
                    isLoading = false
                    isEditMode = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to save changes: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteContact() {
        isLoading = true
        
        Task {
            do {
                try await emergencyViewModel.deleteContact(id: contact.id, userId: userViewModel.currentUser.id)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to delete contact: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func callContact() {
        guard let url = URL(string: "tel://\(phoneNumber.filter { $0.isNumber })") else { return }
        UIApplication.shared.open(url)
    }
    
    private func messageContact() {
        guard let url = URL(string: "sms://\(phoneNumber.filter { $0.isNumber })") else { return }
        UIApplication.shared.open(url)
    }
}

struct ContactInfoRow: View {
    let icon: String
    let title: String
    @Binding var value: String
    var isEditable: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isEditable {
                TextField("", text: $value)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(title == "Phone" ? .phonePad : .default)
            } else {
                Text(value)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ContactToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    var isEditable: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isEditable {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            } else {
                Image(systemName: isOn ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isOn ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContactDetailView(contact: EmergencyContact.example)
                .environmentObject(UserViewModel())
                .environmentObject(EmergencyViewModel())
        }
    }
}
