import Foundation
import Combine

class BACViewModel: ObservableObject {
    private let bacCalculator = BACCalculator()
    private let storageService = StorageService()
    private let notificationService = NotificationService()
    
    @Published var currentBAC: BACEstimate = BACEstimate.empty()
    @Published var isCalculating = false
    @Published var error: String?
    
    // Timer for auto-refreshing BAC
        private var refreshTimer: Timer?
        
        init() {
            // Start refresh timer
            setupRefreshTimer()
        }
        
        deinit {
            refreshTimer?.invalidate()
        }
        
        func calculateBAC() async {
            await MainActor.run {
                isCalculating = true
                error = nil
            }
            
            do {
                // Get current user and drinks from storage
                guard let userId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId),
                      let user = try await storageService.getUser(id: userId) else {
                    await MainActor.run {
                        error = "No user data found"
                        isCalculating = false
                    }
                    return
                }
                
                // Get recent drinks (past 24 hours)
                let drinks = try await storageService.getDrinksInTimeRange(
                    userId: userId,
                    start: Date().addingTimeInterval(-24 * 60 * 60),
                    end: Date()
                )
                
                // Calculate BAC
                let bacEstimate = BACCalculator.calculateBAC(user: user, drinks: drinks)
                
                // Save BAC estimate
                try await storageService.saveBAC(bacEstimate, userId: userId)
                
                // Update UI
                await MainActor.run {
                    currentBAC = bacEstimate
                    isCalculating = false
                    
                    // Log for high BAC levels
                    if bacEstimate.bac >= Constants.BAC.legalLimit {
                        Analytics.shared.logBACUpdate(
                            bac: bacEstimate.bac,
                            isAboveLegalLimit: true
                        )
                    }
                }
                
                // Schedule notifications if BAC is above zero
                if bacEstimate.bac > 0 {
                    notificationService.scheduleBACSoberNotification(estimate: bacEstimate)
                    
                    // Show safety alert if BAC is above legal or high threshold
                    if bacEstimate.bac >= Constants.BAC.legalLimit {
                        notificationService.showSafetyAlert(estimate: bacEstimate)
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to calculate BAC: \(error.localizedDescription)"
                    isCalculating = false
                }
            }
        }
        
        func predictBAC(newDrink: Drink) async -> BACEstimate? {
            do {
                // Get current user and drinks from storage
                guard let userId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId),
                      let user = try await storageService.getUser(id: userId) else {
                    return nil
                }
                
                // Get recent drinks (past 24 hours)
                let drinks = try await storageService.getDrinksInTimeRange(
                    userId: userId,
                    start: Date().addingTimeInterval(-24 * 60 * 60),
                    end: Date()
                )
                
                // Calculate predicted BAC
                return BACCalculator.predictBAC(user: user, currentDrinks: drinks, newDrink: newDrink)
            } catch {
                await MainActor.run {
                    self.error = "Failed to predict BAC: \(error.localizedDescription)"
                }
                return nil
            }
        }
        
        private func setupRefreshTimer() {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
                // Auto-refresh BAC every 15 minutes
                guard let self = self else { return }
                
                Task {
                    await self.calculateBAC()
                }
            }
        }
        
        func refreshBAC() async {
            await calculateBAC()
        }
    }
