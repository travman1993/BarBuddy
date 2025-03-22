//
//  ShareView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI

struct ShareView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var selectedContacts: [Contact] = []
    @State private var customMessage: String = "Here's my current BAC."
    @State private var shareExpiration: Double = 2.0 // Hours
    @State private var isSharing: Bool = false
    @State private var activeShares: [BACShare] = [] // This would be stored/synced in a real app
    
    // Sample contacts list (would be fetched from contacts or user's friends list)
    let contacts: [Contact] = [
        Contact(id: "1", name: "Alex Smith", phone: "555-123-4567"),
        Contact(id: "2", name: "Jordan Taylor", phone: "555-987-6543"),
        Contact(id: "3", name: "Casey Johnson", phone: "555-456-7890"),
        Contact(id: "4", name: "Morgan Lee", phone: "555-789-0123")
    ]
    
    // Pre-defined message templates
    let messageTemplates = [
        "Here's my current BAC.",
        "I'm heading home soon.",
        "Just checking in with my status.",
        "I might need a ride later.",
        "I'm staying at the current venue for a while."
    ]
    
    var body: some View {
        VStack {
            if drinkTracker.currentBAC <= 0.0 {
                // No BAC to share
                EmptyStateView()
            } else {
                // BAC available to share
                ScrollView {
                    VStack(spacing: 20) {
                        // Current BAC display
                        CurrentBACView(bac: drinkTracker.currentBAC)
                        
                        // Active shares
                        if !activeShares.isEmpty {
                            ActiveSharesView(shares: activeShares)
                        }
                        
                        // Share options
                        ShareOptionsView(
                            contacts: contacts,
                            selectedContacts: $selectedContacts,
                            customMessage: $customMessage,
                            messageTemplates: messageTemplates,
                            shareExpiration: $shareExpiration
                        )
                        
                        // Share button
                        ShareButton(
                            isEnabled: !selectedContacts.isEmpty,
                            action: shareBAC
                        )
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Share Status")
    }
    
    private func shareBAC() {
        guard !selectedContacts.isEmpty else { return }
        
        // Create a new BAC share
        let newShare = BACShare(
            bac: drinkTracker.currentBAC,
            message: customMessage,
            expiresAfter: shareExpiration
        )
        
        // In a real app, this would send the share via a backend service
        // For now, we'll just add it to our local list
        activeShares.append(newShare)
        
        // Reset selection
        selectedContacts = []
        customMessage = "Here's my current BAC."
        
        // Confirmation feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// Empty state when no BAC is available
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

// Current BAC display section
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
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// Active shares list
struct ActiveSharesView: View {
    let shares: [BACShare]
    
    var activeShares: [BACShare] {
        return shares.filter { $0.isActive }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Shares")
                .font(.headline)
            
            ForEach(activeShares) { share in
                HStack {
                    VStack(alignment: .leading) {
                        Text(String(format: "BAC: %.3f", share.bac))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Expires \(expirationTimeString(for: share.expiresAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(statusColor(for: share.safetyStatus))
                        .frame(width: 12, height: 12)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func expirationTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func statusColor(for status: SafetyStatus) -> Color {
        switch status {
        case .safe: return .green
        case .borderline: return .yellow
        case .unsafe: return .red
        }
    }
}

// Share options selector
struct ShareOptionsView: View {
    let contacts: [Contact]
    @Binding var selectedContacts: [Contact]
    @Binding var customMessage: String
    let messageTemplates: [String]
    @Binding var shareExpiration: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Share With")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(contacts) { contact in
                        ContactSelectButton(
                            contact: contact,
                            isSelected: selectedContacts.contains { $0.id == contact.id },
                            action: {
                                toggleContactSelection(contact)
                            }
                        )
                    }
                }
            }
            
            Text("Message")
                .font(.headline)
                .padding(.top, 8)
            
            TextEditor(text: $customMessage)
                .frame(height: 80)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(messageTemplates, id: \.self) { template in
                        Button(action: {
                            customMessage = template
                        }) {
                            Text(template)
                                .font(.caption)
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
            }
            
            Text("Share Duration")
                .font(.headline)
                .padding(.top, 8)
            
            VStack(alignment: .leading) {
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
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func toggleContactSelection(_ contact: Contact) {
        if let index = selectedContacts.firstIndex(where: { $0.id == contact.id }) {
            selectedContacts.remove(at: index)
        } else {
            selectedContacts.append(contact)
        }
    }
    
    private func expirationTimeString(hours: Double) -> String {
        let expirationDate = Date().addingTimeInterval(hours * 3600)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "until \(formatter.string(from: expirationDate))"
    }
}

// Contact selection button
struct ContactSelectButton: View {
    let contact: Contact
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(contact.initials)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(contact.name.split(separator: " ").first ?? "")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 70)
        }
    }
}

// Share button
struct ShareButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share BAC Status")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(isEnabled ? 1.0 : 0.7)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    NavigationView {
        ShareView()
            .environmentObject(DrinkTracker())
    }
}
