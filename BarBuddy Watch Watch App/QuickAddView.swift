//
//  QuickAddView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/22/25.
//
import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @EnvironmentObject var sessionManager: WatchSessionManager
    
    let drinkTypes: [DrinkType] = [.beer, .wine, .cocktail, .shot]
    
    var body: some View {
        VStack {
            Text("Quick Add")
                .font(.headline)
                .padding(.top, 5)
            
            List {
                ForEach(drinkTypes, id: \.self) { drinkType in
                    Button(action: {
                        addDrink(type: drinkType)
                    }) {
                        HStack {
                            Text(drinkType.icon)
                                .font(.title3)
                            
                            Text(drinkType.rawValue)
                                .font(.body)
                        }
                    }
                }
            }
        }
    }
    
    private func addDrink(type: DrinkType) {
        // Add drink locally
        drinkTracker.addDrink(
            type: type,
            size: type.defaultSize,
            alcoholPercentage: type.defaultAlcoholPercentage
        )
        
        // Send to phone if connected
        sessionManager.logDrink(type: type)
    }
}
