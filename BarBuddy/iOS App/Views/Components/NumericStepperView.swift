import SwiftUI

struct NumericStepperView: View {
    let title: String
    let unit: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...Double.infinity
    var step: Double = 1.0
    var formatSpecifier: String = "%.1f"
    var isPrecise: Bool = false
    
    var body: some View {
        VStack(spacing: Constants.UI.smallPadding) {
            // Title
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: Constants.UI.standardPadding) {
                // Decrement button
                Button {
                    decrementValue()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(value <= range.lowerBound)
                
                // Value display
                VStack(spacing: 4) {
                    Text(String(format: formatSpecifier, value))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 80)
                
                // Increment button
                Button {
                    incrementValue()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(value >= range.upperBound)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            
            // Fine adjustment buttons if precise mode is enabled
            if isPrecise {
                HStack(spacing: Constants.UI.standardPadding) {
                    Button {
                        decrementValue(smallStep: true)
                    } label: {
                        Text("-\(String(format: formatSpecifier, step / 10))")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(Constants.UI.cornerRadius / 2)
                    }
                    .disabled(value <= range.lowerBound)
                    
                    Button {
                        decrementValue(smallStep: false)
                    } label: {
                        Text("-\(String(format: formatSpecifier, step))")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(Constants.UI.cornerRadius / 2)
                    }
                    .disabled(value <= range.lowerBound)
                    
                    Button {
                        incrementValue(smallStep: false)
                    } label: {
                        Text("+\(String(format: formatSpecifier, step))")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(Constants.UI.cornerRadius / 2)
                    }
                    .disabled(value >= range.upperBound)
                    
                    Button {
                        incrementValue(smallStep: true)
                    } label: {
                        Text("+\(String(format: formatSpecifier, step / 10))")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(Constants.UI.cornerRadius / 2)
                    }
                    .disabled(value >= range.upperBound)
                }
            }
        }
    }
    
    private func incrementValue(smallStep: Bool = false) {
        let incrementAmount = smallStep ? step / 10 : step
        value = min(range.upperBound, value + incrementAmount)
    }
    
    private func decrementValue(smallStep: Bool = false) {
        let decrementAmount = smallStep ? step / 10 : step
        value = max(range.lowerBound, value - decrementAmount)
    }
}

struct NumericStepperView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NumericStepperView(
                title: "Weight",
                unit: "lbs",
                value: .constant(160.0),
                range: 50...400,
                step: 5.0
            )
            
            NumericStepperView(
                title: "Alcohol Percentage",
                unit: "%",
                value: .constant(5.0),
                range: 0...100,
                step: 0.5,
                formatSpecifier: "%.1f",
                isPrecise: true
            )
            
            NumericStepperView(
                title: "Amount",
                unit: "oz",
                value: .constant(12.0),
                range: 0...32,
                step: 1.0,
                formatSpecifier: "%.1f",
                isPrecise: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
