import WatchConnectivity
import Foundation

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession = .default
    
    // Reference to your drink tracker
    private var drinkTracker: DrinkTracker?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // Set a reference to your drink tracker
    func setDrinkTracker(_ drinkTracker: DrinkTracker) {
        self.drinkTracker = drinkTracker
    }
    
    // Send BAC data to Watch
    func sendBACDataToWatch(bac: Double, timeUntilSober: TimeInterval) {
        if session.activationState == .activated {
            let data: [String: Any] = [
                "currentBAC": bac,
                "timeUntilSober": timeUntilSober
            ]
            
            session.transferUserInfo(data)
        }
    }
    
    // Handle messages from the watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let drinkTracker = drinkTracker else {
            replyHandler(["error": "DrinkTracker not set"])
            return
        }
        
        // Handle various request types
        if let request = message["request"] as? String {
            switch request {
            case "userProfile":
                // Send user profile data
                let reply: [String: Any] = [
                    "weight": drinkTracker.userProfile.weight,
                    "gender": drinkTracker.userProfile.gender.rawValue.lowercased()
                ]
                replyHandler(reply)
                
            case "latestBAC":
                // Send latest BAC data
                let reply: [String: Any] = [
                    "currentBAC": drinkTracker.currentBAC,
                    "timeUntilSober": drinkTracker.timeUntilSober
                ]
                replyHandler(reply)
                
            default:
                replyHandler(["error": "Unknown request"])
            }
        }
        // Handle various action types
        else if let action = message["action"] as? String {
            switch action {
            case "logDrink":
                if let drinkTypeString = message["drinkType"] as? String,
                   let drinkType = DrinkType(rawValue: drinkTypeString) {
                    
                    // Add the drink
                    drinkTracker.addDrink(
                        type: drinkType,
                        size: drinkType.defaultSize,
                        alcoholPercentage: drinkType.defaultAlcoholPercentage
                    )
                    
                    // Send back updated BAC
                    let reply: [String: Any] = [
                        "updatedBAC": drinkTracker.currentBAC,
                        "timeUntilSober": drinkTracker.timeUntilSober
                    ]
                    replyHandler(reply)
                } else {
                    replyHandler(["error": "Invalid drink type"])
                }
                
            case "updateWeight":
                if let weight = message["weight"] as? Double {
                    // Update the user's weight
                    var updatedProfile = drinkTracker.userProfile
                    updatedProfile.weight = weight
                    drinkTracker.updateUserProfile(updatedProfile)
                    
                    // Send back updated BAC (which was recalculated with new weight)
                    let reply: [String: Any] = [
                        "updatedBAC": drinkTracker.currentBAC,
                        "timeUntilSober": drinkTracker.timeUntilSober
                    ]
                    replyHandler(reply)
                } else {
                    replyHandler(["error": "Invalid weight"])
                }
                
            default:
                replyHandler(["error": "Unknown action"])
            }
        } else {
            replyHandler(["error": "Invalid message format"])
        }
    }
    
    // Required WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iOS WCSession activated: \(activationState.rawValue), error: \(String(describing: error))")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iOS WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("iOS WCSession deactivated")
    }
}
