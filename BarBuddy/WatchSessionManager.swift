import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    // Singleton instance
    static let shared = WatchSessionManager()
    
    // Published properties for tracking session state
    @Published var isReachable = false
    @Published var isWatchAppInstalled = false
    
    // Session reference
    private var session: WCSession?
    
    // Drink tracker reference (weak to avoid retain cycle)
    private weak var drinkTracker: DrinkTracker?
    
    // Override initializer
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // Setup Watch Connectivity
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // Set drink tracker reference
    func setDrinkTracker(_ tracker: DrinkTracker) {
        self.drinkTracker = tracker
    }
    
    // MARK: - Data Transmission Methods
    
    /// Send BAC data to Watch
    func sendBACDataToWatch(bac: Double, timeUntilSober: TimeInterval) {
        guard isReachable else { return }
        
        let bacData: [String: Any] = [
            "currentBAC": bac,
            "timeUntilSober": timeUntilSober,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session?.sendMessage(bacData, replyHandler: nil) { error in
            print("Error sending BAC data: \(error.localizedDescription)")
        }
    }
    
    /// Send user profile to Watch
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
    
    /// Handle incoming messages from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let request = message["request"] as? String else {
            replyHandler(["error": "Invalid request"])
            return
        }
        
        switch request {
        case "getCurrentBAC":
            // Respond with current BAC if available
            guard let drinkTracker = drinkTracker else {
                replyHandler(["error": "Drink tracker not available"])
                return
            }
            
            replyHandler([
                "currentBAC": drinkTracker.currentBAC,
                "timeUntilSober": drinkTracker.timeUntilSober
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
            
            // Respond with updated BAC
            replyHandler([
                "currentBAC": drinkTracker?.currentBAC ?? 0,
                "timeUntilSober": drinkTracker?.timeUntilSober ?? 0
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
    
    // MARK: - Utility Methods
    
    /// Check if Watch connectivity is supported and session is active
    func isWatchConnectivityAvailable() -> Bool {
        return WCSession.isSupported() &&
               session?.activationState == .activated &&
               session?.isReachable == true
    }
    
    /// Transfer file to Watch (for larger data)
    func transferFileToWatch(fileURL: URL, metadata: [String: Any] = [:]) {
        guard isReachable else { return }
        
        do {
            try session?.transferFile(fileURL, metadata: metadata)
        } catch {
            print("Error transferring file to Watch: \(error.localizedDescription)")
            // Add any additional error handling you need
        }
    }
}
