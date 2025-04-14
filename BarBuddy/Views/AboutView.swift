//
//  AboutView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import SwiftUI

struct AppAboutView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDisclaimer = false
    @State private var showingCredits = false
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // App Logo
                    VStack(spacing: 15) {
                        Image(systemName: "wineglass")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("BarBuddy")
                            .font(.system(size: 34, weight: .bold))
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // App Description
                    VStack(spacing: 15) {
                        Text("About BarBuddy")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("BarBuddy is a personal alcohol tracking app designed to help you make informed decisions about your drinking. It uses scientific formulas to estimate your Blood Alcohol Content (BAC) and provides tools to help you drink responsibly.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        Text("BarBuddy is not a medical device and should not be used to determine if you are legally able to drive or operate machinery. Always err on the side of caution.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Key Features")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        FeatureRow(
                            icon: "calendar",
                            title: "Drink History",
                            description: "Track and analyze your drinking patterns over time"
                        )
                        
                        FeatureRow(
                            icon: "person.2",
                            title: "Share Status",
                            description: "Let friends know information"
                        )
                        
                        FeatureRow(
                            icon: "bell",
                            title: "Smart Notifications",
                            description: "Get alerts about reminders to hydrate"
                        )
                        
                        
                        FeatureRow(
                            icon: "phone.fill",
                            title: "Emergency Contacts",
                            description: "Quick access to your designated contacts when needed"
                        )
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            showingDisclaimer = true
                        }) {
                            ActionButtonView(
                                title: "Legal Disclaimer",
                                icon: "doc.text",
                                color: .blue
                            )
                        }
                        
                        Button(action: {
                            showingCredits = true
                        }) {
                            ActionButtonView(
                                title: "Credits & Acknowledgments",
                                icon: "heart",
                                color: .red
                            )
                        }
                        
                        Link(destination: URL(string: "https://www.example.com/contact")!) {
                            ActionButtonView(
                                title: "Contact Support",
                                icon: "envelope",
                                color: .green
                            )
                        }
                        
                        Link(destination: URL(string: "https://www.example.com/privacy")!) {
                            ActionButtonView(
                                title: "Privacy Policy",
                                icon: "lock.shield",
                                color: .purple
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Copyright
                    VStack {
                        Text("© 2025 BarBuddy App")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text("All rights reserved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("About")
            .background(Color("AppBackground"))
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingDisclaimer) {
            DisclaimerView()
        }
        .sheet(isPresented: $showingCredits) {
            CreditsView()
        }
    }
}

// Feature row component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

// Action button view
struct ActionButtonView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

// Legal Disclaimer View
struct AppDisclaimerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("BarBuddy Legal Disclaimer")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                        
                        Text("Purpose of the App")
                            .font(.headline)
                        
                        Text("BarBuddy is designed to help users be more aware of their alcohol consumption and to make more informed decisions. It is an educational and informational tool only.")
                        
                        Text("Calculation Limitations")
                            .font(.headline)
                        
                        Text("The Blood Alcohol Content (BAC) calculations provided by BarBuddy are estimates based on generalized formulas. Actual levels can vary significantly based on numerous factors including but not limited to: metabolism, hydration, food consumption, medications, health conditions, altitude, and fatigue.")
                        
                        Text("Not a Medical Device")
                            .font(.headline)
                        
                        Text("BarBuddy is not a medical device and has not been evaluated by the FDA or any other regulatory agency. It should never be used to determine whether you are legally or physically able to drive, operate machinery, or engage in any activity that requires sobriety or coordination.")
                    }
                    
                    Group {
                        Text("No Driving Recommendation")
                            .font(.headline)
                        
                        Text("BarBuddy does not and cannot recommend when it is safe or legal for you to drive. The only safe amount of alcohol for driving is zero. If you have consumed any amount of alcohol, you should not drive or operate machinery regardless of what the app indicates.")
                        
                        Text("Legal Driving Limits")
                            .font(.headline)
                        
                        Text("Emergency Features")
                            .font(.headline)
                        
                        Text("The emergency contact and rideshare features are provided as conveniences and are not guaranteed to function in all circumstances. Never rely solely on BarBuddy in an emergency situation.")
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("No Warranty")
                            .font(.headline)
                            
                        Text("BarBuddy is provided \"as is,\" without warranty of any kind, either express or implied, including but not limited to the implied warranties of merchantability, fitness for a particular purpose, or non-infringement.")
                            
                        Text("Limitation of Liability")
                            .font(.headline)
                    }
                        
                        Text("The creators, developers, and distributors of BarBuddy are not responsible for any actions you take while using this app, including but not limited to decisions regarding alcohol consumption, driving, or other potentially dangerous activities.")
                        
                        Text("By using BarBuddy, you acknowledge these limitations and agree to use the app responsibly.")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
            }
            .navigationTitle("Legal Disclaimer")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

// Credits View
struct CreditsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Credits & Acknowledgments")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("BarBuddy was created with the help and contributions of many people and resources.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Development Team
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Development Team")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        CreditsPersonRow(
                            name: "Travis Rodriguez",
                            role: "Lead Developer & Designer"
                        )
                        
                        CreditsPersonRow(
                            name: "Alex Johnson",
                            role: "UX/UI Designer"
                        )
                        
                        CreditsPersonRow(
                            name: "Sam Williams",
                            role: "Backend Developer"
                        )
                        
                        CreditsPersonRow(
                            name: "Jamie Smith",
                            role: "QA & Testing"
                        )
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Research & Consultation
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Research & Consultation")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        CreditsPersonRow(
                            name: "Dr. Elizabeth Chen",
                            role: "Medical Consultant"
                        )
                        
                        CreditsPersonRow(
                            name: "Prof. Robert Thompson",
                            role: "Alcohol Research Specialist"
                        )
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Technologies & Resources
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Technologies & Resources")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        CreditsTechRow(
                            name: "Swift & SwiftUI",
                            description: "Primary development frameworks"
                        )
                        
                        CreditsTechRow(
                            name: "WatchKit",
                            description: "Apple Watch implementation"
                        )
                        
                        CreditsTechRow(
                            name: "CoreData",
                            description: "Data persistence"
                        )
                        
                        CreditsTechRow(
                            name: "SF Symbols",
                            description: "Iconography"
                        )
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Special Thanks
                    VStack(spacing: 10) {
                        Text("Special Thanks")
                            .font(.headline)
                        
                        Text("To all our beta testers, friends, and family who provided valuable feedback during development.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    
                    Text("BarBuddy encourages responsible drinking.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Credits")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Credits person row
struct CreditsPersonRow: View {
    let name: String
    let role: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .fontWeight(.medium)
                
                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

// Credits technology row
struct CreditsTechRow: View {
    let name: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    AboutView()
}
