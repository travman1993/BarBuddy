//
//  RecentlyAddedDrinkRow.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/9/25.
//
import SwiftUI

struct RecentlyAddedDrinkRow: View {
    var drink: Drink
    var onRemove: (Drink) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(drink.type.rawValue)  // Assuming 'type' is a raw value of an enum
                    .font(.headline)
                Text(drink.timestamp, style: .time)  // Displaying timestamp as time
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: {
                onRemove(drink)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
