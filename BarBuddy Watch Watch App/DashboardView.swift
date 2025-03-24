//
//  DashboardView.swift
//  BarBuddy Watch Watch App
//
//  Created by Travis Rodriguez on 3/24/25.
#if os(watchOS)
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DrinkTrackerViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // BAC display
                VStack(spacing: 5) {
                    Text("Current BAC")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.3f", viewModel.currentBAC))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(bacColor)
                    
                    Text(safetyStatus)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(bacColor.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.vertical, 10)
                
                Divider()
                
                // Time until sober
                if viewModel.timeUntilSober > 0 {
                    VStack(spacing: 5) {
                        Text("Sober in")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(viewModel.getFormattedTimeUntilSober())
                            .font(.headline)
                    }
                    .padding(.vertical, 10)
                    
                    Divider()
                }
                
                // Recent drinks
                VStack(spacing: 5) {
                    Text("Recent Drinks")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if viewModel.drinks.isEmpty {
                        Text("No drinks recorded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    } else {
                        // Show the last 3 drinks
                        ForEach(Array(viewModel.drinks.prefix(3).enumerated()), id: \.element.id) { index, drink in
                            HStack {
                                Text(drink.type.icon)
                                    .font(.body)
                                
                                Text(drink.type.rawValue)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(timeAgo(drink.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 5)
                            
                            if index < min(2, viewModel.drinks.count - 1) {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Properties
    
    var bacColor: Color {
        switch viewModel.getSafetyStatus() {
        case .safe: return .green
        case .borderline: return .yellow
        case .unsafe: return .red
        }
    }
    
    var safetyStatus: String {
        return viewModel.getSafetyStatus().rawValue
    }
    
    // MARK: - Helper Methods
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
#endif
