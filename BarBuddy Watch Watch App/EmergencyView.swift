//
//  EmergencyView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/22/25.
//
import SwiftUI

struct EmergencyView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Get Home Safe")
                .font(.headline)
            
            Button(action: getUber) {
                HStack {
                    Image(systemName: "car.fill")
                    Text("Uber")
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button(action: callEmergency) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Emergency")
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func getUber() {
        // Implementation
    }
    
    private func callEmergency() {
        // Implementation
    }
}
