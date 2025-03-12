//
//  WelcomeView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/12/25.
//

import SwiftUI

struct WelcomeView: View {
    var coordinator: OnboardingCoordinator? = nil
    
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var showingNextScreen = false
    
    var body: some View {
        VStack(spacing: Constants.UI.largePadding) {
            // App icon / logo
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: "mug.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.blue)
                    .frame(width: 80, height: 80)
            }
            .padding(.top, Constants.UI.largePadding)
            
            // Welcome text
            Text("Welcome to \(Constants.App.name)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your personal alcohol tracking assistant")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            // App features
            VStack(alignment: .leading, spacing: Constants.UI.standardPadding) {
                FeatureRow(icon: "gauge", title: "Track Your BAC", description: "Get real-time estimates of your blood alcohol content")
                
                FeatureRow(icon: "mug.fill", title: "Log Drinks", description: "Easily record different types of alcoholic beverages")
                
                FeatureRow(icon: "clock.fill", title: "Time to Sober", description: "Know when it's safe to drive again")
                
                FeatureRow(icon: "exclamationmark.triangle.fill", title: "Emergency Features", description: "Quickly contact emergency contacts if needed")
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Get started button
            Button {
                if let coordinator = coordinator {
                    coordinator.showGenderSelection()
                } else {
                    showingNextScreen = true
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
            }
            .padding(.horizontal)
            .padding(.bottom, Constants.UI.largePadding)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingNextScreen) {
            GenderSelectionView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(UserViewModel())
    }
}
