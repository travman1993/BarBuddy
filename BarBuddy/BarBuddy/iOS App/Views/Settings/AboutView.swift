
import SwiftUI
import SafariServices

struct AboutView: View {
    @State private var showingLegalSheet = false
    @State private var selectedLegalDocument: LegalDocument?
    
    enum LegalDocument: String, Identifiable {
        case privacyPolicy = "Privacy Policy"
        case termsOfService = "Terms of Service"
        case disclaimer = "Disclaimer"
        
        var id: String { self.rawValue }
        
        var url: URL? {
            switch self {
            case .privacyPolicy:
                return URL(string: Constants.App.privacyPolicyURL)
            case .termsOfService:
                return URL(string: Constants.App.termsOfServiceURL)
            case .disclaimer:
                return nil // This is shown in-app
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                // App logo
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "mug.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        Text(Constants.App.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version \(Constants.App.version) (\(Constants.App.build))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
            }
            .listRowBackground(Color.clear)
            
            Section(header: Text("App Information")) {
                // App details
                NavigationLink(destination: AppFeaturesView()) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.blue)
                        Text("Features")
                    }
                }
                
                NavigationLink(destination: BACAwarenessView()) {
                    HStack {
                        Image(systemName: "gauge")
                            .foregroundColor(.blue)
                        Text("BAC Information")
                    }
                }
                
                NavigationLink(destination: SafetyTipsView()) {
                    HStack {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundColor(.blue)
                        Text("Alcohol Safety")
                    }
                }
            }
            
            Section(header: Text("Support")) {
                // Feedback
                Button {
                    sendFeedbackEmail()
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("Contact Support")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Rate app
                Button {
                    rateApp()
                } label: {
                    HStack {
                        Image(systemName: "star.bubble.fill")
                            .foregroundColor(.blue)
                        Text("Rate the App")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Share app
                Button {
                    shareApp()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("Share the App")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Legal")) {
                // Privacy Policy
                Button {
                    selectedLegalDocument = .privacyPolicy
                    showingLegalSheet = true
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.blue)
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Terms of Service
                Button {
                    selectedLegalDocument = .termsOfService
                    showingLegalSheet = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Disclaimer
                Button {
                    selectedLegalDocument = .disclaimer
                    showingLegalSheet = true
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.blue)
                        Text("Disclaimer")
                    }
                }
            }
            
            Section {
                // Credits
                Text("© \(Calendar.current.component(.year, from: Date())) \(Constants.App.name)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("About")
        .sheet(isPresented: $showingLegalSheet) {
            if let document = selectedLegalDocument {
                if document == .disclaimer {
                    DisclaimerContentView()
                } else if let url = document.url {
                    SafariView(url: url)
                }
            }
        }
    }
    
    // Actions
    private func sendFeedbackEmail() {
        if let url = URL(string: "mailto:\(Constants.App.supportEmail)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: Constants.App.appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareApp() {
        let activityVC = UIActivityViewController(
            activityItems: [
                "Check out \(Constants.App.name): \(Constants.App.appStoreURL)"
            ],
            applicationActivities: nil
        )
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// Safari view controller wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
            // Nothing to update
        }
    }

    // Disclaimer content view
    struct DisclaimerContentView: View {
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DISCLAIMER")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 8)
                        
                        Text(Constants.Strings.disclaimerText)
                            .padding(.bottom, 16)
                        
                        Text("ADDITIONAL HEALTH INFORMATION")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        Text("Excessive alcohol consumption poses serious health risks, including but not limited to liver damage, addiction, increased risk of accidents, and impaired judgment. If you believe you may have a drinking problem, please seek professional help.")
                            .padding(.bottom, 16)
                        
                        Text("ACCURACY OF BAC CALCULATIONS")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        Text("Blood Alcohol Content (BAC) calculations are based on the Widmark formula and are intended to provide estimates only. Actual BAC can be affected by many factors including metabolism, food consumption, medication, and health conditions. The only accurate way to measure BAC is through proper blood, breath, or urine testing.")
                    }
                    .padding()
                }
                .navigationTitle("Disclaimer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // App features view
    struct AppFeaturesView: View {
        var body: some View {
            List {
                Section {
                    FeatureRow(
                        title: "Real-time BAC Tracking",
                        description: "Estimate your Blood Alcohol Content based on your drinks and physical characteristics",
                        icon: "gauge"
                    )
                    
                    FeatureRow(
                        title: "Drink Logging",
                        description: "Record beers, wines, liquors, and custom drinks with precise alcohol content",
                        icon: "list.bullet"
                    )
                    
                    FeatureRow(
                        title: "Safe-to-Drive Timer",
                        description: "Know exactly when it's safe to drive again after drinking",
                        icon: "timer"
                    )
                    
                    FeatureRow(
                        title: "Emergency Contacts",
                        description: "Set up trusted contacts who can be notified in case of emergency",
                        icon: "person.crop.circle.badge.exclamationmark"
                    )
                    
                    FeatureRow(
                        title: "Apple Watch Support",
                        description: "Track your BAC and add drinks directly from your Apple Watch",
                        icon: "applewatch"
                    )
                    
                    FeatureRow(
                        title: "Ride Services",
                        description: "Quickly access ride sharing services to get home safely",
                        icon: "car.fill"
                    )
                    
                    FeatureRow(
                        title: "Privacy-Focused",
                        description: "All your data stays on your device - no data is shared without your consent",
                        icon: "hand.raised.fill"
                    )
                }
            }
            .navigationTitle("Features")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    struct FeatureRow: View {
        let title: String
        let description: String
        let icon: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
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
            .padding(.vertical, 8)
        }
    }

    // BAC Awareness View
    struct BACAwarenessView: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // What is BAC
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is BAC?")
                            .font(.headline)
                        
                        Text("Blood Alcohol Content (BAC) is the percentage of alcohol in your bloodstream. For example, a BAC of 0.08% means that 0.08% of your bloodstream is alcohol.")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    
                    // BAC Levels
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BAC Levels & Effects")
                            .font(.headline)
                        
                        BACLevelRow(
                            level: "0.020-0.039%",
                            effects: "Mild euphoria, relaxation, slight impairment in reasoning and memory",
                            color: Color.safeBAC
                        )
                        
                        BACLevelRow(
                            level: "0.040-0.059%",
                            effects: "Feeling of wellbeing, lower inhibitions, slight impairment of judgment",
                            color: Color.safeBAC
                        )
                        
                        BACLevelRow(
                            level: "0.060-0.079%",
                            effects: "Slight impairment of balance, speech, vision, and control",
                            color: Color.cautionBAC
                        )
                        
                        BACLevelRow(
                            level: "0.080-0.099%",
                            effects: "Legal intoxication in most states. Significant impairment of motor coordination and judgment",
                            color: Color.dangerBAC
                        )
                        
                        BACLevelRow(
                            level: "0.100-0.129%",
                            effects: "Clear deterioration of reaction time and control, slurred speech, poor coordination",
                            color: Color.dangerBAC
                        )
                        
                        BACLevelRow(
                            level: "0.130-0.159%",
                            effects: "Major impairment of physical and mental control, blurred vision, lack of balance",
                            color: Color.dangerBAC
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    
                    // Safe drinking
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Safe Drinking Tips")
                            .font(.headline)
                        
                        BulletPointView(text: "Drink slowly and alternate with water")
                        BulletPointView(text: "Eat before and while drinking")
                        BulletPointView(text: "Know your limits and stick to them")
                        BulletPointView(text: "Plan a safe ride home before drinking")
                        BulletPointView(text: "Never drink and drive, regardless of BAC")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    
                    // Disclaimer
                    Text("Remember: BAC calculators provide estimates only. Actual impairment can vary significantly between individuals, and it's always best to err on the side of caution.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("BAC Information")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    struct BACLevelRow: View {
        let level: String
        let effects: String
        let color: Color
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .frame(width: 4, height: nil)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(effects)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    struct AboutView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                AboutView()
            }
        }
    }
