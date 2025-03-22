//
//  WatchSessionManager.swift
//  BarBuddy Watch Watch App
//
//  Created by Travis Rodriguez on 3/22/25.
//
import WatchConnectivity
import Foundation
import SwiftUI

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession = .default
    private var pendingDrinks: [DrinkType] = []
    private var pendingTasks: [String: (Bool) -> Void] = [:]
    private var retryTimer: Timer?
    
    // Published properties for reactive UI updates
    @Published var currentBAC: Double = 0.0
    @Published var timeUntilSober: TimeInterval = 0
    @Published var connectionState: ConnectionState = .unknown
    @Published var lastSyncTime: Date? = nil
    
    enum ConnectionState {
        case unknown
        case connected
        case disconnected
        case inactive
    }
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        
        // Load any cached data
        loadCachedBAC()
        
        // Background retrying of pending drinks
        startBackgroundRetryTimer()
    }
    
    deinit {
        retryTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    // Request initial data from phone when app launches
    func requestInitialData() {
        guard session.activationState == .activated else {
            connectionState = .inactive
            return
        }
        
        // Request latest BAC data
        requestLatestBAC()
        
        // Try to send any pending drinks
        retryPendingDrinks()
    }
    
    // Request latest BAC data from iPhone
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
                self.cacheBAC()
            }
        }, errorHandler: { error in
            print("Error requesting latest BAC: \(error.localizedDescription)")
        })
    }
    
    // Log drink with completion handler for UI feedback
    func logDrink(type: DrinkType, completion: @escaping (Bool) -> Void = { _ in }) {
        guard session.activationState == .activated else {
            // Store for later and return failure
            addToPendingDrinks(type: type)
            completion(false)
            return
        }
        
        let requestId = UUID().uuidString
        pendingTasks[requestId] = completion
        
        let message: [String: Any] = [
            "action": "logDrink",
            "drinkType": type.rawValue,
            "requestId": requestId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                let success = reply["success"] as? Bool ?? false
                if let bac = reply["updatedBAC"] as? Double {
                    self.currentBAC = bac
                }
                
                if let timeUntilSober = reply["timeUntilSober"] as? TimeInterval {
                    self.timeUntilSober = timeUntilSober
                }
                
                // Call completion handler if it exists
                if let completion = self.pendingTasks[requestId] {
                    completion(success)
                    self.pendingTasks.removeValue(forKey: requestId)
                }
                
                self.lastSyncTime = Date()
                self.cacheBAC()
            }
        }, errorHandler: { error in
            print("Error sending drink log: \(error.localizedDescription)")
            
            // Store for retry later
            self.addToPendingDrinks(type: type)
            
            // Call completion handler with failure
            DispatchQueue.main.async {
                if let completion = self.pendingTasks[requestId] {
                    completion(false)
                    self.pendingTasks.removeValue(forKey: requestId)
                }
            }
        })
    }
    
    // Request ride service (Uber/Lyft)
    func requestRideService(service: String, completion: @escaping (Bool) -> Void) {
        guard session.activationState == .activated else {
            completion(false)
            return
        }
        
        let requestId = UUID().uuidString
        pendingTasks[requestId] = completion
        
        let message: [String: Any] = [
            "action": "requestRide",
            "service": service,
            "requestId": requestId
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                let success = reply["success"] as? Bool ?? false
                
                // Call completion handler if it exists
                if let completion = self.pendingTasks[requestId] {
                    completion(success)
                    self.pendingTasks.removeValue(forKey: requestId)
                }
            }
        }, errorHandler: { error in
            print("Error requesting ride: \(error.localizedDescription)")
            
            // Call completion handler with failure
            DispatchQueue.main.async {
                if let completion = self.pendingTasks[requestId] {
                    completion(false)
                    self.pendingTasks.removeValue(forKey: requestId)
                }
            }
        })
    }
    
    // Contact emergency contact
    func contactEmergency(completion: @escaping (Bool) -> Void) {
        guard session.activationState == .activated else {
            completion(false)
            return
        }
        
        let requestId = UUID().uuidString
        pendingTasks[requestId] = completion
        
        let message: [String: Any] = [
            "action": "contactEmergency",
            "requestId": requestId
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                let success = reply["success"] as? Bool ?? false
                
                // Call completion handler if it exists
                if let completion = self.pendingTasks[requestId] {
                    completion(success)
                    self.pendingTasks.removeValue(forKey: requestId)
                }
            }
        }, errorHandler: { error in
            print("Error contacting emergency: \(error.localizedDescription)")
            
            // Call completion handler with failure
            DispatchQueue.main.async {
                if let completion = self.pendingTasks[requestId] {
                    completion(false)
                    self.pendingTasks.removeValue(forKey: requestId)
                }
            }
        })
    }
    
    // Share BAC status
    func shareStatus(bac: Double, completion: @escaping (Bool) -> Void) {
        guard session.activationState == .activated else {
            completion(false)
            return
        }
        
        let requestId = UUID().uuidString
        pendingTasks[requestId] = completion
        
        let message: [String: Any] = [
            "action": "shareStatus",
            "bac": bac,
            "requestId": requestId
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                let success = reply["success"] as? Bool ?? false
                
                // Call completion handler if it exists
                if let completion = self.pendingTasks[requestId] {
                    completion(success)
                    self.pendingTasks.removeValue(forKey: requestId)
                }
            }
        }, errorHandler: { error in
            print("Error sharing status: \(error.localizedDescription)")
            
            // Call completion handler with failure
            DispatchQueue.main.async {
                if let completion = self.pendingTasks[requestId] {
                    completion(false)
                    self.pendingTasks.removeValue(forKey: requestId)
                }
            }
        })
    }
    
    // Add drink to pending list for later retry
    func addToPendingDrinks(type: DrinkType) {
        pendingDrinks.append(type)
        savePendingDrinks()
    }
    
    // MARK: - WCSessionDelegate Methods
    
    // Handle incoming data from iOS app
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            if let bac = userInfo["currentBAC"] as? Double {
                self.currentBAC = bac
            }
            
            if let timeUntilSober = userInfo["timeUntilSober"] as? TimeInterval {
                self.timeUntilSober = timeUntilSober
            }
            
            self.lastSyncTime = Date()
            self.cacheBAC()
        }
    }
    
    // Handle immediate message replies
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            // Handle various message types
            if let action = message["action"] as? String {
                switch action {
                case "updateBAC":
                    if let bac = message["currentBAC"] as? Double,
                       let timeUntilSober = message["timeUntilSober"] as? TimeInterval {
                        self.currentBAC = bac
                        self.timeUntilSober = timeUntilSober
                        self.lastSyncTime = Date()
                        self.cacheBAC()
                    }
                    
                    replyHandler(["success": true])
                    
                default:
                    replyHandler(["success": false, "error": "Unknown action"])
                }
            } else {
                replyHandler(["success": false, "error": "Missing action"])
            }
        }
    }
    
    // Session activation completed
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            switch activationState {
            case .activated:
                self.connectionState = .connected
                // Try to sync when activated
                self.requestLatestBAC()
                self.retryPendingDrinks()
            case .inactive:
                self.connectionState = .inactive
            case .notActivated:
                self.connectionState = .disconnected
            @unknown default:
                self.connectionState = .unknown
            }
        }
        
        print("Watch WCSession activated: \(activationState.rawValue), error: \(String(describing: error))")
    }
    
    // MARK: - Private Helper Methods
    
    // Start timer to retry pending operations
    private func startBackgroundRetryTimer() {
        // Try to retry every 30 seconds if we have pending operations
        retryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.retryPendingDrinks()
        }
    }
    
    // Retry sending pending drinks
    private func retryPendingDrinks() {
        guard !pendingDrinks.isEmpty, session.activationState == .activated else {
            return
        }
        
        // Make a copy to avoid concurrent modification
        let drinksToRetry = pendingDrinks
        
        // Clear the list first to avoid duplicates
        pendingDrinks.removeAll()
        savePendingDrinks()
        
        // Try to send each drink
        for drinkType in drinksToRetry {
            logDrink(type: drinkType) { success in
                // If failed again, re-add to pending list
                if !success {
                    DispatchQueue.main.async {
                        self.addToPendingDrinks(type: drinkType)
                    }
                }
            }
        }
    }
    
    // Cache BAC for offline access
    private func cacheBAC() {
        UserDefaults.standard.set(currentBAC, forKey: "cachedBAC")
        UserDefaults.standard.set(timeUntilSober, forKey: "cachedTimeUntilSober")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastSyncTimestamp")
    }
    
    // Load cached BAC
    private func loadCachedBAC() {
        if let cachedBAC = UserDefaults.standard.object(forKey: "cachedBAC") as? Double {
            currentBAC = cachedBAC
        }
        
        if let cachedTime = UserDefaults.standard.object(forKey: "cachedTimeUntilSober") as? TimeInterval {
            timeUntilSober = cachedTime
        }
        
        if let lastSync = UserDefaults.standard.object(forKey: "lastSyncTimestamp") as? TimeInterval {
            lastSyncTime = Date(timeIntervalSince1970: lastSync)
        }
        
        // Load pending drinks
        loadPendingDrinks()
    }
    
    // Save pending drinks for retry
    private func savePendingDrinks() {
        let drinkTypes = pendingDrinks.map { $0.rawValue }
        UserDefaults.standard.set(drinkTypes, forKey: "pendingDrinks")
    }
    
    // Load pending drinks
    private func loadPendingDrinks() {
        if let pendingDrinkStrings = UserDefaults.standard.stringArray(forKey: "pendingDrinks") {
            pendingDrinks = pendingDrinkStrings.compactMap { DrinkType(rawValue: $0) }
        }
    }
}

// Extension for DrinkTracker to update from watch
extension DrinkTracker {
    func updateBACFromWatch(bac: Double, timeUntilSober: TimeInterval) {
        // This is a simplified method for the watch app to update BAC values
        // without recalculating everything - it just uses the values from the phone
        self.currentBAC = bac
        self.timeUntilSober = timeUntilSober
    }
}
