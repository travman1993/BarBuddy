//
//  QuickAddView.swift
//  BarBuddy Watch Watch App
//
//  Created by Travis Rodriguez on 3/24/25.
//

#if os(watchOS)
import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject var viewModel: DrinkTrackerViewModel
    @EnvironmentObject var sessionManager: WatchSessionManager
    
    let drinkTypes: [DrinkType] = [.beer, .wine, .cocktail, .shot, .other]
    
    @State private var showingConfirmation = false
    @State private var lastAddedDrink: DrinkType?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Quick Add")
                    .font(.headline)
                    .padding(.top, 5)
                
                // Toast-style confirmation
                if showingConfirmation, let drinkType = lastAddedDrink {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(drinkType.rawValue) added")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // Drink type buttons
                ForEach(drinkTypes, id: \.self) { drinkType in
                    Button(action: {
                        addDrink(type: drinkType)
                    }) {
                        HStack {
                            Text(drinkType.icon)
                                .font(.title3)
                            
                            Text(drinkType.rawValue)
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    private func addDrink(type: DrinkType) {
        // Add drink using view model
        viewModel.addDrink(
            type: type,
            size: type.defaultSize,
            alcoholPercentage: type.defaultAlcoholPercentage
        )
        
        // Show confirmation
        lastAddedDrink = type
        showingConfirmation = true
        
        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showingConfirmation = false
            }
        }
        
        // Explicitly send to iPhone through session manager
        sessionManager.logDrink(type: type)
    }
}
#endif
