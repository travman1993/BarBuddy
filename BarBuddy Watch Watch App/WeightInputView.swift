//
//  WeightInputView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/22/25.
//
import SwiftUI

struct WeightInputView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var weight: Double
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedUnit: WeightUnit = .pounds
    @State private var isSaving = false
    
    enum WeightUnit: String, CaseIterable {
        case pounds = "lbs"
        case kilograms = "kg"
    }
    
    init(currentWeight: Double) {
        _weight = State(initialValue: currentWeight)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Your Weight")
                    .font(.headline)
                    .padding(.top, 5)
                
                // Replace SegmentedPickerStyle with inline buttons for unit selection
                HStack {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Button(action: {
                            selectedUnit = unit
                        }) {
                            Text(unit.rawValue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selectedUnit == unit ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(selectedUnit == unit ? .white : .primary)
                                .cornerRadius(5)
                        }
                    }
                }
                .padding(.vertical, 5)
                
                HStack {
                    Button(action: { adjustWeight(-5) }) {
                        Text("-5")
                            .font(.title3)
                            .padding(5)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    }
                    
                    Button(action: { adjustWeight(-1) }) {
                        Text("-1")
                            .font(.title3)
                            .padding(5)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(weight))")
                        .font(.system(size: 32, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: { adjustWeight(1) }) {
                        Text("+1")
                            .font(.title3)
                            .padding(5)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    }
                    
                    Button(action: { adjustWeight(5) }) {
                        Text("+5")
                            .font(.title3)
                            .padding(5)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    }
                }
                .padding(.vertical, 10)
                
                Text("\(selectedUnit.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if isSaving {
                    ProgressView()
                        .padding()
                } else {
                    Button(action: saveWeight) {
                        Text("Save")
                            .font(.body)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
            }
            .padding()
        }
        .navigationTitle("Weight")
    }
    
    private func adjustWeight(_ amount: Double) {
        weight = max(50, weight + amount)  // Ensure weight doesn't go below 50
        WKInterfaceDevice.current().play(.click)
    }
    
    private func saveWeight() {
        isSaving = true
        var weightInPounds = weight
        
        // Convert to pounds if in kg
        if selectedUnit == .kilograms {
            weightInPounds = weight * 2.20462
        }
        
        // Update weight on phone
        sessionManager.updateUserWeight(weightInPounds)
        
        // Close view after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            WKInterfaceDevice.current().play(.success)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
