import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @State private var currentStep: OnboardingStep = .welcome
    
    enum OnboardingStep {
        case welcome
        case gender
        case weight
        case userInfo
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Content based on current step
                switch currentStep {
                case .welcome:
                    WelcomeView(coordinator: nil)
                        .environmentObject(userViewModel)
                        .transition(.opacity)
                case .gender:
                    GenderSelectionView(coordinator: nil)
                        .environmentObject(userViewModel)
                        .transition(.opacity)
                case .weight:
                    WeightEntryView(coordinator: nil)
                        .environmentObject(userViewModel)
                        .transition(.opacity)
                case .userInfo:
                    UserInfoView(coordinator: nil)
                        .environmentObject(userViewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: currentStep)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        // Custom navigation handling to override native NavLink behavior
        .environment(\.onboardingNavigation, OnboardingNavigation(
            goToNext: goToNextStep,
            goToPrevious: goToPreviousStep,
            completeOnboarding: completeOnboarding
        ))
    }
    
    private func goToNextStep() {
        withAnimation {
            switch currentStep {
            case .welcome:
                currentStep = .gender
            case .gender:
                currentStep = .weight
            case .weight:
                currentStep = .userInfo
            case .userInfo:
                // This is handled separately in completeOnboarding
                break
            }
        }
    }
    
    private func goToPreviousStep() {
        withAnimation {
            switch currentStep {
            case .welcome:
                // Already at first step, do nothing
                break
            case .gender:
                currentStep = .welcome
            case .weight:
                currentStep = .gender
            case .userInfo:
                currentStep = .weight
            }
        }
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasSeenOnboarding)
        
        // This will automatically trigger a state change in the main app
        // and show the disclaimer view
    }
}

// Environment key to handle navigation in onboarding
struct OnboardingNavigationKey: EnvironmentKey {
    static let defaultValue = OnboardingNavigation()
}

extension EnvironmentValues {
    var onboardingNavigation: OnboardingNavigation {
        get { self[OnboardingNavigationKey.self] }
        set { self[OnboardingNavigationKey.self] = newValue }
    }
}

struct OnboardingNavigation {
    var goToNext: () -> Void = {}
    var goToPrevious: () -> Void = {}
    var completeOnboarding: () -> Void = {}
}

// Extension for WelcomeView to support navigation
extension WelcomeView {
    @Environment(\.onboardingNavigation) private var navigation
    
    private func next() {
        navigation.goToNext()
    }
}

// Extension for GenderSelectionView to support navigation
extension GenderSelectionView {
    @Environment(\.onboardingNavigation) private var navigation
    
    private func next() {
        navigation.goToNext()
    }
    
    private func previous() {
        navigation.goToPrevious()
    }
}

// Extension for WeightEntryView to support navigation
extension WeightEntryView {
    @Environment(\.onboardingNavigation) private var navigation
    
    private func next() {
        navigation.goToNext()
    }
    
    private func previous() {
        navigation.goToPrevious()
    }
}

// Extension for UserInfoView to support navigation
extension UserInfoView {
    @Environment(\.onboardingNavigation) private var navigation
    
    private func complete() {
        navigation.completeOnboarding()
    }
    
    private func previous() {
        navigation.goToPrevious()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(UserViewModel())
    }
}
