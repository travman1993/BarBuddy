//
//  DrinkLimitSettingView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/14/25.
//
import SwiftUI

struct DrinkLimitSettingView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var drinkLimit: Double
    @State private var showingLimitEditor = false
    
    init(initialLimit: Double) {
        _drinkLimit = State(initialValue: initialLimit)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Drink Limit:")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(String(format: "%.1f", drinkLimit)) standard drinks")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button(action: {
                    showingLimitEditor = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Slider(value: $drinkLimit, in: 1...10, step: 0.5)
                .accentColor(.blue)
                .disabled(!showingLimitEditor)
            
            if showingLimitEditor {
                HStack {
                    Button("Cancel") {
                        // Reset to the original value
                        drinkLimit = drinkTracker.drinkLimit
                        showingLimitEditor = false
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        // Save the new limit
                        drinkTracker.updateDrinkLimit(drinkLimit)
                        showingLimitEditor = false
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .animation(.easeInOut, value: showingLimitEditor)
    }
}
