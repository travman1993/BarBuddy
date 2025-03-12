import SwiftUI

struct DisclaimerView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @State private var disclaimer1Accepted = false
    @State private var disclaimer2Accepted = false
    @State private var isAccepting = false
    
    private var canAccept: Bool {
        disclaimer1Accepted && disclaimer2Accepted
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.UI.standardPadding) {
                    // Warning Icon
                    HStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, Constants.UI.largePadding)
                    
                    // Title
                    Text("Please Read Carefully")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, Constants.UI.smallPadding)
                    
                    // Disclaimer Text
                    Text(Constants.Strings.disclaimerText)
                        .padding(.bottom, Constants.UI.standardPadding)
                    
                    // Health Warning
                    Text("Additional Health Warning")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.bottom, Constants.UI.smallPadding)
                    
                    Text("Excessive alcohol consumption poses serious health risks, including but not limited to liver damage, addiction, increased risk of accidents, and impaired judgment. If you believe you may have a drinking problem, please seek professional help.")
                        .padding(.bottom, Constants.UI.standardPadding)
                    
                    // Checkboxes
                    VStack(alignment: .leading, spacing: Constants.UI.smallPadding) {
                        Toggle(isOn: $disclaimer1Accepted) {
                            Text("I understand that BAC estimates provided by BarBuddy are approximate and should not be used to determine if I am legally fit to drive.")
                                .fontWeight(.semibold)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        
                        Toggle(isOn: $disclaimer2Accepted) {
                            Text("I understand that the only truly safe amount of alcohol to consume before driving is ZERO.")
                                .fontWeight(.semibold)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                    }
                    .padding(.vertical, Constants.UI.standardPadding)
                    
                    // Accept Button
                    Button {
                        acceptDisclaimer()
                    } label: {
                        if isAccepting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("I UNDERSTAND AND AGREE")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(canAccept ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
                    .disabled(!canAccept || isAccepting)
                    .padding(.vertical, Constants.UI.smallPadding)
                }
                .padding()
            }
            .navigationTitle("Important Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func acceptDisclaimer() {
        guard canAccept else { return }
        
        isAccepting = true
        
        Task {
            do {
                try await userViewModel.acceptDisclaimer()
            } catch {
                print("Error accepting disclaimer: \(error)")
            }
            
            if Task.isCancelled { return }
            isAccepting = false
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .font(.system(size: 22))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerView()
            .environmentObject(UserViewModel())
    }
}
