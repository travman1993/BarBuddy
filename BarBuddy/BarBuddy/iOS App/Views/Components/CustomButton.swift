import SwiftUI

struct CustomButton: View {
    let title: String
    var icon: String? = nil
    var backgroundColor: Color = .blue
    var foregroundColor: Color = .white
    var isLoading: Bool = false
    var fullWidth: Bool = true
    var cornerRadius: CGFloat = Constants.UI.cornerRadius
    var height: CGFloat = Constants.UI.buttonHeight
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .padding(.horizontal, fullWidth ? Constants.UI.standardPadding : Constants.UI.largePadding)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .opacity(isLoading ? 0.8 : 1.0)
        }
        .disabled(isLoading)
    }
}

// Different button styles
extension CustomButton {
    static func primary(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            backgroundColor: .blue,
            foregroundColor: .white,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
    
    static func secondary(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            backgroundColor: Color(.systemGray5),
            foregroundColor: .primary,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
    
    static func success(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            backgroundColor: .green,
            foregroundColor: .white,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
    
    static func danger(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            backgroundColor: .red,
            foregroundColor: .white,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
    
    static func outline(
        title: String,
        icon: String? = nil,
        color: Color = .blue,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        CustomButton(
            title: title,
            icon: icon,
            backgroundColor: .clear,
            foregroundColor: color,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .stroke(color, lineWidth: 1)
        )
    }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomButton.primary(
                title: "Add Drink",
                icon: "plus",
                action: {}
            )
            
            CustomButton.secondary(
                title: "Cancel",
                action: {}
            )
            
            CustomButton.success(
                title: "Check In",
                icon: "checkmark.circle.fill",
                action: {}
            )
            
            CustomButton.danger(
                title: "Delete",
                icon: "trash",
                isLoading: false,
                action: {}
            )
            
            CustomButton.outline(
                title: "View Details",
                icon: "info.circle",
                action: {}
            )
            
            CustomButton(
                title: "Loading Example",
                icon: "arrow.clockwise",
                isLoading: true,
                action: {}
            )
            
            CustomButton(
                title: "Not Full Width",
                fullWidth: false,
                action: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
