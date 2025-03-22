//
//  DrinkLogView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI

struct DrinkLogView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var selectedDrinkType: DrinkType = .beer
    @State private var customSize: Double = 12.0
    @State private var customAlcoholPercentage: Double = 5.0
    @State private var showingCustomDrinkView = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Quick Add Section
                Section {
                    Text("Quick Add")
                        .font(.headline)
                        .padding(.top)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(DrinkType.allCases, id: \.self) { drinkType in
                                QuickAddDrinkButton(
                                    drinkType: drinkType,
                                    action: {
                                        addDefaultDrink(type: drinkType)
                                    }
                
                Section {
                    Button(action: onSave) {
                        Text("Add Drink")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(Color.blue)
                    .foregroundColor(.white)
                }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                Divider()
                
                // Custom Drink Button
                Button(action: {
                    // Pre-populate with values from selected drink type
                    selectedDrinkType = .beer
                    customSize = selectedDrinkType.defaultSize
                    customAlcoholPercentage = selectedDrinkType.defaultAlcoholPercentage
                    
                    showingCustomDrinkView = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Custom Drink")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                Spacer()
                
                // Recently Added Drinks
                RecentlyAddedDrinksView(drinks: drinkTracker.drinks, onRemove: { drink in
                    drinkTracker.removeDrink(drink)
                })
            }
            .navigationTitle("Log Drink")
            .sheet(isPresented: $showingCustomDrinkView) {
                CustomDrinkView(
                    selectedDrinkType: $selectedDrinkType,
                    size: $customSize,
                    alcoholPercentage: $customAlcoholPercentage,
                    onSave: {
                        addCustomDrink(
                            type: selectedDrinkType,
                            size: customSize,
                            alcoholPercentage: customAlcoholPercentage
                        )
                        showingCustomDrinkView = false
                    }
                )
            }
        }
    }
    
    private func addDefaultDrink(type: DrinkType) {
        drinkTracker.addDrink(
            type: type,
            size: type.defaultSize,
            alcoholPercentage: type.defaultAlcoholPercentage
        )
        
        // Give haptic feedback for successful addition
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func addCustomDrink(type: DrinkType, size: Double, alcoholPercentage: Double) {
        drinkTracker.addDrink(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage
        )
        
        // Give haptic feedback for successful addition
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct QuickAddDrinkButton: View {
    let drinkType: DrinkType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(drinkType.icon)
                    .font(.system(size: 30))
                
                Text(drinkType.rawValue)
                    .font(.caption)
                
                Text("\(String(format: "%.1f", drinkType.defaultSize)) oz, \(String(format: "%.1f", drinkType.defaultAlcoholPercentage))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 100)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct CustomDrinkView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDrinkType: DrinkType
    @Binding var size: Double
    @Binding var alcoholPercentage: Double
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Drink Type")) {
                    Picker("Type", selection: $selectedDrinkType) {
                        ForEach(DrinkType.allCases, id: \.self) { type in
                            Text("\(type.icon) \(type.rawValue)").tag(type)
                        }
                    }
                    .onChange(of: selectedDrinkType) { newValue in
                        // Update default values when drink type changes
                        size = newValue.defaultSize
                        alcoholPercentage = newValue.defaultAlcoholPercentage
                    }
                }
                
                Section(header: Text("Size")) {
                    HStack {
                        Text("\(String(format: "%.1f", size)) oz")
                            .frame(width: 60, alignment: .leading)
                        
                        Slider(value: $size, in: 1...24, step: 0.5)
                    }
                }
                
                Section(header: Text("Alcohol Percentage")) {
                    HStack {
                        Text("\(String(format: "%.1f", alcoholPercentage))%")
                            .frame(width: 60, alignment: .leading)
                        
                        Slider(value: $alcoholPercentage, in: 0.5...70, step: 0.5)
                    }
                }
                
                Section(header: Text("Equivalent To")) {
                    HStack {
                        Text("Standard Drinks:")
                        Spacer()
                        Text(String(format: "%.1f", calculateStandardDrinks()))
                            .fontWeight(.bold)
                    }
                }
