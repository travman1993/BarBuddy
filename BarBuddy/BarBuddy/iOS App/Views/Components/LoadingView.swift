//
//  LoadingView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    var showProgress: Bool = false
    
    var body: some View {
        VStack(spacing: Constants.UI.standardPadding) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(Constants.UI.largePadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// Usage modifier for any view
extension View {
    func loading(isLoading: Bool, message: String = "Loading...", showProgress: Bool = false) -> some View {
        ZStack {
            self
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                LoadingView(message: message, showProgress: showProgress)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView(message: "Loading drinks...")
                .previewLayout(.sizeThatFits)
                .padding()
            
            LoadingView(message: "Calculating BAC...", showProgress: true)
                .previewLayout(.sizeThatFits)
                .padding()
            
            ZStack {
                VStack {
                    Text("Content behind loading view")
                        .font(.title)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                
                LoadingView(message: "Please wait")
            }
        }
    }
}
