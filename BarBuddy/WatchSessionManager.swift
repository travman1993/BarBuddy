//
//  WatchSessionManager.swift
//  BarBuddy
//

//
//  WatchSessionManager.swift
//  BarBuddy
//

import Foundation
import WatchConnectivity

/**
 * Manages communication between the iOS app and Apple Watch app.
 *
 * This class handles sending drink data, and user profile information
 * to the companion Watch app, and processes requests from the Watch.
 */
class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    /// Shared singleton instance
    static let shared = WatchSessionManager()
    
    /// Published properties for tracking session state
    @Published var isReachable = false
    @Published var isWatchAppInstalled = false
    
    /// Session reference
    private var session: WCSession?
    
    /// Drink tracker reference (weak to avoid retain cycle)
    private weak var drinkTracker: DrinkTracker?
    
    /**
     * Initializes the Watch Session Manager.
     */
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    /**
     * Sets up the Watch Connectivity session.
     */
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    /**
     * Sets the drink tracker reference to enable data sharing.
     *
     * - Parameter tracker: The app's DrinkTracker instance
     */
    func setDrinkTracker(_ tracker: DrinkTracker) {
        self.drinkTracker = tracker
    }
    
    /**
     * Sends drink data to the Watch app.
     *
     * - Parameters:
     *   - drinkCount: Current standard drink count
     *   - drinkLimit: User's set drink limit
     *   - timeUntilReset: Time until count resets at 4am
     */
    func sendDrinkDataToWatch(drinkCount: Double, drinkLimit: Double, timeUntilReset: TimeInterval) {
        guard isReachable else { return }
        
        let drinkData: [String: Any] = [
            "drinkCount": drinkCount,
            "drinkLimit": drinkLimit,
            "timeUntilReset": timeUntilReset,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session?.sendMessage(drinkData, replyHandler: nil) { error in
            print("Error sending drink data: \(error.localizedDescription)")
        }
    }
    
    /**
     * Sends user profile information to the Watch app.
     */
    func sendUserProfileToWatch() {
        guard let drinkTracker = drinkTracker, isReachable else { return }
        
        let profileData: [String: Any] = [
            "weight": drinkTracker.userProfile.weight,
            "gender": drinkTracker.userProfile.gender.rawValue,
            "height": drinkTracker.userProfile.height ?? 0
        ]
        
        session?.sendMessage(profileData, replyHandler: nil) { error in
            print("Error sending profile data: \(error.localizedDescription)")
        }
    }
    
    /**
     * Handles incoming messages from the Watch app.
     */
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let request = message["request"] as? String else {
            replyHandler(["error": "Invalid request"])
            return
        }
        
        switch request {
        case "getCurrentDrinkData":
            // Respond with current drink data if available
            guard let drinkTracker = drinkTracker else {
                replyHandler(["error": "Drink tracker not available"])
                return
            }
            
            replyHandler([
                "drinkCount": drinkTracker.standardDrinkCount,
                "drinkLimit": drinkTracker.drinkLimit,
                "timeUntilReset": drinkTracker.timeUntilReset
            ])
            
        case "logDrink":
            // Log a drink from Watch
            guard let drinkType = message["drinkType"] as? String,
                  let type = DrinkType(rawValue: drinkType) else {
                replyHandler(["error": "Invalid drink type"])
                return
            }
            
            // Add drink using default values from drink type
            drinkTracker?.addDrink(
                type: type,
                size: type.defaultSize,
                alcoholPercentage: type.defaultAlcoholPercentage
            )
            
            // Respond with updated drink data
            replyHandler([
                "drinkCount": drinkTracker?.standardDrinkCount ?? 0,
                "drinkLimit": drinkTracker?.drinkLimit ?? 4.0,
                "timeUntilReset": drinkTracker?.timeUntilReset ?? 0
            ])
            
        default:
            replyHandler(["error": "Unknown request"])
        }
    }
    
    // MARK: - WCSessionDelegate Methods
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = (activationState == .activated)
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    // iOS-specific delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Watch session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Watch session deactivated")
        session.activate()
    }
    #endif
    
    /**
     * Checks if Watch connectivity is available and session is active.
     *
     * - Returns: True if Watch connectivity is fully operational
     */
    func isWatchConnectivityAvailable() -> Bool {
        return WCSession.isSupported() &&
               session?.activationState == .activated &&
               session?.isReachable == true
    }
}
