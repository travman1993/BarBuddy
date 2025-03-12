import SwiftUI

enum AlertType {
    case success
    case warning
    case error
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        }
    }
}

struct AlertBanner: View {
    let type: AlertType
    let title: String
    var message: String? = nil
    var isTemporary: Bool = true
    var action: (() -> Void)? = nil
    
    @Binding var isPresented: Bool
    
    @State private var offset: CGFloat = -100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: Constants.UI.smallPadding) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(type.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let message = message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Button {
                        action?()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(type.color)
                    }
                    .padding(.leading, Constants.UI.smallPadding)
                }
                
                if !isTemporary {
                    Button {
                        dismissBanner()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .offset(y: offset)
        .animation(.spring(), value: offset)
        .onAppear {
            offset = 0
            
            if isTemporary {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismissBanner()
                }
            }
        }
    }
    
    private func dismissBanner() {
        withAnimation {
            offset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

// Usage helper extension on View
extension View {
    func alertBanner(
        isPresented: Binding<Bool>,
        type: AlertType,
        title: String,
        message: String? = nil,
        isTemporary: Bool = true,
        action: (() -> Void)? = nil
    ) -> some View {
        ZStack(alignment: .top) {
            self
            
            if isPresented.wrappedValue {
                AlertBanner(
                    type: type,
                    title: title,
                    message: message,
                    isTemporary: isTemporary,
                    action: action,
                    isPresented: isPresented
                )
                .zIndex(100)
                .transition(.move(edge: .top))
            }
        }
    }
}

struct AlertBanner_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AlertBanner(
                type: .success,
                title: "Drink Added",
                message: "Your drink has been added to the log",
                isPresented: .constant(true)
            )
            
            AlertBanner(
                type: .error,
                title: "Failed to Save",
                message: "There was an error saving your data",
                isPresented: .constant(true)
            )
            
            AlertBanner(
                type: .warning,
                title: "High BAC Level",
                message: "Your BAC is above the legal limit",
                isTemporary: false,
                isPresented: .constant(true)
            )
            
            AlertBanner(
                type: .info,
                title: "Syncing with Watch",
                message: "Your data is being synced with Apple Watch",
                action: { print("Action tapped") },
                isPresented: .constant(true)
            )
        }
        .previewLayout(.sizeThatFits)
        .padding(.vertical)
    }
}
