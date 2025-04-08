//
//  LocationManager.swift
//  BarBuddy
//

import Foundation
import CoreLocation
import Combine

/**
 * Manages location services for the app.
 *
 * This class handles getting the user's current location,
 * requesting permissions, and providing location data for emergency sharing.
 */
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    /// Shared singleton instance
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    /// Published properties for location status and data
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published var currentPlacemark: CLPlacemark?
    
    /**
     * Initializes the LocationManager and sets up the delegate.
     */
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    /**
     * Requests permission to access the user's location while the app is in use.
     */
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /**
     * Starts monitoring the user's location.
     */
    func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    /**
     * Stops monitoring the user's location to save battery.
     */
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    /**
     * Returns a human-readable string representing the user's current location.
     *
     * - Returns: String containing city and state/province, or "Location unavailable"
     */
    func getLocationString() -> String {
        guard let placemark = currentPlacemark else {
            return "Location unavailable"
        }
        
        // Create a simple location string
        var locationString = ""
        
        if let locality = placemark.locality {
            locationString += locality
        }
        
        if let administrativeArea = placemark.administrativeArea {
            if !locationString.isEmpty {
                locationString += ", "
            }
            locationString += administrativeArea
        }
        
        return locationString.isEmpty ? "Location unavailable" : locationString
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        
        // Reverse geocode to get placemark
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            self?.currentPlacemark = placemarks?.first
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
