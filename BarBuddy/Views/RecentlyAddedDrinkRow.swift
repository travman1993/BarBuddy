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
            Text(drink.type.icon)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(drink.type.rawValue)
                    .fontWeight(.medium)
                
                Text("\(String(format: "%.1f", drink.size)) oz, \(String(format: "%.1f", drink.alcoholPercentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(drink.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    Image(systemName: "wineglass")
                        .font(.system(size: 10))
                    Text("\(String(format: "%.1f", drink.standardDrinks))")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Button(action: {
                onRemove(drink)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
