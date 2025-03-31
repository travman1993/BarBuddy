//
//  ShareView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
#if os(iOS)
import SwiftUI
import Contacts
import MessageUI

struct ShareView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @StateObject private var shareManager = ShareManager()
    @State private var messageDelegate = ShareViewMessageDelegate()
    @State private var selectedContacts: [Contact] = []
    @State private var customMessage: String = "Here's my current BAC."
    @State private var shareExpiration: Double = 2.0
    @State private var includeLocation = false
    @State private var showingShareOptions = false
    @State private var showingQRCode = false
    @State private var selectedShareOption: ShareOption = .text
    @State private var showingSavedShares = false
    @State private var showingMessageComposer = false
    
    enum ShareOption {
        case text, email, qrCode, url
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current BAC display
                CurrentBACView(bac: drinkTracker.currentBAC)
                    .padding(.horizontal)
                
                if drinkTracker.currentBAC <= 0.0 {
                    // No BAC to share
                    EmptyStateView()
                } else {
                    // Active shares
                    if !shareManager.activeShares.isEmpty {
                        Button(action: {
                            showingSavedShares = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                Text("\(shareManager.activeShares.count) Active Shares")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Share content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share Message")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Updated message composer button
                        Button(action: {
                            showingMessageComposer = true
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Compose Message")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showingMessageComposer) {
                            if MFMessageComposeViewController.canSendText() {
                                let phoneNumbers = selectedContacts.map { $0.phone }
                                MessageComposerView(
                                    recipients: phoneNumbers,
                                    body: createFullShareMessage(),
                                    delegate: messageDelegate
                                )
                            } else {
                                Text("SMS services are not available on this device")
                                    .padding()
                            }
                        }
                        
                        // Message templates
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(shareManager.messageTemplates, id: \.self) { template in
                                    Button(action: {
                                        customMessage = template
                                    }) {
                                        Text(template)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(customMessage == template ? Color.blue : Color.gray.opacity(0.2))
                                            )
                                            .foregroundColor(customMessage == template ? .white : .primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Location toggle
                        Toggle(isOn: $includeLocation) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text("Include my current location")
                            }
                        }
                        .padding(.horizontal)
                        
                        // Share duration
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share will expire after:")
                                .font(.headline)
                            
                            HStack {
                                Text("\(Int(shareExpiration)) hours")
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text(expirationTimeString(hours: shareExpiration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $shareExpiration, in: 1...24, step: 1)
                        }
                        .padding(.horizontal)
                        
                        // Share buttons
                        HStack {
                            ShareOptionButton(
                                title: "Text",
                                systemImage: "message.fill",
                                color: .green,
                                isSelected: selectedShareOption == .text
                            ) {
                                selectedShareOption = .text
                                showingShareOptions = true
                            }
                            
                            ShareOptionButton(
                                title: "Email",
                                systemImage: "envelope.fill",
                                color: .blue,
                                isSelected: selectedShareOption == .email
                            ) {
                                selectedShareOption = .email
                                showingShareOptions = true
                            }
                            
                            ShareOptionButton(
                                title: "QR Code",
                                systemImage: "qrcode",
                                color: .purple,
                                isSelected: selectedShareOption == .qrCode
                            ) {
                                selectedShareOption = .qrCode
                                showingQRCode = true
                            }
                            
                            ShareOptionButton(
                                title: "Link",
                                systemImage: "link",
                                color: .orange,
                                isSelected: selectedShareOption == .url
                            ) {
                                selectedShareOption = .url
                                shareViaLink()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Emergency contacts
                    let emergencyManager = EmergencyContactManager.shared
                    if !emergencyManager.emergencyContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Share with Emergency Contacts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(emergencyManager.emergencyContacts) { contact in
                                        Button(action: {
                                            shareWithEmergencyContact(contact)
                                        }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.2))
                                                        .frame(width: 60, height: 60)
                                                    
                                                    Text(getInitials(from: contact.name))
                                                        .font(.title2)
                                                        .fontWeight(.semibold)
                                                }
                                                
                                                Text(contact.name.split(separator: " ").first?.description ?? "")
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .navigationTitle("Share Status")
            .sheet(isPresented: $showingShareOptions) {
                switch selectedShareOption {
                case .text:
                    ContactSelectionView(
                        shareManager: shareManager,
                        selectedContacts: $selectedContacts,
                        onShare: { contacts in
                            shareViaText(with: contacts)
                        }
                    )
                case .email:
                    EmailShareView(
                        bac: drinkTracker.currentBAC,
                        message: customMessage,
                        timeUntilSober: drinkTracker.timeUntilSober,
                        includeLocation: includeLocation
                    )
                default:
                    EmptyView()
                }
            }
            .sheet(isPresented: $showingQRCode) {
                QRCodeShareView(
                    bac: drinkTracker.currentBAC,
                    message: customMessage,
                    timeUntilSober: drinkTracker.timeUntilSober,
                    includeLocation: includeLocation
                )
            }
            .sheet(isPresented: $showingSavedShares) {
                ActiveSharesView(shareManager: shareManager)
            }
        }
    }
    
    // Format expiration time
    private func expirationTimeString(hours: Double) -> String {
        let expirationDate = Date().addingTimeInterval(hours * 3600)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "until \(formatter.string(from: expirationDate))"
    }
    
    // Share via text message
    private func shareViaText(with contacts: [Contact]) {
        guard !contacts.isEmpty else { return }
        
        showingMessageComposer = true
        selectedContacts = contacts
        
        // Create a new share record
        let share = BACShare(
            bac: drinkTracker.currentBAC,
            message: customMessage,
            expiresAfter: shareExpiration
        )
        shareManager.addShare(share)
    }
    
    // Share via link (would generate a unique URL in a real app)
    private func shareViaLink() {
        let fullMessage = createFullShareMessage()
        
        // In a real app, this would generate a unique URL to a web page with the BAC info
        // For now, we'll just share the text directly
        let activityVC = UIActivityViewController(
            activityItems: [fullMessage],
            applicationActivities: nil
        )
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    // Share with emergency contact
    private func shareWithEmergencyContact(_ contact: EmergencyContact) {
        let fullMessage = createFullShareMessage()
        
        // Create a new share record
        let share = BACShare(
            bac: drinkTracker.currentBAC,
            message: customMessage,
            expiresAfter: shareExpiration
        )
        shareManager.addShare(share)
        
        // Send message to emergency contact
        EmergencyContactManager.shared.sendCustomMessage(to: contact, message: fullMessage)
    }
    
    // Create the full share message
    private func createFullShareMessage() -> String {
        let bacString = String(format: "%.3f", drinkTracker.currentBAC)
        
        var fullMessage = customMessage.contains("%BAC%")
            ? customMessage.replacingOccurrences(of: "%BAC%", with: bacString)
            : "\(customMessage)\n\nMy current BAC is \(bacString)."
        
        // Add time until sober if available
        if drinkTracker.timeUntilSober > 0 {
            let hours = Int(drinkTracker.timeUntilSober) / 3600
            let minutes = (Int(drinkTracker.timeUntilSober) % 3600) / 60
            let timeString = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes) minutes"
            
            fullMessage += "\nEstimated time until sober: \(timeString)"
        }
        
        // Add location if enabled
        if includeLocation {
            // In a real app, this would include actual GPS coordinates or a map link
            fullMessage += "\n\nShared from BarBuddy App (with location)"
        } else {
            fullMessage += "\n\nShared from BarBuddy App"
        }
        
        return fullMessage
    }
    
    // Get initials from a name
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2,
           let first = components.first?.first,
           let last = components.last?.first {
            return String(first) + String(last)
        } else if let first = components.first?.first {
            return String(first)
        }
        return "?"
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wineglass")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No BAC to Share")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Log a drink first to share your BAC status with friends.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Current BAC View
struct CurrentBACView: View {
    let bac: Double
    
    var safetyStatus: SafetyStatus {
        if bac < 0.04 {
            return .safe
        } else if bac < 0.08 {
            return .borderline
        } else {
            return .unsafe
        }
    }
    
    var statusColor: Color {
        switch safetyStatus {
        case .safe: return .green
        case .borderline: return .yellow
        case .unsafe: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Current BAC")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.3f", bac))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(statusColor)
            
            Text(safetyStatus.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Message Composer View
struct BACMessageComposerView: View {
    @Binding var message: String
    let bac: Double
    let timeUntilSober: TimeInterval
    
    var placeholderText: String {
        "Type a message to share with your BAC status. Use %BAC% to insert your BAC value."
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text(placeholderText)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .foregroundColor(.gray)
                }
                
                TextEditor(text: $message)
                    .frame(minHeight: 100)
                    .padding(5)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            Text("Your message will include your current BAC (\(String(format: "%.3f", bac))) and safety status.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Share Option Button
struct ShareOptionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Contact Selection View
struct ContactSelectionView: View {
    @ObservedObject var shareManager: ShareManager
    @Binding var selectedContacts: [Contact]
    @Environment(\.presentationMode) var presentationMode
    let onShare: ([Contact]) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(shareManager.contacts) { contact in
                        ContactRow(
                            contact: contact,
                            isSelected: selectedContacts.contains(where: { $0.id == contact.id }),
                            onToggle: { toggleContact(contact) }
                        )
                    }
                }
                
                Button(action: {
                    onShare(selectedContacts)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Share with \(selectedContacts.count) Contact\(selectedContacts.count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedContacts.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(selectedContacts.isEmpty)
                .padding(.bottom)
            }
            .navigationTitle("Select Contacts")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func toggleContact(_ contact: Contact) {
        if let index = selectedContacts.firstIndex(where: { $0.id == contact.id }) {
            selectedContacts.remove(at: index)
        } else {
            selectedContacts.append(contact)
        }
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    let contact: Contact
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(contact.initials)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                VStack(alignment: .leading) {
                    Text(contact.name)
                        .font(.headline)
                    
                    Text(contact.phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Email Share View
struct EmailShareView: View {
    let bac: Double
    let message: String
    let timeUntilSober: TimeInterval
    let includeLocation: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var recipients: String = ""
    @State private var subject: String = "My BAC Status from BarBuddy"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipients")) {
                    TextField("Email addresses (separated by comma)", text: $recipients)
                        .keyboardType(.emailAddress)
                }
                
                Section(header: Text("Email Content")) {
                    TextField("Subject", text: $subject)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message Preview")
                            .font(.headline)
                            .padding(.vertical, 5)
                        
                        Text(formattedEmailMessage)
                            .font(.body)
                    }
                    .padding(.vertical, 5)
                }
                
                Section {
                    Button(action: sendEmail) {
                        HStack {
                            Spacer()
                            Text("Send Email")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Email BAC Status")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    var formattedEmailMessage: String {
        let bacString = String(format: "%.3f", bac)
        
        var fullMessage = message.contains("%BAC%")
            ? message.replacingOccurrences(of: "%BAC%", with: bacString)
            : "\(message)\n\nMy current BAC is \(bacString)."
        
        if timeUntilSober > 0 {
            let hours = Int(timeUntilSober) / 3600
            let minutes = (Int(timeUntilSober) % 3600) / 60
            let timeString = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes) minutes"
            
            fullMessage += "\nEstimated time until sober: \(timeString)"
        }
        
        if includeLocation {
            fullMessage += "\n\nMy current location: [Location would be included here]"
        }
        
        fullMessage += "\n\nThis was shared from the BarBuddy app."
        
        return fullMessage
    }
    
    private func sendEmail() {
        // In a real app, this would use MFMailComposeViewController
        // or share a mailto: URL
        
        let emailString = "mailto:\(recipients)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(formattedEmailMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: emailString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - QR Code Share View
struct QRCodeShareView: View {
    let bac: Double
    let message: String
    let timeUntilSober: TimeInterval
    let includeLocation: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Scan this QR code to view my BAC status")
                    .font(.headline)
                
                if let qrImage = generateQRCode() {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                } else {
                    Text("Unable to generate QR code")
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("BAC Status: \(String(format: "%.3f", bac))")
                        .font(.headline)
                    
                    if timeUntilSober > 0 {
                        let hours = Int(timeUntilSober) / 3600
                        let minutes = (Int(timeUntilSober) % 3600) / 60
                        
                        Text("Time until sober: \(hours)h \(minutes)m")
                    }
                    
                    Text(message)
                        .font(.body)
                        .padding(.top, 5)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: shareQRCode) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share QR Code")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("QR Code Share")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func generateQRCode() -> UIImage? {
        let data = qrCodeData.data(using: .utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("H", forKey: "inputCorrectionLevel")
            
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                
                if let cgImage = CIContext().createCGImage(scaledImage, from: scaledImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
    
    var qrCodeData: String {
        let bacString = String(format: "%.3f", bac)
        
        var qrData = "BAC: \(bacString)\n"
        
        if timeUntilSober > 0 {
            let hours = Int(timeUntilSober) / 3600
            let minutes = (Int(timeUntilSober) % 3600) / 60
            qrData += "Time until sober: \(hours)h \(minutes)m\n"
        }
        
        qrData += "Message: \(message)\n"
        
        if includeLocation {
            qrData += "Location: [Location would be included here]\n"
        }
        
        qrData += "Shared from BarBuddy App"
        
        return qrData
    }
    
    private func shareQRCode() {
        if let qrImage = generateQRCode() {
            let activityVC = UIActivityViewController(
                activityItems: [qrImage],
                applicationActivities: nil
            )
            
            // Present the activity view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
}

// MARK: - Active Shares View
struct ActiveSharesView: View {
    @ObservedObject var shareManager: ShareManager
    @Environment(\.presentationMode) var presentationMode
    
    var activeShares: [BACShare] {
        return shareManager.activeShares.filter { $0.isActive }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(activeShares) { share in
                    ActiveShareRow(share: share)
                }
                .onDelete { indexSet in
                    let sharesToDelete = indexSet.map { activeShares[$0] }
                    for share in sharesToDelete {
                        shareManager.removeShare(share)
                    }
                }
                
                if activeShares.isEmpty {
                    Text("No active shares")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .navigationTitle("Active Shares")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Active Share Row
struct ActiveShareRow: View {
    let share: BACShare
    
    // Private method to get color based on safety status
    private func statusColor(for status: SafetyStatus) -> Color {
        switch status {
        case .safe: return .green
        case .borderline: return .yellow
        case .unsafe: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BAC: \(String(format: "%.3f", share.bac))")
                    .font(.headline)
                    .foregroundColor(statusColor(for: share.safetyStatus))
                
                Spacer()
                
                Text(timeAgo(share.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(share.message)
                .font(.subheadline)
                .lineLimit(2)
            
            HStack {
                Text("Expires \(expirationTimeString(for: share.expiresAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                StatusBadge(status: share.safetyStatus)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func expirationTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
    // MARK: - Status Badge
    struct StatusBadge: View {
        let status: SafetyStatus
        
        var body: some View {
            Text(status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .cornerRadius(8)
        }
        
        var backgroundColor: Color {
            switch status {
            case .safe: return .green.opacity(0.2)
            case .borderline: return .yellow.opacity(0.2)
            case .unsafe: return .red.opacity(0.2)
            }
        }
        
        var textColor: Color {
            switch status {
            case .safe: return .green
            case .borderline: return .yellow
            case .unsafe: return .red
            }
        }
    }

    // MARK: - Share Manager
    class ShareManager: ObservableObject {
        @Published var activeShares: [BACShare] = []
        @Published var contacts: [Contact] = []
        
        // Message templates
        let messageTemplates = [
            "Here's my current BAC.",
            "I'm heading home soon.",
            "Just checking in with my status.",
            "I might need a ride later.",
            "I'm staying at the current venue for a while."
        ]
        
        init() {
            loadShares()
            loadContacts()
        }
        
        // MARK: - Shares Management
        
        func loadShares() {
            if let data = UserDefaults.standard.data(forKey: "activeShares") {
                if let decoded = try? JSONDecoder().decode([BACShare].self, from: data) {
                    self.activeShares = decoded.filter { $0.isActive }
                }
            }
        }
        
        func saveShares() {
            if let encoded = try? JSONEncoder().encode(activeShares) {
                UserDefaults.standard.set(encoded, forKey: "activeShares")
            }
        }
        
        func addShare(_ share: BACShare) {
            activeShares.append(share)
            saveShares()
        }
        
        func removeShare(_ share: BACShare) {
            activeShares.removeAll { $0.id == share.id }
            saveShares()
        }
        
        // MARK: - Contacts Management
        
        func loadContacts() {
            // In a real app, this would load from the user's contacts
            // For now, we'll use sample data
            contacts = [
                Contact(id: "1", name: "Alex Smith", phone: "555-123-4567"),
                Contact(id: "2", name: "Jordan Taylor", phone: "555-987-6543"),
                Contact(id: "3", name: "Casey Johnson", phone: "555-456-7890"),
                Contact(id: "4", name: "Morgan Lee", phone: "555-789-0123")
            ]
        }
        
        // MARK: - Messaging
        
        func sendTextMessage(to recipients: [String], message: String) {
            // Print the message (for debugging)
            print("Sending to: \(recipients.joined(separator: ", "))")
            print("Message: \(message)")
        }
    }

#endif
