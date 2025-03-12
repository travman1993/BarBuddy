import SwiftUI

struct DrinkRowView: View {
    let drink: Drink
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Drink icon
                Image(systemName: drink.type.systemIconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    // Drink name
                    Text(drink.displayName)
                        .font(.headline)
                    
                    // Details
                    Text("\(drink.amount.volumeString(isMetric: false)) • \(drink.standardDrinks.formatted()) standard drinks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time
                VStack(alignment: .trailing, spacing: 2) {
                    Text(drink.timestamp.timeString)
                        .font(.subheadline)
                    
                    Text(drink.timestamp.relativeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Location if available
            if let location = drink.location, !location.isEmpty {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete Drink?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this drink? This will affect your BAC calculation.")
        }
    }
}

struct DrinkRowView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkRowView(
            drink: Drink.example(),
            onDelete: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
