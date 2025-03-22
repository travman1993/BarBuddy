import WatchConnectivity
import Foundation
import SwiftUI

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession = .default
    
    @Published var currentBAC: Double = 0.0
    @Published var timeUntilSober: TimeInterval = 0
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // Basic method to log a drink
    func logDrink(type: DrinkType) {
        guard session.activationState == .activated else { return }
        
        let message: [String: Any] = [
            "action": "logDrink",
            "drinkType": type.rawValue
        ]
        
        session.sendMessage(message, replyHandler: { _ in
            // Success
        }, errorHandler: { error in
            print("Error sending drink log: \(error.localizedDescription)")
        })
    }
    
    // WCSessionDelegate methods - minimal implementation
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation completion
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Required for iOS
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Required for iOS
    }
    #endif
}
