import SwiftUI

struct CustomDrinkForm: View {
    @Binding var drinkType: DrinkType
    @Binding var name: String
    @Binding var alcoholPercentage: Double
    @Binding var amount: Double
    @Binding var location: String
    @Binding var notes: String
    
    @State private var isEditingName = false
    @State private var isEditingLocation = false
    @State private var isEditingNotes = false
    
    var standardDrinks: Double {
        let pureAlcoholOunces = amount * (alcoholPercentage / 100)
        return (pureAlcoholOunces / 0.6).rounded(toPlaces: 1)
    }
    
    var body: some View {
        Form {
            // Drink Type
            Section(header: Text("Drink Type")) {
                Picker("Type", selection: $drinkType) {
                    ForEach(DrinkType.allCases) { type in
                        HStack {
                            Image(systemName: type.systemIconName)
                            Text(type.defaultName)
                        }.tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: drinkType) { newType in
                    if !isEditingName {
                        // Update default values when type changes
                        alcoholPercentage = newType.defaultAlcoholPercentage
                        amount = newType.defaultAmount
                    }
                }
            }
            
            // Drink Details
            Section(header: Text("Drink Details")) {
                TextField("Drink Name (Optional)", text: $name)
                    .onTapGesture {
                        isEditingName = true
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
                
                HStack {
                    Text("Standard Drinks")
                    Spacer()
                    Text("\(standardDrinks, specifier: "%.1f")")
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)
            }
            
            // Additional Info
            Section(header: Text("Additional Information")) {
                TextField("Location (Optional)", text: $location)
                    .onTapGesture {
                        isEditingLocation = true
                    }
                
                VStack(alignment: .leading) {
                    Text("Notes (Optional)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .onTapGesture {
                            isEditingNotes = true
                        }
                }
            }
            
            // Help text
            Section(footer: Text("A standard drink contains about 0.6 fluid ounces (14 grams) of pure alcohol.")) {
                EmptyView()
            }
        }
    }
}

struct CustomDrinkForm_Previews: PreviewProvider {
    static var previews: some View {
        CustomDrinkForm(
            drinkType: .constant(.beer),
            name: .constant(""),
            alcoholPercentage: .constant(5.0),
            amount: .constant(12.0),
            location: .constant(""),
            notes: .constant("")
        )
    }
}
