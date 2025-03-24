#if os(watchOS)
import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession = .default
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated: \(activationState.rawValue)")
    }
    
    // Methods to match DrinkTracker's expectations
    func logDrink(type: DrinkType) {
        let message: [String: Any] = [
            "action": "logDrink",
            "drinkType": type.rawValue
        ]
        sendMessageToPhone(message)
    }
    
    func removeDrink(_ drink: Drink) {
        let message: [String: Any] = [
            "action": "removeDrink",
            "drinkId": drink.id.uuidString
        ]
        sendMessageToPhone(message)
    }
    
    func clearDrinks() {
        let message: [String: Any] = [
            "action": "clearDrinks"
        ]
        sendMessageToPhone(message)
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        let message: [String: Any] = [
            "action": "updateUserProfile",
            "weight": profile.weight,
            "gender": profile.gender.rawValue
        ]
        sendMessageToPhone(message)
    }
    
    // Helper method to send messages to phone
    private func sendMessageToPhone(_ message: [String: Any]) {
        guard session.activationState == .activated else { return }
        
        session.sendMessage(message) { reply in
            print("Message sent to phone: \(reply)")
        } errorHandler: { error in
            print("Error sending message to phone: \(error)")
        }
    }
}
#endif
