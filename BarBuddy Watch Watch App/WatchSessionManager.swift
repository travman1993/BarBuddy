//
//  WatchSessionManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/22/25.
//
import WatchConnectivity
import Foundation

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession = .default
    
    // Lightweight reference to drink tracker
    private weak var drinkTracker: DrinkTracker?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func setDrinkTracker(_ tracker: DrinkTracker) {
        self.drinkTracker = tracker
    }
    
    // Request full data sync from iPhone
    func requestInitialData() {
        guard session.activationState == .activated else { return }
        
        let message = ["request": "fullDataSync"]
        session.sendMessage(message) { [weak self] reply in
            DispatchQueue.main.async {
                if let drinks = reply["drinks"] as? [Drink],
                   let bac = reply["currentBAC"] as? Double,
                   let timeUntilSober = reply["timeUntilSober"] as? TimeInterval {
                    self?.drinkTracker?.updateFromiPhone(
                        drinks: drinks,
                        bac: bac,
                        timeUntilSober: timeUntilSober
                    )
                }
            }
        }
    }
    
    // Log drink via iPhone
    func logDrink(type: DrinkType) {
        guard session.activationState == .activated else { return }
        
        let message: [String: Any] = [
            "action": "logDrink",
            "drinkType": type.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message) { [weak self] reply in
            DispatchQueue.main.async {
                if let bac = reply["updatedBAC"] as? Double,
                   let timeUntilSober = reply["timeUntilSober"] as? TimeInterval,
                   let drinks = reply["drinks"] as? [Drink] {
                    self?.drinkTracker?.updateFromiPhone(
                        drinks: drinks,
                        bac: bac,
                        timeUntilSober: timeUntilSober
                    )
                }
            }
        }
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated: \(activationState.rawValue)")
        if activationState == .activated {
            requestInitialData()
        }
    }
    
    // Handle background updates
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            if let drinks = userInfo["drinks"] as? [Drink],
               let bac = userInfo["currentBAC"] as? Double,
               let timeUntilSober = userInfo["timeUntilSober"] as? TimeInterval {
                self?.drinkTracker?.updateFromiPhone(
                    drinks: drinks,
                    bac: bac,
                    timeUntilSober: timeUntilSober
                )
            }
        }
    }
}
