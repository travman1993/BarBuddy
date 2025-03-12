//
//  ToastView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

enum ToastStyle {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct Toast: Identifiable, Equatable {
    var id = UUID()
    let style: ToastStyle
    let message: String
    var duration: Double = 3.0
    
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToastView: View {
    let toast: Toast
    @Binding var toasts: [Toast]
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.style.icon)
                .foregroundColor(toast.style.color)
            
            Text(toast.message)
                .font(.subheadline)
            
            Spacer()
            
            Button {
                withAnimation {
                    toasts.removeAll { $0.id == toast.id }
                }
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .padding(.horizontal)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                withAnimation {
                    toasts.removeAll { $0.id == toast.id }
                }
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toasts: [Toast]
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            VStack(spacing: 8) {
                ForEach(toasts) { toast in
                    ToastView(toast: toast, toasts: $toasts)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 16)
            .animation(.spring(), value: toasts)
        }
    }
}

// Usage extension
extension View {
    func toasts(toasts: Binding<[Toast]>) -> some View {
        self.modifier(ToastModifier(toasts: toasts))
    }
    
    func showToast(style: ToastStyle, message: String, duration: Double = 3.0) -> some View {
        self.modifier(ToastModifier(toasts: .constant([Toast(style: style, message: message, duration: duration)])))
    }
}

struct ToastView_Previews: PreviewProvider {
    @State static var toasts: [Toast] = [
        Toast(style: .success, message: "Drink added successfully"),
        Toast(style: .error, message: "Failed to save data", duration: 5.0),
        Toast(style: .warning, message: "Your BAC is approaching the legal limit"),
        Toast(style: .info, message: "Tap to add a drink")
    ]
    
    static var previews: some View {
        Group {
            // Single toast examples
            VStack {
                ToastView(toast: Toast(style: .success, message: "Drink added successfully"), toasts: $toasts)
                
                ToastView(toast: Toast(style: .error, message: "Failed to save data"), toasts: $toasts)
                
                ToastView(toast: Toast(style: .warning, message: "Your BAC is approaching the legal limit"), toasts: $toasts)
                
                ToastView(toast: Toast(style: .info, message: "Tap to add a drink"), toasts: $toasts)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            
            // Example usage in a view
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                Button("Show Toast") {
                    // This would add a toast in a real app
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(Constants.UI.cornerRadius)
            }
            .toasts(toasts: $toasts)
        }
    }
}
