//
//  DrinkOptionsView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

struct DrinkOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var drinkViewModel: WatchDrinkViewModel
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    @EnvironmentObject private var bacViewModel: WatchBACViewModel
    
    @State private var selectedType: DrinkType = .beer
    @State private var isAddingDrink = false
    @State private var showingConfirmation = false
    
    var body: some View {
        List {
            ForEach(DrinkType.allCases.filter { $0 != .custom }) { type in
                Button {
                    selectedType = type
                    addSelectedDrink()
                } label: {
                    HStack {
                        Image(systemName: type.systemIconName)
                            .foregroundColor(.blue)
                        
                        Text(type.defaultName)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(type.defaultAlcoholPercentage, specifier: "%.1f")%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(isAddingDrink)
            }
        }
        .navigationTitle("Select Drink")
        .overlay {
            if isAddingDrink {
                ProgressView("Adding...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            }
        }
        .alert("Drink Added", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(selectedType.defaultName) has been added.")
        }
    }
    
    private func addSelectedDrink() {
        guard !isAddingDrink else { return }
        
        isAddingDrink = true
        
        Task {
            do {
                try await drinkViewModel.addStandardDrink(
                    userId: userViewModel.currentUser.id,
                    type: selectedType
                )
                
                await bacViewModel.refreshBAC()
                
                // Show feedback
                WKInterfaceDevice.current().play(.success)
                
                await MainActor.run {
                    isAddingDrink = false
                    showingConfirmation = true
                }
            } catch {
                WKInterfaceDevice.current().play(.failure)
                
                await MainActor.run {
                    isAddingDrink = false
                }
            }
        }
    }
}
