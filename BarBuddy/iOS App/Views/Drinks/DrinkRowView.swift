import SwiftUI

struct DrinkRowView: View {
    let drink: Drink
    let onDelete: () -> Void
    var showDetails: Bool = true
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Drink icon
            Image(systemName: drink.type.systemIconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            // Drink details
            VStack(alignment: .leading, spacing: 4) {
                // Drink name
                Text(drink.displayName)
                    .font(.headline)
                
                if showDetails {
                    // Details
                    HStack(spacing: 8) {
                        Text("\(drink.amount.volumeString(isMetric: false))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(drink.standardDrinks.formatted()) standard")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let location = drink.location, !location.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(drink.timestamp.timeString)
                    .font(.subheadline)
                
                if showDetails {
                    Text(drink.timestamp.relativeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Drink?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this drink? This will affect your BAC calculation.")
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct CompactDrinkRow: View {
    let drink: Drink
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: drink.type.systemIconName)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            // Name
            Text(drink.displayName)
                .font(.subheadline)
            
            Spacer()
            
            // Time
            Text(drink.timestamp.timeString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct DrinkRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard view
            DrinkRowView(
                drink: Drink.example(type: .beer),
                onDelete: {}
            )
            
            // Compact view
            CompactDrinkRow(
                drink: Drink.example(type: .wine)
            )
            
            // Row with location
            let drinkWithLocation = Drink(
                userId: "example",
                type: .cocktail,
                name: "Martini",
                alcoholPercentage: 15.0,
                amount: 6.0,
                location: "Skybar Lounge"
            )
            
            DrinkRowView(
                drink: drinkWithLocation,
                onDelete: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
