import SwiftUI

struct EmergencyContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var emergencyViewModel: EmergencyViewModel
    
    @State private var showingAddContactSheet = false
    @State private var showingEmergencyAlertSheet = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.UI.standardPadding) {
                    // Emergency buttons
                    if !emergencyViewModel.contacts.isEmpty {
                        VStack(spacing: Constants.UI.smallPadding) {
                            // Emergency Alert button
                            Button {
                                showingEmergencyAlertSheet = true
                            } label: {
                                Label("Emergency Alert", systemImage: "exclamationmark.triangle.fill")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(Constants.UI.cornerRadius)
                            }
                            
                            // Check In button
                            Button {
                                sendCheckIn()
                            } label: {
                                Label("Send Check-In", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(Constants.UI.cornerRadius)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Contacts List
                    if emergencyViewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if emergencyViewModel.contacts.isEmpty {
                        EmptyContactsView {
                            showingAddContactSheet = true
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Your Emergency Contacts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(emergencyViewModel.contacts) { contact in
                                NavigationLink(destination: ContactDetailView(contact: contact)) {
                                    ContactRow(contact: contact)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if contact.id != emergencyViewModel.contacts.last?.id {
                                    Divider()
                                        .padding(.leading, 64)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(Constants.UI.cornerRadius)
                        .padding(.horizontal)
                    }
                    
                    // Add contact button
                    Button {
                        showingAddContactSheet = true
                    } label: {
                        Label("Add Emergency Contact", systemImage: "person.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(Constants.UI.cornerRadius)
                    }
                    .padding(.horizontal)
                    
                    // Explanation
                    if emergencyViewModel.contacts.isEmpty {
                        Text("Emergency contacts can be notified when you check in or send an emergency alert.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Emergency Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showingAddContactSheet {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddContactSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                
                if dismiss != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddContactSheet) {
                AddContactView()
            }
            .sheet(isPresented: $showingEmergencyAlertSheet) {
                EmergencyAlertView()
            }
            .refreshable {
                await loadContacts()
            }
            .onAppear {
                loadContacts()
            }
        }
    }
    
    private func loadContacts() async {
        isLoading = true
        await emergencyViewModel.loadContacts(userId: userViewModel.currentUser.id)
        isLoading = false
    }
    
    private func loadContacts() {
        Task {
            await loadContacts()
        }
    }
    
    private func sendCheckIn() {
        Task {
            try? await emergencyViewModel.sendCheckInMessage(
                userId: userViewModel.currentUser.id,
                userName: userViewModel.currentUser.name ?? "User"
            )
        }
    }
}

struct ContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Text(initials)
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            // Contact info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                    
                    if contact.isPrimary {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Text(contact.formattedPhoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Call button
            Button {
                callContact()
            } label: {
                Image(systemName: "phone.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.green))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
    
    private var initials: String {
        let words = contact.name.components(separatedBy: .whitespacesAndNewlines)
        let letters = words.compactMap { $0.first }
        
        if letters.isEmpty {
            return "?"
        } else if letters.count == 1 {
            return String(letters[0]).uppercased()
        } else {
            return String(letters[0]) + String(letters[1])
        }
    }
    
    private func callContact() {
            guard let url = URL(string: "tel://\(contact.phoneNumber.filter { $0.isNumber })") else { return }
            UIApplication.shared.open(url)
        }
    }

    struct EmptyContactsView: View {
        let action: () -> Void
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No Emergency Contacts")
                    .font(.headline)
                
                Text("Add emergency contacts who can be notified in case you need help.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: action) {
                    Text("Add Your First Contact")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.cornerRadius)
                }
                .padding(.top)
            }
            .padding()
        }
    }

    struct EmergencyContactsView_Previews: PreviewProvider {
        static var previews: some View {
            EmergencyContactsView()
                .environmentObject(UserViewModel())
                .environmentObject({
                    let viewModel = EmergencyViewModel()
                    viewModel.contacts = [
                        EmergencyContact.example,
                        EmergencyContact(
                            userId: "example",
                            name: "John Smith",
                            phoneNumber: "5551234567"
                        )
                    ]
                    return viewModel
                }())
        }
    }
