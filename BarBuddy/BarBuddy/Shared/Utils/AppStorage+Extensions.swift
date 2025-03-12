import Foundation
import SwiftUI

// Extension to handle Codable objects in AppStorage
extension AppStorage {
    init<T: Codable>(wrappedValue: T, _ key: String, store: UserDefaults? = nil) {
        let data = try? JSONEncoder().encode(wrappedValue)
        let stringData = data.map { String(decoding: $0, as: UTF8.self) } ?? "null"
        self.init(wrappedValue: stringData, key, store: store)
    }
    
    init<T: Codable>(_ key: String, store: UserDefaults? = nil) where Value == T {
        self.init(key, store: store) {
            guard let data = UserDefaults.standard.data(forKey: key) else {
                return nil
            }
            return try? JSONDecoder().decode(T.self, from: data)
        } set: { newValue in
            if let value = newValue, let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

// Extension for handling Codable objects in SceneStorage
extension SceneStorage {
    init<T: Codable>(wrappedValue: T, _ key: String) {
        let data = try? JSONEncoder().encode(wrappedValue)
        let stringData = data.map { String(decoding: $0, as: UTF8.self) } ?? "null"
        self.init(wrappedValue: stringData, key)
    }
}
