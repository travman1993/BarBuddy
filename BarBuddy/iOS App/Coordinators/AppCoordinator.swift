//
//  AppCoordinator.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

//
//  AppCoordinator.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI
import UIKit
import Combine

// Protocol that all coordinators will conform to
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get }
    
    func start()
    func finish()
}

// Protocol for coordinators that can be dismissed
protocol DismissableCoordinator: Coordinator {
    var parentCoordinator: Coordinator? { get set }
}

// Main app coordinator that manages the flow of the app
class AppCoordinator: NSObject, Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    // ViewModels shared across the app
    private let userViewModel: UserViewModel
    private let drinkViewModel: DrinkViewModel
    private let bacViewModel: BACViewModel
    private let settingsViewModel: SettingsViewModel
    private let emergencyViewModel: EmergencyViewModel
    
    // Services
    private let notificationService = NotificationService()
    private let locationService = LocationService()
    
    // Cancellables for handling subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        
        // Initialize ViewModels
        self.userViewModel = UserViewModel()
        self.drinkViewModel = DrinkViewModel()
        self.bacViewModel = BACViewModel()
        self.settingsViewModel = SettingsViewModel()
        self.emergencyViewModel = EmergencyViewModel()
        
        super.init()
        
        // Set up the navigation bar appearance
        self.setupNavigationBar()
        
        // Subscribe to user changes
        subscribeToUserChanges()
    }
    
    func start() {
        // Request necessary permissions (notifications, location)
        requestPermissions()
        
        // Determine the initial flow based on the user's state
        determineInitialFlow()
    }
    
    func finish() {
        childCoordinators.removeAll()
    }
    
    // MARK: - Setup Methods
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.tintColor = UIColor.systemBlue
    }
    
    private func subscribeToUserChanges() {
        userViewModel.$isFirstLaunch
            .combineLatest(userViewModel.$hasAcceptedDisclaimer)
            .sink { [weak self] isFirstLaunch, hasAcceptedDisclaimer in
                self?.handleUserStateChanged(isFirstLaunch: isFirstLaunch, hasAcceptedDisclaimer: hasAcceptedDisclaimer)
            }
            .store(in: &cancellables)
    }
    
    private func requestPermissions() {
        Task {
            // Request notification permissions
            let granted = await notificationService.requestPermissions()
            
            if granted {
                notificationService.setUpNotificationCategories()
            }
            
            // Request location permissions (if enabled in settings)
            if settingsViewModel.settings.saveLocationData {
                locationService.requestLocationPermission { _ in }
            }
        }
    }
    
    // MARK: - Flow Determination
    
    private func determineInitialFlow() {
        let isFirstLaunch = userViewModel.isFirstLaunch
        let hasAcceptedDisclaimer = userViewModel.hasAcceptedDisclaimer
        
        if isFirstLaunch {
            showOnboarding()
        } else if !hasAcceptedDisclaimer {
            showDisclaimer()
        } else {
            showMainInterface()
        }
    }
    
    private func handleUserStateChanged(isFirstLaunch: Bool, hasAcceptedDisclaimer: Bool) {
        if !isFirstLaunch && hasAcceptedDisclaimer && !(navigationController.visibleViewController is UIHostingController<MainTabView>) {
            showMainInterface()
        }
    }
    
    // MARK: - Navigation Methods
    
    private func showOnboarding() {
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController, userViewModel: userViewModel)
        onboardingCoordinator.parentCoordinator = self
        onboardingCoordinator.start()
        childCoordinators.append(onboardingCoordinator)
    }
    
    private func showDisclaimer() {
        let disclaimerView = DisclaimerView()
            .environmentObject(userViewModel)
        
        let hostingController = UIHostingController(rootView: disclaimerView)
        navigationController.setViewControllers([hostingController], animated: true)
    }
    
    private func showMainInterface() {
        // Load drinks and calculate BAC
        Task {
            await drinkViewModel.loadRecentDrinks(userId: userViewModel.currentUser.id)
            await bacViewModel.calculateBAC()
            await emergencyViewModel.loadContacts(userId: userViewModel.currentUser.id)
        }
        
        // Set up the main interface
        let mainTabView = MainTabView()
            .environmentObject(userViewModel)
            .environmentObject(drinkViewModel)
            .environmentObject(bacViewModel)
            .environmentObject(settingsViewModel)
            .environmentObject(emergencyViewModel)
        
        let hostingController = UIHostingController(rootView: mainTabView)
        navigationController.setViewControllers([hostingController], animated: true)
    }
    
    // MARK: - Coordinator Management
    
    func childDidFinish(_ child: Coordinator) {
        for (index, coordinator) in childCoordinators.enumerated() {
            if coordinator === child {
                childCoordinators.remove(at: index)
                break
            }
        }
    }
}

// Coordinator for handling the onboarding flow
class OnboardingCoordinator: NSObject, DismissableCoordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: Coordinator?
    
    private let userViewModel: UserViewModel
    
    init(navigationController: UINavigationController, userViewModel: UserViewModel) {
        self.navigationController = navigationController
        self.userViewModel = userViewModel
        super.init()
    }
    
    func start() {
        let welcomeView = WelcomeView(coordinator: self)
            .environmentObject(userViewModel)
        
        let hostingController = UIHostingController(rootView: welcomeView)
        navigationController.setViewControllers([hostingController], animated: true)
    }
    
    func finish() {
        guard let appCoordinator = parentCoordinator as? AppCoordinator else { return }
        appCoordinator.childDidFinish(self)
    }
    
    // Navigation methods for the onboarding flow
    func showGenderSelection() {
        let genderSelectionView = GenderSelectionView(coordinator: self)
            .environmentObject(userViewModel)
        
        let hostingController = UIHostingController(rootView: genderSelectionView)
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func showWeightEntry() {
        let weightEntryView = WeightEntryView(coordinator: self)
            .environmentObject(userViewModel)
        
        let hostingController = UIHostingController(rootView: weightEntryView)
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func showUserInfo() {
        let userInfoView = UserInfoView(coordinator: self)
            .environmentObject(userViewModel)
        
        let hostingController = UIHostingController(rootView: userInfoView)
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func completeOnboarding() {
        // Update user model to mark first launch as completed
        Task {
            try? await userViewModel.updateUserProfile(name: userViewModel.currentUser.name)
        }
        
        // Dismiss this coordinator
        finish()
    }
}

// Extension for WelcomeView to use the coordinator
extension WelcomeView {
    init(coordinator: OnboardingCoordinator) {
        self.init()
        // Set up any callbacks or navigation handlers
    }
}

// Extension for GenderSelectionView to use the coordinator
extension GenderSelectionView {
    init(coordinator: OnboardingCoordinator) {
        self.init()
        // Set up any callbacks or navigation handlers
    }
}

// Extension for WeightEntryView to use the coordinator
extension WeightEntryView {
    init(coordinator: OnboardingCoordinator) {
        self.init()
        // Set up any callbacks or navigation handlers
    }
}

// Extension for UserInfoView to use the coordinator
extension UserInfoView {
    init(coordinator: OnboardingCoordinator) {
        self.init()
        // Set up any callbacks or navigation handlers
    }
}
