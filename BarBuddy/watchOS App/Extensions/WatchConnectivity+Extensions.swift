//
//  WatchConnectivity+Extensions.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

// WatchConnectivity+Extensions.swift
// WatchConnectivity+Extensions.swift
import Foundation
import WatchKit

extension WKExtension {
    static var isSupported: Bool {
        #if os(watchOS)
        return true
        #else
        return false
        #endif
    }
    
    func openParentApplication(_ userInfo: [String: Any]) {
        #if os(watchOS)
        self.openParentApplication(userInfo) { _, _ in }
        #endif
    }
}
