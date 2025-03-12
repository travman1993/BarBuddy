//
//  QuickAddDrinkView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI
import WatchKit

struct WatchQuickAddView: View {
    @EnvironmentObject private var drinkViewModel: WatchDrinkViewModel
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    @EnvironmentObject private var bacViewModel: WatchBACViewModel
    
    @State private var isAddingDrink = false
    @State private var showingSuccess = false
    @State private var addedDrinkType: DrinkType?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Quick Add")
                    .font(.headline)
                
                // Quick add buttons
                VStack(spacing: 12) {
                    WatchQuickAddButton(type: .beer, onTap: addDrink)
                    WatchQuickAddButton(type: .wine, onTap: addDrink)
                    WatchQuickAddButton(type: .liquor, onTap: addDrink)
                    WatchQuickAddButton(type: .cocktail, onTap: addDrink)
                }
                
                // Current BAC
                if bacViewModel.currentBAC.bac > 0 {
                    VStack(spacing: 4) {
                        Text("Current BAC: \(bacViewModel.currentBAC.bac.bacString)")
                            .font(.caption)
                        
                        Text(bacViewModel.currentBAC.timeUntilLegalFormatted)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)
                }
            }
            .padding()
            .disabled(isAddingDrink)
            .overlay {
                if isAddingDrink {
                    ProgressView("Adding...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
        }
        .navigationTitle("Add Drink")
        .alert("Drink Added", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            if let type = addedDrinkType {
                Text("\(type.defaultName) has been added.")
            } else {
                Text("Drink has been added.")
            }
        }
    }
    
    private func addDrink(type: DrinkType) {
        guard !isAddingDrink else { return }
        
        isAddingDrink = true
        addedDrinkType = type
        
        Task {
            do {
                try await drinkViewModel.addStandardDrink(
                    userId: userViewModel.currentUser.id,
                    type: type
                )
                
                await bacViewModel.refreshBAC()
                
                // Show feedback
                WKInterfaceDevice.current().play(.success)
                
                await MainActor.run {
                    isAddingDrink = false
                    showingSuccess = true
                }
            } catch {
                // Show error
                WKInterfaceDevice.current().play(.failure)
                
                await MainActor.run {
                    isAddingDrink = false
                }
            }
        }
    }
}

struct WatchQuickAddButton: View {
    let type: DrinkType
    let onTap: (DrinkType) -> Void
    
    var body: some View {
        Button {
            onTap(type)
        } label: {
            HStack {
                Image(systemName: type.systemIconName)
                    .font(.body)
                
                Text(type.defaultName)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
            }
            .padding(8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        }
    }
}
struct WatchBACView_Previews: PreviewProvider {
    static var previews: some View {
        WatchBACView()
            .environmentObject(WatchBACViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
    }
}

struct WatchQuickAddView_Previews: PreviewProvider {
    static var previews: some View {
        WatchQuickAddView()
            .environmentObject(WatchDrinkViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
            .environmentObject(WatchBACViewModel.preview)
    }
}

struct WatchMainView_Previews: PreviewProvider {
    static var previews: some View {
        WatchMainView()
            .environmentObject(WatchBACViewModel.preview)
            .environmentObject(WatchDrinkViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
    }
}
