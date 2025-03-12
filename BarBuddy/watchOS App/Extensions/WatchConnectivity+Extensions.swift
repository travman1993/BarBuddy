//
//  WatchConnectivity+Extensions.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
    }
    
    func startSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        switch activationState {
        case .activated:
            print("Watch connectivity session activated")
        case .inactive:
            print("Watch connectivity session inactive")
        case .notActivated:
            print("Watch connectivity session not activated")
        @unknown default:
            break
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]?) -> Void)? = nil) {
        guard WCSession.default.isReachable else {
            print("Watch session not reachable")
            return
        }
        
        WCSession.default.sendMessage(message, replyHandler: replyHandler) { error in
            print("Error sending message: \(error.localizedDescription)")
        }
    }
}
