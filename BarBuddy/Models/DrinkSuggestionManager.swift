//
//  DrinkSuggestionManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import SwiftUI
import Combine

class DrinkSuggestionManager: ObservableObject {
    static let shared = DrinkSuggestionManager()
    
    @EnvironmentObject var drinkTracker: DrinkTracker

    @Published var preferredDrinkTypes: [DrinkType] = []
    @Published var showLowAlcoholSuggestions: Bool = false
    @Published var showHydrationReminders: Bool = true
    @Published var showModerateOptions: Bool = true
    
    // Suggested drinks based
    struct DrinkSuggestion: Identifiable, Hashable {
        let id = UUID()
        
        let name: String
        let type: DrinkType
        let alcoholPercentage: Double
        let isNonAlcoholic: Bool
        let size: Double
        let standardDrinks: Double
        let emoji: String
        let description: String
        let ingredients: [String]?
        
        var formattedSize: String {
            return "\(Int(size)) oz"
        }
        
        // Add hash and equals for proper uniqueness in collections
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: DrinkSuggestion, rhs: DrinkSuggestion) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // Predefined suggestions
    private let nonAlcoholicOptions: [DrinkSuggestion] = [
        DrinkSuggestion(
            name: "Water",
            type: .other,
            alcoholPercentage: 0,
            isNonAlcoholic: true,
            size: 16,
            standardDrinks: 0,
            emoji: "💧",
            description: "Stay hydrated to help process alcohol and avoid hangovers.",
            ingredients: ["Water"]
        ),
        DrinkSuggestion(
            name: "Club Soda",
            type: .other,
            alcoholPercentage: 0,
            isNonAlcoholic: true,
            size: 12,
            standardDrinks: 0,
            emoji: "🥤",
            description: "Refreshing and bubbly without the alcohol.",
            ingredients: ["Carbonated water"]
        ),
        DrinkSuggestion(
            name: "Virgin Mojito",
            type: .cocktail,
            alcoholPercentage: 0,
            isNonAlcoholic: true,
            size: 12,
            standardDrinks: 0,
            emoji: "🍃",
            description: "Refreshing mint and lime drink without the rum.",
            ingredients: ["Lime juice", "Mint leaves", "Sugar", "Club soda"]
        ),
        DrinkSuggestion(
            name: "Shirley Temple",
            type: .cocktail,
            alcoholPercentage: 0,
            isNonAlcoholic: true,
            size: 12,
            standardDrinks: 0,
            emoji: "🍒",
            description: "Classic non-alcoholic cocktail with grenadine.",
            ingredients: ["Ginger ale", "Grenadine", "Maraschino cherry"]
        ),
        DrinkSuggestion(
            name: "Kombucha",
            type: .other,
            alcoholPercentage: 0.5,
            isNonAlcoholic: true,
            size: 12,
            standardDrinks: 0,
            emoji: "🍵",
            description: "Fermented tea with probiotics and very minimal alcohol.",
            ingredients: ["Fermented tea", "Probiotics", "Fruit flavors"]
        )
    ]
    
    private let lowAlcoholOptions: [DrinkSuggestion] = [
        DrinkSuggestion(
            name: "Light Beer",
            type: .beer,
            alcoholPercentage: 3.5,
            isNonAlcoholic: false,
            size: 12,
            standardDrinks: 0.7,
            emoji: "🍺",
            description: "Lower alcohol beer to pace your drinking.",
            ingredients: ["Malted barley", "Hops", "Water", "Yeast"]
        ),
        DrinkSuggestion(
            name: "Radler/Shandy",
            type: .beer,
            alcoholPercentage: 2.5,
            isNonAlcoholic: false,
            size: 12,
            standardDrinks: 0.5,
            emoji: "🍋",
            description: "Beer mixed with lemonade or citrus soda.",
            ingredients: ["Beer", "Lemonade or citrus soda"]
        ),
        DrinkSuggestion(
            name: "White Wine Spritzer",
            type: .wine,
            alcoholPercentage: 6.0,
            isNonAlcoholic: false,
            size: 6,
            standardDrinks: 0.6,
            emoji: "🥂",
            description: "White wine diluted with soda water.",
            ingredients: ["White wine", "Club soda", "Optional citrus"]
        ),
        DrinkSuggestion(
            name: "Aperol Spritz",
            type: .cocktail,
            alcoholPercentage: 8.0,
            isNonAlcoholic: false,
            size: 8,
            standardDrinks: 1.0,
            emoji: "🧡",
            description: "Classic Italian aperitif with prosecco and soda water.",
            ingredients: ["Aperol", "Prosecco", "Club soda", "Orange slice"]
        ),
        DrinkSuggestion(
            name: "Campari & Soda",
            type: .cocktail,
            alcoholPercentage: 7.0,
            isNonAlcoholic: false,
            size: 6,
            standardDrinks: 0.7,
            emoji: "🔴",
            description: "Bitter Italian aperitif with soda water.",
            ingredients: ["Campari", "Club soda", "Optional citrus"]
        )
    ]
    
    private let moderateOptions: [DrinkSuggestion] = [
        DrinkSuggestion(
            name: "Standard Beer",
            type: .beer,
            alcoholPercentage: 5.0,
            isNonAlcoholic: false,
            size: 12,
            standardDrinks: 1.0,
            emoji: "🍺",
            description: "Regular beer with balanced flavor.",
            ingredients: ["Malted barley", "Hops", "Water", "Yeast"]
        ),
        DrinkSuggestion(
            name: "Glass of Wine",
            type: .wine,
            alcoholPercentage: 12.0,
            isNonAlcoholic: false,
            size: 5,
            standardDrinks: 1.0,
            emoji: "🍷",
            description: "Standard serving of wine.",
            ingredients: ["Fermented grapes"]
        ),
        DrinkSuggestion(
            name: "Moscow Mule",
            type: .cocktail,
            alcoholPercentage: 10.0,
            isNonAlcoholic: false,
            size: 8,
            standardDrinks: 1.3,
            emoji: "🥃",
            description: "Refreshing ginger and vodka drink.",
            ingredients: ["Vodka", "Ginger beer", "Lime juice"]
        ),
        DrinkSuggestion(
            name: "Tom Collins",
            type: .cocktail,
            alcoholPercentage: 10.0,
            isNonAlcoholic: false,
            size: 8,
            standardDrinks: 1.3,
            emoji: "🍋",
            description: "Classic gin cocktail with lemon and soda.",
            ingredients: ["Gin", "Lemon juice", "Simple syrup", "Club soda"]
        ),
        DrinkSuggestion(
            name: "Vodka Soda",
            type: .cocktail,
            alcoholPercentage: 12.0,
            isNonAlcoholic: false,
            size: 6,
            standardDrinks: 1.2,
            emoji: "🥂",
            description: "Simple mixed drink with fewer calories.",
            ingredients: ["Vodka", "Club soda", "Lime"]
        )
    ]
    
    
    
    init() {
        loadPreferences()
    }
    
    // MARK: - Preferences Management
    
    func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "preferredDrinkTypes") {
            if let decoded = try? JSONDecoder().decode([DrinkType].self, from: data) {
                self.preferredDrinkTypes = decoded
            }
        }
        
        showLowAlcoholSuggestions = UserDefaults.standard.bool(forKey: "showLowAlcoholSuggestions")
        showHydrationReminders = UserDefaults.standard.bool(forKey: "showHydrationReminders")
        showModerateOptions = UserDefaults.standard.bool(forKey: "showModerateOptions")
    }
    
    func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferredDrinkTypes) {
            UserDefaults.standard.set(encoded, forKey: "preferredDrinkTypes")
        }
        
        UserDefaults.standard.set(showLowAlcoholSuggestions, forKey: "showLowAlcoholSuggestions")
        UserDefaults.standard.set(showHydrationReminders, forKey: "showHydrationReminders")
        UserDefaults.standard.set(showModerateOptions, forKey: "showModerateOptions")
    }
    
    func togglePreferredDrinkType(_ type: DrinkType) {
        if preferredDrinkTypes.contains(type) {
            preferredDrinkTypes.removeAll { $0 == type }
        } else {
            preferredDrinkTypes.append(type)
        }
        
        savePreferences()
    }
    
    // MARK: - Suggestions Logic
    
    // Modified getSuggestions method in DrinkSuggestionManager.swift

    func getSuggestions(for drinkCount: Double, drinkLimit: Double) -> [DrinkSuggestion] {
        var suggestions: [DrinkSuggestion] = []
        
        // Create a new copy of water suggestion
        if showHydrationReminders {
            if let waterTemplate = nonAlcoholicOptions.first(where: { $0.name == "Water" }) {
                // Create a new instance with same properties but a new UUID
                let waterSuggestion = DrinkSuggestion(
                    name: waterTemplate.name,
                    type: waterTemplate.type,
                    alcoholPercentage: waterTemplate.alcoholPercentage,
                    isNonAlcoholic: waterTemplate.isNonAlcoholic,
                    size: waterTemplate.size,
                    standardDrinks: waterTemplate.standardDrinks,
                    emoji: waterTemplate.emoji,
                    description: waterTemplate.description,
                    ingredients: waterTemplate.ingredients
                )
                suggestions.append(waterSuggestion)
            }
        }
        
        // Near or exceeded limit - suggest non-alcoholic options only
        if drinkCount >= drinkLimit {
            // Take up to 4 non-alcoholic options (excluding water which we already added)
            let otherNonAlcoholicOptions = nonAlcoholicOptions
                .filter { $0.name != "Water" }
                .prefix(4)
            
            // Create new instances for each suggestion
            for template in otherNonAlcoholicOptions {
                let newSuggestion = DrinkSuggestion(
                    name: template.name,
                    type: template.type,
                    alcoholPercentage: template.alcoholPercentage,
                    isNonAlcoholic: template.isNonAlcoholic,
                    size: template.size,
                    standardDrinks: template.standardDrinks,
                    emoji: template.emoji,
                    description: template.description,
                    ingredients: template.ingredients
                )
                suggestions.append(newSuggestion)
            }
            
            return suggestions
        }
        
        // Approaching limit - suggest low alcohol options and water
        if drinkCount >= drinkLimit * 0.75 {
            if showLowAlcoholSuggestions {
                // Filter and create new instances of low alcohol options
                let filteredTemplates = lowAlcoholOptions.filter { option in
                    return preferredDrinkTypes.isEmpty || preferredDrinkTypes.contains(option.type)
                }.prefix(3)
                
                for template in filteredTemplates {
                    let newSuggestion = DrinkSuggestion(
                        name: template.name,
                        type: template.type,
                        alcoholPercentage: template.alcoholPercentage,
                        isNonAlcoholic: template.isNonAlcoholic,
                        size: template.size,
                        standardDrinks: template.standardDrinks,
                        emoji: template.emoji,
                        description: template.description,
                        ingredients: template.ingredients
                    )
                    suggestions.append(newSuggestion)
                }
            }
            
            // Add a couple of non-alcoholic options
            let nonAlcoholTemplates = nonAlcoholicOptions
                .filter { $0.name != "Water" }  // Skip water since we've already added it
                .shuffled()
                .prefix(2)
            
            for template in nonAlcoholTemplates {
                let newSuggestion = DrinkSuggestion(
                    name: template.name,
                    type: template.type,
                    alcoholPercentage: template.alcoholPercentage,
                    isNonAlcoholic: template.isNonAlcoholic,
                    size: template.size,
                    standardDrinks: template.standardDrinks,
                    emoji: template.emoji,
                    description: template.description,
                    ingredients: template.ingredients
                )
                suggestions.append(newSuggestion)
            }
            
            return suggestions
        }
        
        // Still under limit - suggest a mix of options
        var allOptions: [DrinkSuggestion] = []
        
        // Add low alcohol and moderate options
        if showLowAlcoholSuggestions {
            allOptions.append(contentsOf: lowAlcoholOptions.map { template in
                DrinkSuggestion(
                    name: template.name,
                    type: template.type,
                    alcoholPercentage: template.alcoholPercentage,
                    isNonAlcoholic: template.isNonAlcoholic,
                    size: template.size,
                    standardDrinks: template.standardDrinks,
                    emoji: template.emoji,
                    description: template.description,
                    ingredients: template.ingredients
                )
            })
        }
        
        if showModerateOptions {
            allOptions.append(contentsOf: moderateOptions.map { template in
                DrinkSuggestion(
                    name: template.name,
                    type: template.type,
                    alcoholPercentage: template.alcoholPercentage,
                    isNonAlcoholic: template.isNonAlcoholic,
                    size: template.size,
                    standardDrinks: template.standardDrinks,
                    emoji: template.emoji,
                    description: template.description,
                    ingredients: template.ingredients
                )
            })
        }
        
        // Filter by preferred drink types if any are selected
        if !preferredDrinkTypes.isEmpty {
            allOptions = allOptions.filter { option in
                return preferredDrinkTypes.contains(option.type)
            }
        }
        
        // Add selected options
        suggestions.append(contentsOf: allOptions.shuffled().prefix(4))
        
        // Add a non-alcoholic option
        if let nonAlcoholTemplate = nonAlcoholicOptions.filter({ $0.name != "Water" }).randomElement() {
            let newSuggestion = DrinkSuggestion(
                name: nonAlcoholTemplate.name,
                type: nonAlcoholTemplate.type,
                alcoholPercentage: nonAlcoholTemplate.alcoholPercentage,
                isNonAlcoholic: nonAlcoholTemplate.isNonAlcoholic,
                size: nonAlcoholTemplate.size,
                standardDrinks: nonAlcoholTemplate.standardDrinks,
                emoji: nonAlcoholTemplate.emoji,
                description: nonAlcoholTemplate.description,
                ingredients: nonAlcoholTemplate.ingredients
            )
            suggestions.append(newSuggestion)
        }
        
        return suggestions.shuffled()
    }
    
    // Get a specific suggestion for hydration after a certain number of drinks
    func getHydrationSuggestion() -> DrinkSuggestion {
        return nonAlcoholicOptions.first(where: { $0.name == "Water" })!
    }
    
    // Get a random non-alcoholic suggestion
    func getRandomNonAlcoholicSuggestion() -> DrinkSuggestion {
        let options = nonAlcoholicOptions.filter { $0.name != "Water" }
        return options.randomElement() ?? nonAlcoholicOptions[0]
    }
}


// MARK: - Drink Suggestion View
struct DrinkSuggestionView: View {
    @ObservedObject var suggestionManager = DrinkSuggestionManager.shared
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var showingPreferences = false
    
    private func addDrink(_ suggestion: DrinkSuggestionManager.DrinkSuggestion) {
        drinkTracker.addDrink(
            type: suggestion.type,
            size: suggestion.size,
            alcoholPercentage: suggestion.alcoholPercentage
        )
        
        // Schedule a hydration reminder
        if suggestionManager.showHydrationReminders {
            NotificationManager.shared.scheduleHydrationReminder(afterMinutes: 30)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended Drinks")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingPreferences = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    let suggestions = suggestionManager.getSuggestions(
                        for: drinkTracker.standardDrinkCount,
                        drinkLimit: drinkTracker.drinkLimit
                    )
                    
                    ForEach(suggestions) { suggestion in
                        DrinkSuggestionCard(
                            suggestion: suggestion,
                            onAdd: {
                                if !suggestion.isNonAlcoholic {
                                    addDrink(suggestion)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            if drinkTracker.standardDrinkCount >= drinkTracker.drinkLimit {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text("You've reached your drink limit. Consider switching to non-alcoholic options.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingPreferences) {
            DrinkPreferencesView(suggestionManager: suggestionManager)
        }
    }
}

    
    // MARK: - Drink Suggestion Card
    struct DrinkSuggestionCard: View {
        let suggestion: DrinkSuggestionManager.DrinkSuggestion
        let onAdd: () -> Void
        @State private var showingDetails = false
        
        var backgroundColor: Color {
            if suggestion.isNonAlcoholic {
                return Color.green.opacity(0.1)
            } else if suggestion.standardDrinks <= 0.7 {
                return Color.blue.opacity(0.1)
            } else {
                return Color.orange.opacity(0.1)
            }
        }
        
        var body: some View {
            Button(action: {
                showingDetails = true
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(suggestion.emoji)
                            .font(.title)
                        
                        Spacer()
                        
                        if suggestion.isNonAlcoholic {
                            Text("Non-Alcoholic")
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(suggestion.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(suggestion.formattedSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !suggestion.isNonAlcoholic {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(suggestion.alcoholPercentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("\(String(format: "%.1f", suggestion.standardDrinks)) std")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(height: 32)
                    
                    if !suggestion.isNonAlcoholic {
                        Button(action: onAdd) {
                            Text("Add to Log")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
                .frame(width: 160)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingDetails) {
                DrinkDetailView(suggestion: suggestion, onAdd: onAdd)
            }
        }
    }
    
    // MARK: - Drink Detail View
    struct DrinkDetailView: View {
        let suggestion: DrinkSuggestionManager.DrinkSuggestion
        let onAdd: () -> Void
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack(alignment: .top) {
                            Text(suggestion.emoji)
                                .font(.system(size: 72))
                                .frame(width: 80, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(suggestion.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                if suggestion.isNonAlcoholic {
                                    Text("Non-Alcoholic")
                                        .font(.subheadline)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                } else {
                                    Text("\(String(format: "%.1f", suggestion.standardDrinks)) standard drinks")
                                        .font(.subheadline)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Details
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Details")
                                .font(.headline)
                            
                            HStack {
                                DetailItem(
                                    title: "Size",
                                    value: suggestion.formattedSize,
                                    systemImage: "ruler"
                                )
                                
                                Divider()
                                    .frame(height: 40)
                                
                                DetailItem(
                                    title: "Type",
                                    value: suggestion.type.rawValue,
                                    systemImage: "tag"
                                )
                                
                                if !suggestion.isNonAlcoholic {
                                    Divider()
                                        .frame(height: 40)
                                    
                                    DetailItem(
                                        title: "Alcohol",
                                        value: "\(String(format: "%.1f", suggestion.alcoholPercentage))%",
                                        systemImage: "percent"
                                    )
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(suggestion.description)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Ingredients
                        if let ingredients = suggestion.ingredients, !ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Ingredients")
                                    .font(.headline)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(ingredients, id: \.self) { ingredient in
                                        HStack(alignment: .top) {
                                            Text("•")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                            
                                            Text(ingredient)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Add button for alcoholic drinks
                        if !suggestion.isNonAlcoholic {
                            Button(action: {
                                onAdd()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Add to Drink Log")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarItems(trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
    
    // Detail item for drink details
    struct DetailItem: View {
        let title: String
        let value: String
        let systemImage: String
        
        var body: some View {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Drink Preferences View
    struct DrinkPreferencesView: View {
        @ObservedObject var suggestionManager: DrinkSuggestionManager
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                Form {
                    Section {
                        ForEach(DrinkType.allCases, id: \.self) { type in
                            Button(action: {
                                suggestionManager.togglePreferredDrinkType(type)
                            }) {
                                HStack {
                                    Text(type.icon)
                                        .font(.title2)
                                    
                                    Text(type.rawValue)
                                    
                                    Spacer()
                                    
                                    if suggestionManager.preferredDrinkTypes.contains(type) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if !suggestionManager.preferredDrinkTypes.isEmpty {
                            Button(action: {
                                suggestionManager.preferredDrinkTypes = []
                                suggestionManager.savePreferences()
                            }) {
                                Text("Clear All")
                                    .foregroundColor(.red)
                            }
                        }
                    } header: {
                        Text("Preferred Drink Types")
                    } footer: {
                        Text("Selecting specific drink types will filter your suggestions. If none are selected, you'll see all types.")
                    }
                    
                    Section {
                        Toggle("Show Low-Alcohol Options", isOn: $suggestionManager.showLowAlcoholSuggestions)
                            .onChange(of: suggestionManager.showLowAlcoholSuggestions) { oldValue, newValue in
                                suggestionManager.savePreferences()
                            }
                        
                        Toggle("Show Hydration Reminders", isOn: $suggestionManager.showHydrationReminders)
                            .onChange(of: suggestionManager.showHydrationReminders) { oldValue, newValue in
                                suggestionManager.savePreferences()
                            }
                        
                        Toggle("Show Moderate Options", isOn: $suggestionManager.showModerateOptions)
                            .onChange(of: suggestionManager.showModerateOptions) { oldValue, newValue in
                                suggestionManager.savePreferences()
                            }
                    } header: {
                        Text("Suggestion Options")
                    } footer: {
                        Text("These settings control what types of drink suggestions you'll receive based on your current BAC.")
                    }
                    
                    Section {
                        Text("Note: When your above 0.08, you'll only see non-alcoholic suggestions regardless of these settings.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Drink Preferences")
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
