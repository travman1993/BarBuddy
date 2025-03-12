import SwiftUI

struct SegmentedPickerView<SelectionValue: Hashable & Identifiable, Content: View>: View {
    let values: [SelectionValue]
    @Binding var selection: SelectionValue
    let content: (SelectionValue, Bool) -> Content
    
    private let cornerRadius: CGFloat = Constants.UI.cornerRadius
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(values) { value in
                makeButton(for: value)
            }
        }
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(cornerRadius)
    }
    
    @ViewBuilder
    private func makeButton(for value: SelectionValue) -> some View {
        let isSelected = value.hashValue == selection.hashValue
        
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = value
            }
        } label: {
            content(value, isSelected)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .cornerRadius(cornerRadius)
        .animation(.easeInOut(duration: 0.2), value: selection)
    }
}

// Easy-to-use text version
struct TextSegmentedPickerView<SelectionValue: Hashable & Identifiable & CustomStringConvertible>: View {
    let title: String
    let values: [SelectionValue]
    @Binding var selection: SelectionValue
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.smallPadding) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            SegmentedPickerView(values: values, selection: $selection) { value, isSelected in
                Text(value.description)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
    }
}

// Preview helper
extension Int: Identifiable {
    public var id: Int { self }
}

extension String: Identifiable {
    public var id: String { self }
}

struct SegmentedPickerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Custom content example
            SegmentedPickerView(values: ["Beer", "Wine", "Liquor", "Cocktail"], selection: .constant("Beer")) { value, isSelected in
                VStack {
                    Image(systemName: isSelected ? "\(value.lowercased()).fill" : value.lowercased())
                        .font(.body)
                    
                    Text(value)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
            }
            .padding()
            
            // Text-only example
            TextSegmentedPickerView(
                title: "Time Frame",
                values: ["Day", "Week", "Month"],
                selection: .constant("Week")
            )
            .padding()
            
            // Numbers example
            TextSegmentedPickerView(
                title: "Rating",
                values: [1, 2, 3, 4, 5],
                selection: .constant(3)
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
        .background(Color(.systemBackground))
    }
}
