import SwiftUI

struct DrinkDetailView: View {
    let drink: Drink
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var bacViewModel: BACViewModel
    
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.standardPadding) {
                // Drink Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: drink.type.systemIconName)
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                }
                .padding(.top)
                
                // Drink Name
                Text(drink.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Drink Time
                Text("Added \(drink.timestamp.dateTimeString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Drink Details
                DrinkInfoCard(drink: drink)
                
                // Additional Details
                if let location = drink.location, !location.isEmpty {
                    DrinkLocationView(location: location)
                }
                
                if let notes = drink.notes, !notes.isEmpty {
                    DrinkNotesView(notes: notes)
                }
                
                // BAC Contribution
                DrinkBACContributionView(drink: drink)
                
                Spacer()
                
                // Delete Button
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Label("Delete Drink", systemImage: "trash")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(Constants.UI.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                .stroke(Color.red, lineWidth: 1)
                        )
                }
                .disabled(isDeleting)
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Drink Details")
        .alert("Delete Drink?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDrink()
            }
        } message: {
            Text("Are you sure you want to delete this drink? This will affect your BAC calculation.")
        }
        .overlay {
            if isDeleting {
                ProgressView("Deleting...")
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 5)
                    )
            }
        }
    }
    
    private func deleteDrink() {
        isDeleting = true
        
        Task {
            await drinkViewModel.deleteDrink(id: drink.id)
            await bacViewModel.calculateBAC()
            
            // Navigation back happens automatically when the drink is deleted
            isDeleting = false
        }
    }
}

struct DrinkInfoCard: View {
    let drink: Drink
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                InfoItem(
                    label: "Alcohol",
                    value: "\(drink.alcoholPercentage, specifier: "%.1f")%",
                    icon: "percent"
                )
                
                Divider()
                
                InfoItem(
                    label: "Amount",
                    value: "\(drink.amount, specifier: "%.1f") oz",
                    icon: "drop.fill"
                )
                
                Divider()
                
                InfoItem(
                    label: "Standard",
                    value: "\(drink.standardDrinks, specifier: "%.1f")",
                    icon: "mug.fill"
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
        }
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DrinkLocationView: View {
    let location: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                
                Text(location)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

struct DrinkNotesView: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            
            Text(notes)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

struct DrinkBACContributionView: View {
    let drink: Drink
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BAC Impact")
                .font(.headline)
            
            HStack(spacing: 16) {
                // BAC Contribution
                VStack(alignment: .leading, spacing: 4) {
                    Text("Adds approximately")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(bacContribution, specifier: "%.3f")%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("to your BAC when consumed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Metabolism rate
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Metabolized in")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(metabolismTimeString)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("at average rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    // Approximate BAC contribution
    // Note: This is a simplification and not the full Widmark formula which needs weight and gender
    private var bacContribution: Double {
        let alcoholGrams = drink.amount * (drink.alcoholPercentage / 100) * 29.57 * 0.789
        return (alcoholGrams / 5400) * 100 // Very rough approximation
    }
    
    // Approximate time to metabolize this drink
    private var metabolismTimeString: String {
        let hoursToMetabolize = bacContribution / Constants.BAC.metabolismRate
        let hours = Int(hoursToMetabolize)
        let minutes = Int((hoursToMetabolize - Double(hours)) * 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct DrinkDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                DrinkDetailView(drink: Drink.example(type: .beer))
            }
            
            NavigationView {
                DrinkDetailView(drink: Drink.example(type: .wine))
            }
            
            NavigationView {
                DrinkDetailView(drink: Drink.example(type: .liquor))
            }
        }
        .environmentObject(DrinkViewModel())
        .environmentObject(BACViewModel())
    }
}
