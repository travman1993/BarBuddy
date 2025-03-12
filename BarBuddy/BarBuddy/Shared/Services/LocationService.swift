import Foundation
import CoreLocation

class LocationService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var locationUpdateHandler: ((Result<CLLocation, Error>) -> Void)?
    private var authorizationStatusHandler: ((CLAuthorizationStatus) -> Void)?
    
    // Error type for location service errors
    enum LocationError: Error, LocalizedError {
        case locationDisabled
        case locationRestricted
        case locationDenied
        case unknownError
        case noLocationAvailable
        
        var errorDescription: String? {
            switch self {
            case .locationDisabled:
                return "Location services are disabled. Please enable location in Settings."
            case .locationRestricted:
                return "Location services are restricted on this device."
            case .locationDenied:
                return "Location permission has been denied. Please enable location in Settings."
            case .unknownError:
                return "An unknown error occurred while accessing location."
            case .noLocationAvailable:
                return "No location data is available."
            }
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // Request location permissions
    func requestLocationPermission(completion: @escaping (CLAuthorizationStatus) -> Void) {
        authorizationStatusHandler = completion
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            completion(locationManager.authorizationStatus)
        }
    }
    
    // Get current location
    func getCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        locationUpdateHandler = completion
        
        // Check if we already have a recent location
        if let location = currentLocation,
           Date().timeIntervalSince(location.timestamp) < 60 { // Within last minute
            completion(.success(location))
            return
        }
        
        // Check authorization status
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied:
            completion(.failure(LocationError.locationDenied))
        case .restricted:
            completion(.failure(LocationError.locationRestricted))
        case .notDetermined:
            authorizationStatusHandler = { status in
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    self.locationManager.requestLocation()
                } else {
                    completion(.failure(LocationError.locationDenied))
                }
            }
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            completion(.failure(LocationError.unknownError))
        }
    }
    
    // Get address from location coordinates
    func getAddressFromLocation(location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(.failure(LocationError.noLocationAvailable))
                return
            }
            
            // Format address
            var addressComponents: [String] = []
            
            if let thoroughfare = placemark.thoroughfare {
                addressComponents.append(thoroughfare)
            }
            
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            
            if let administrativeArea = placemark.administrativeArea {
                addressComponents.append(administrativeArea)
            }
            
            if addressComponents.isEmpty {
                completion(.failure(LocationError.noLocationAvailable))
            } else {
                let address = addressComponents.joined(separator: ", ")
                completion(.success(address))
            }
        }
    }
    
    // Get current location as formatted address
    func getCurrentLocationAddress(completion: @escaping (Result<String, Error>) -> Void) {
        getCurrentLocation { result in
            switch result {
            case .success(let location):
                self.getAddressFromLocation(location: location, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationUpdateHandler?(.failure(LocationError.noLocationAvailable))
            return
        }
        
        currentLocation = location
        locationUpdateHandler?(.success(location))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationUpdateHandler?(.failure(error))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatusHandler?(manager.authorizationStatus)
    }
}
