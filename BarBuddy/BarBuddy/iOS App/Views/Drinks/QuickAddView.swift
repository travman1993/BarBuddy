import SwiftUI

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var bacViewModel: BACViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @State private var selectedDrinkType: DrinkType = .beer
    @State private var isLoading = false
    @State private var showingConfirmation = false
    @State private var addedDrink: Drink?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.UI.largePadding) {
                    // Title
                    Text("Quick Add a Drink")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    
                    // Drink types grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Constants.UI.standardPadding) {
                        ForEach(DrinkType.allCases.filter { $0 != .custom }) { type in
                            DrinkTypeCard(
                                type: type,
                                isSelected: selectedDrinkType == type,
                                onTap: {
                                    selectedDrinkType = type
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Drink details preview
                    DrinkPreviewCard(drinkType: selectedDrinkType)
                    
                    // Add button
                    Button {
                        addStandardDrink()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Add \(selectedDrinkType.defaultName)")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
                    .padding(.horizontal)
                    .disabled(isLoading)
                    
                    // Cancel button
                    Button("Cancel") {
                        dismiss()
                    }
                    .padding()
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .alert("Drink Added", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let drink = addedDrink {
                Text("\(drink.type.defaultName) added. Your BAC has been updated.")
            }
        }
    }
    
    private func addStandardDrink() {
        isLoading = true
        
        Task {
            do {
                await drinkViewModel.addStandardDrink(
                    userId: userViewModel.currentUser.id,
                    type: selectedDrinkType
                )
                
                // Update BAC
                await bacViewModel.calculateBAC()
                
                // Create a representation of the drink that was added
                addedDrink = Drink(
                    userId: userViewModel.currentUser.id,
                    type: selectedDrinkType,
                    alcoholPercentage: selectedDrinkType.defaultAlcoholPercentage,
                    amount: selectedDrinkType.defaultAmount
                )
                
                await MainActor.run {
                    isLoading = false
                    showingConfirmation = true
                }
            } catch {
                print("Error adding drink: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct DrinkTypeCard: View {
    let type: DrinkType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: type.systemIconName)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.defaultName)
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(type.defaultAlcoholPercentage, specifier: "%.1f")% • \(type.defaultAmount, specifier: "%.1f") oz")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DrinkPreviewCard: View {
    let drinkType: DrinkType
    
    private var standardDrinks: Double {
        let pureAlcoholOunces = drinkType.defaultAmount * (drinkType.defaultAlcoholPercentage / 100)
        return (pureAlcoholOunces / 0.6).rounded(toPlaces: 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drink Details")
                .font(.headline)
                .padding(.bottom, 4)
            
            DetailRow(label: "Type", value: drinkType.defaultName, icon: drinkType.systemIconName)
            DetailRow(label: "Alcohol", value: "\(drinkType.defaultAlcoholPercentage, specifier: "%.1f")%", icon: "percent")
            DetailRow(label: "Amount", value: "\(drinkType.defaultAmount, specifier: "%.1f") oz", icon: "drop.fill")
            DetailRow(label: "Standard Drinks", value: "\(standardDrinks, specifier: "%.1f")", icon: "mug.fill")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .padding(.horizontal)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct QuickAddView_Previews: PreviewProvider {
    static var previews: some View {
        QuickAddView()
            .environmentObject(UserViewModel())
            .environmentObject(DrinkViewModel())
            .environmentObject(BACViewModel())
            .environmentObject(SettingsViewModel())
    }
}
