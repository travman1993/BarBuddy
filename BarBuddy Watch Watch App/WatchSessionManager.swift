//
//  WatchSessionManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/22/25.
//
import WatchConnectivity
import Foundation
import SwiftUI

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession = .default
    
    // Common properties across platforms
    @Published var lastSyncTime: Date? = nil
    
    // Platform-specific properties
    #if os(iOS)
    // Reference to your drink tracker on iOS
    private var drinkTracker: DrinkTracker?
    #elseif os(watchOS)
    // Published properties for watchOS
    @Published var currentBAC: Double = 0.0
    @Published var timeUntilSober: TimeInterval = 0
    @Published var userWeight: Double = 160.0
    @Published var userGender: String = "male"
    
    // Reference to the DrinkTracker to update it when we get data from phone
    private var drinkTracker: DrinkTracker?
    #endif
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Common Methods
    
    // Set a reference to DrinkTracker
    func setDrinkTracker(_ drinkTracker: DrinkTracker) {
        self.drinkTracker = drinkTracker
    }
    
    // MARK: - iOS-specific Methods
    #if os(iOS)
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
    
    // Handle message from watch for sending SMS
    func handleMessageRequest(recipients: [String], body: String) {
        // This would be implemented on iOS to handle message requests from the watch
        print("Received message request from watch: \(body)")
        // In a real app, this would open a message composer or similar
    }
    
    // MARK: - watchOS-specific Methods
    #elseif os(watchOS)
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
                
                self.lastSyncTime = Date()
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
                    
                    // Update the DrinkTracker if available
                    if let drinkTracker = self.drinkTracker,
                       let timeUntilSober = reply["timeUntilSober"] as? TimeInterval {
                        drinkTracker.updateBACData(bac: bac, timeUntilSober: timeUntilSober)
                    }
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
                    
                    // Update the DrinkTracker if available
                    if let drinkTracker = self.drinkTracker,
                       let timeUntilSober = reply["timeUntilSober"] as? TimeInterval {
                        drinkTracker.updateBACData(bac: bac, timeUntilSober: timeUntilSober)
                    }
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
                    
                    // Update the DrinkTracker if available
                    if let drinkTracker = self.drinkTracker,
                       let timeUntilSober = reply["timeUntilSober"] as? TimeInterval {
                        drinkTracker.updateBACData(bac: bac, timeUntilSober: timeUntilSober)
                    }
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
    
    // Method to request iPhone to send a message
    func sendMessageRequest(recipients: [String], body: String) {
        guard session.activationState == .activated else { return }
        
        let message: [String: Any] = [
            "action": "sendMessage",
            "recipients": recipients,
            "body": body
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            print("Message request sent to iPhone")
        }, errorHandler: { error in
            print("Error sending message request: \(error.localizedDescription)")
        })
    }
    #endif
    
    // MARK: - WCSessionDelegate Methods
    
    // Required WCSessionDelegate method for all platforms
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            print("\(ProcessInfo.processInfo.operatingSystemVersionString) WCSession activated: \(activationState.rawValue), error: \(String(describing: error))")
        
            #if os(watchOS)
            if activationState == .activated {
                // Request initial data upon successful connection
                self.requestInitialData()
            }
            #endif
        }
    }
    
    // Handle incoming messages (common to both platforms)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            #if os(iOS)
            // Handle messages on iOS
            if let drinkTracker = self.drinkTracker {
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
                            
                            // Send back updated BAC
                            let reply: [String: Any] = [
                                "updatedBAC": drinkTracker.currentBAC,
                                "timeUntilSober": drinkTracker.timeUntilSober
                            ]
                            replyHandler(reply)
                        } else {
                            replyHandler(["error": "Invalid weight"])
                        }
                        
                    case "sendMessage":
                        if let recipients = message["recipients"] as? [String],
                           let body = message["body"] as? String {
                            self.handleMessageRequest(recipients: recipients, body: body)
                            replyHandler(["status": "Message request received"])
                        } else {
                            replyHandler(["error": "Invalid message parameters"])
                        }
                        
                    default:
                        replyHandler(["error": "Unknown action"])
                    }
                } else {
                    replyHandler(["error": "Invalid message format"])
                }
            } else {
                replyHandler(["error": "DrinkTracker not set"])
            }
            #elseif os(watchOS)
            // watchOS implementation (if needed)
            replyHandler(["status": "Received on watch"])
            #endif
        }
    }
    
    // Handle incoming application context (for background updates)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            #if os(iOS)
            // iOS specific handling
            print("iOS received application context")
            #elseif os(watchOS)
            // watchOS specific handling
            if let bac = applicationContext["currentBAC"] as? Double {
                self.currentBAC = bac
                
                // Update the DrinkTracker if available
                if let drinkTracker = self.drinkTracker,
                   let timeUntilSober = applicationContext["timeUntilSober"] as? TimeInterval {
                    drinkTracker.updateBACData(bac: bac, timeUntilSober: timeUntilSober)
                }
            }
            
            if let timeUntilSober = applicationContext["timeUntilSober"] as? TimeInterval {
                self.timeUntilSober = timeUntilSober
            }
            
            self.lastSyncTime = Date()
            #endif
        }
    }
    
    // Handle incoming user info (for reliable background transfers)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async {
            #if os(iOS)
            // iOS specific handling
            print("iOS received user info")
            #elseif os(watchOS)
            // watchOS specific handling
            if let bac = userInfo["currentBAC"] as? Double {
                self.currentBAC = bac
                
                // Update the DrinkTracker if available
                if let drinkTracker = self.drinkTracker,
                   let timeUntilSober = userInfo["timeUntilSober"] as? TimeInterval {
                    drinkTracker.updateBACData(bac: bac, timeUntilSober: timeUntilSober)
                }
            }
            
            if let timeUntilSober = userInfo["timeUntilSober"] as? TimeInterval {
                self.timeUntilSober = timeUntilSober
            }
            
            self.lastSyncTime = Date()
            #endif
        }
    }
    
    // iOS-specific required delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iOS WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("iOS WCSession deactivated")
    }
    #endif
}
