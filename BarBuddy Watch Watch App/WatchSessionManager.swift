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
    
    @Published var currentBAC: Double = 0.0
    @Published var timeUntilSober: TimeInterval = 0
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // Handle incoming data from iOS app
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            if let bac = userInfo["currentBAC"] as? Double {
                self.currentBAC = bac
            }
            
            if let timeUntilSober = userInfo["timeUntilSober"] as? TimeInterval {
                self.timeUntilSober = timeUntilSober
            }
        }
    }
    
    // Send drink logs to iOS app
    func logDrink(type: DrinkType) {
        if session.activationState == .activated {
            let data: [String: Any] = [
                "action": "logDrink",
                "drinkType": type.rawValue
            ]
            
            session.transferUserInfo(data)
        }
    }
    
    // Required WCSessionDelegate method
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch WCSession activated: \(activationState.rawValue), error: \(String(describing: error))")
    }
}
