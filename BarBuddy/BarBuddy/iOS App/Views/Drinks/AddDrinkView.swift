import SwiftUI

struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var bacViewModel: BACViewModel
    
    @State private var selectedType: DrinkType = .beer
    @State private var name: String = ""
    @State private var alcoholPercentage: Double = 5.0
    @State private var amount: Double = 12.0
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var isCustom: Bool = false
    @State private var isSaving: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // Quick Add Section
                Section(header: Text("Quick Add")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            QuickAddButton(type: .beer, onTap: addStandardDrink)
                            QuickAddButton(type: .wine, onTap: addStandardDrink)
                            QuickAddButton(type: .liquor, onTap: addStandardDrink)
                            QuickAddButton(type: .cocktail, onTap: addStandardDrink)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Custom Toggle
                Section {
                    Toggle("Custom Drink", isOn: $isCustom)
                        .onChange(of: isCustom) { _ in
                            updateDefaultValues()
                        }
                }
                
                // Drink Type (only show if not custom)
                if !isCustom {
                    Section(header: Text("Drink Type")) {
                        Picker("Type", selection: $selectedType) {
                            ForEach(DrinkType.allCases.filter { $0 != .custom }) { type in
                                Text(type.defaultName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedType) { _ in
                            updateDefaultValues()
                        }
                    }
                }
                
                // Custom Drink Details
                Section(header: Text("Drink Details")) {
                    if isCustom {
                        TextField("Drink Name (Optional)", text: $name)
                    }
                    
                    HStack {
                        Text("Alcohol %")
                        Spacer()
                        Text("\(alcoholPercentage, specifier: "%.1f")%")
                    }
                    
                    Slider(value: $alcoholPercentage, in: 0...60, step: 0.1)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text("\(amount, specifier: "%.1f") oz")
                    }
                    
                    Slider(value: $amount, in: 0...32, step: 0.5)
                }
                
                // Additional Info
                Section(header: Text("Additional Information")) {
                    TextField("Location (Optional)", text: $location)
                    
                    TextField("Notes (Optional)", text: $notes)
                        .lineLimit(3)
                }
                
                // Standard Drink Calculation
                Section(footer: Text("A standard drink contains about 0.6 fluid ounces (14 grams) of pure alcohol.")) {
                    HStack {
                        Text("Standard Drinks")
                        Spacer()
                        Text(standardDrinks.formatted() + " drinks")
                            .fontWeight(.semibold)
                    }
                }
                
                // BAC Estimate
                Section(header: Text("BAC Estimate")) {
                    if let predictedBAC = predictedBAC {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Current BAC:")
                                Spacer()
                                Text(bacViewModel.currentBAC.bac.bacString)
                            }
                            
                            HStack {
                                Text("After this drink:")
                                Spacer()
                                Text(predictedBAC.bac.bacString)
                                    .foregroundColor(Color.forBACLevel(predictedBAC.level))
                            }
                            
                            if predictedBAC.bac > Constants.BAC.legalLimit {
                                Text("Warning: This will put you over the legal driving limit.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add a Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDrink()
                    }
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
        .onAppear {
            updateDefaultValues()
        }
    }
    
    private var standardDrinks: Double {
        let pureAlcoholOunces = amount * (alcoholPercentage / 100)
        return (pureAlcoholOunces / 0.6).rounded(toPlaces: 1)
    }
    
    private var predictedBAC: BACEstimate? {
        let drink = Drink(
            userId: userViewModel.currentUser.id,
            type: isCustom ? .custom : selectedType,
            name: isCustom ? name : nil,
            alcoholPercentage: alcoholPercentage,
            amount: amount
        )
        
        // Only calculate if we have drinks loaded
        if !drinkViewModel.recentDrinks.isEmpty {
            return BACCalculator.predictBAC(
                user: userViewModel.currentUser,
                currentDrinks: drinkViewModel.recentDrinks,
                newDrink: drink
            )
        }
        
        return nil
    }
    
    private func updateDefaultValues() {
        if isCustom {
            // Default values for custom drink
            alcoholPercentage = 5.0
            amount = 12.0
        } else {
            // Set defaults based on selected type
            alcoholPercentage = selectedType.defaultAlcoholPercentage
            amount = selectedType.defaultAmount
        }
    }
    
    private func addStandardDrink(type: DrinkType) {
        Task {
            isSaving = true
            do {
                await drinkViewModel.addStandardDrink(
                    userId: userViewModel.currentUser.id,
                    type: type,
                    location: location.isEmpty ? nil : location
                )
                
                // Update BAC
                await bacViewModel.calculateBAC()
                
                // Dismiss the sheet
                if Task.isCancelled { return }
                dismiss()
            } catch {
                print("Error adding standard drink: \(error)")
            }
            isSaving = false
        }
    }
    
    private func saveDrink() {
        Task {
            isSaving = true
            do {
                await drinkViewModel.addDrink(
                    userId: userViewModel.currentUser.id,
                    type: isCustom ? .custom : selectedType,
                    name: isCustom && !name.isEmpty ? name : nil,
                    alcoholPercentage: alcoholPercentage,
                    amount: amount,
                    location: location.isEmpty ? nil : location,
                    notes: notes.isEmpty ? nil : notes
                )
                
                // Update BAC
                await bacViewModel.calculateBAC()
                
                // Dismiss the sheet
                if Task.isCancelled { return }
                dismiss()
            } catch {
                print("Error adding drink: \(error)")
            }
            isSaving = false
        }
    }
}

struct QuickAddButton: View {
    let type: DrinkType
    let onTap: (DrinkType) -> Void
    
    var body: some View {
        Button {
            onTap(type)
        } label: {
            VStack {
                Image(systemName: type.systemIconName)
                    .font(.title2)
                
                Text(type.defaultName)
                    .font(.caption)
            }
            .frame(width: 70, height: 70)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
        }
    }
}

struct AddDrinkView_Previews: PreviewProvider {
    static var previews: some View {
        AddDrinkView()
            .environmentObject(UserViewModel())
            .environmentObject(DrinkViewModel())
            .environmentObject(BACViewModel())
    }
}
