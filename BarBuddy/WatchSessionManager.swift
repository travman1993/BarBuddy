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
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
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
