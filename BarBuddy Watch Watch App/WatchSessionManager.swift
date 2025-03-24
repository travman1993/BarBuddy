#if os(watchOS)
import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession = .default
    
    // Published properties to update the UI when changed
    @Published var isConnected: Bool = false
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated: \(activationState.rawValue)")
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
    }
    
    // Methods to match DrinkTracker's expectations
    func logDrink(type: DrinkType) {
        let message: [String: Any] = [
            "action": "logDrink",
            "drinkType": type.rawValue
        ]
        sendMessageToPhone(message)
    }
    
    // Receive BAC updates from the phone
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        // Process BAC data from phone
        DispatchQueue.main.async {
            if let bac = userInfo["currentBAC"] as? Double,
               let timeUntilSober = userInfo["timeUntilSober"] as? TimeInterval {
                NotificationCenter.default.post(
                    name: Notification.Name("BACDataReceived"),
                    object: nil,
                    userInfo: [
                        "bac": bac,
                        "timeUntilSober": timeUntilSober
                    ]
                )
            }
        }
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
    
    // Request initial data from the iPhone when the Watch app starts
    func requestInitialData() {
        let message: [String: Any] = [
            "request": "initialData"
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
