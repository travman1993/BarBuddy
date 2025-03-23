import WatchConnectivity
import Foundation
import SwiftUI

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession = .default
    
    // Published properties that will be updated from the phone
    @Published var currentBAC: Double = 0.0
    @Published var timeUntilSober: TimeInterval = 0
    @Published var userWeight: Double = 160.0
    @Published var userGender: String = "male"
    @Published var lastSyncTime: Date? = nil
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func requestInitialData() {
        // Request all necessary data from phone
        requestUserProfile()
        requestLatestBAC()
    }
    
    func requestUserProfile() {
        guard session.activationState == .activated else { return }
        
        let message = ["request": "userProfile"]
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                if let weight = reply["weight"] as? Double {
                    self.userWeight = weight
                }
                
                if let gender = reply["gender"] as? String {
                    self.userGender = gender
                }
            }
        }, errorHandler: { error in
            print("Error requesting user profile: \(error.localizedDescription)")
        })
    }
    
    func requestLatestBAC() {
        guard session.activationState == .activated else { return }
        
        let message = ["request": "latestBAC"]
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                if let bac = reply["currentBAC"] as? Double {
                    self.currentBAC = bac
                }
                
                if let timeUntilSober = reply["timeUntilSober"] as? TimeInterval {
                    self.timeUntilSober = timeUntilSober
                }
                
                self.lastSyncTime = Date()
            }
        }, errorHandler: { error in
            print("Error requesting latest BAC: \(error.localizedDescription)")
        })
    }
    
    func logDrink(type: DrinkType) {
        guard session.activationState == .activated else { return }
        
        let message: [String: Any] = [
            "action": "logDrink",
            "drinkType": type.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                // Update BAC after adding drink
                if let bac = reply["updatedBAC"] as? Double {
                    self.currentBAC = bac
                }
                
                if let timeUntilSober = reply["timeUntilSober"] as? TimeInterval {
                    self.timeUntilSober = timeUntilSober
                }
                
                self.lastSyncTime = Date()
            }
        }, errorHandler: { error in
            print("Error sending drink log: \(error.localizedDescription)")
        })
    }
    
    func updateUserWeight(_ weight: Double) {
        guard session.activationState == .activated else { return }
        
        let message: [String: Any] = [
            "action": "updateWeight",
            "weight": weight
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                // Update local values
                self.userWeight = weight
                
                // Update BAC after weight change
                if let bac = reply["updatedBAC"] as? Double {
                    self.currentBAC = bac
                }
                
                if let timeUntilSober = reply["timeUntilSober"] as? TimeInterval {
                    self.timeUntilSober = timeUntilSober
                }
                
                self.lastSyncTime = Date()
            }
        }, errorHandler: { error in
            print("Error updating weight: \(error.localizedDescription)")
        })
    }
    
    // Required WCSessionDelegate method
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if activationState == .activated {
                // Request initial data upon successful connection
                self.requestInitialData()
            }
        }
    }
    
    // Handle incoming application context (for background updates)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let bac = applicationContext["currentBAC"] as? Double {
                self.currentBAC = bac
            }
            
            if let timeUntilSober = applicationContext["timeUntilSober"] as? TimeInterval {
                self.timeUntilSober = timeUntilSober
            }
            
            self.lastSyncTime = Date()
        }
    }
    
    // Handle incoming user info (for reliable background transfers)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async {
            if let bac = userInfo["currentBAC"] as? Double {
                self.currentBAC = bac
            }
            
            if let timeUntilSober = userInfo["timeUntilSober"] as? TimeInterval {
                self.timeUntilSober = timeUntilSober
            }
            
            self.lastSyncTime = Date()
        }
    }
}
