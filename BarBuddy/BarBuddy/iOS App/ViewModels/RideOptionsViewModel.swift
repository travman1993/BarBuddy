//
//  RideOptionsViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

//
//  RideOptionsViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import Foundation
import Combine
import MapKit

class RideOptionsViewModel: ObservableObject {
    // Location service
    private let locationService = LocationService()
    
    // Published properties
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var currentLocation: CLLocation? = nil
    @Published var currentAddress: String = "Determining location..."
    @Published var rideOptions: [RideOption] = []
    
    // Ride service options
    struct RideOption: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let estimatedPrice: String?
        let estimatedTime: String?
        let deepLinkURL: URL?
        let appStoreURL: URL?
        
        var isInstalled: Bool {
            guard let url = deepLinkURL else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }
    
    init() {
        // Initialize with common ride services
        rideOptions = [
            RideOption(
                name: "Uber",
                icon: "uber_icon",
                estimatedPrice: nil,
                estimatedTime: nil,
                deepLinkURL: URL(string: "uber://"),
                appStoreURL: URL(string: "https://apps.apple.com/us/app/uber/id368677368")
            ),
            RideOption(
                name: "Lyft",
                icon: "lyft_icon",
                estimatedPrice: nil,
                estimatedTime: nil,
                deepLinkURL: URL(string: "lyft://"),
                appStoreURL: URL(string: "https://apps.apple.com/us/app/lyft/id529379082")
            ),
            RideOption(
                name: "Taxi",
                icon: "taxi_icon",
                estimatedPrice: nil,
                estimatedTime: nil,
                deepLinkURL: nil,
                appStoreURL: nil
            ),
            RideOption(
                name: "Call a Friend",
                icon: "phone.fill",
                estimatedPrice: "Free",
                estimatedTime: nil,
                deepLinkURL: nil,
                appStoreURL: nil
            )
        ]
    }
    
    // MARK: - Location Methods
    
    func refreshLocation() {
        isLoading = true
        error = nil
        
        locationService.getCurrentLocation { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let location):
                self.currentLocation = location
                self.getAddressFromLocation(location)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.error = "Could not determine location: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getAddressFromLocation(_ location: CLLocation) {
        locationService.getAddressFromLocation(location: location) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let address):
                    self.currentAddress = address
                    self.fetchRideEstimates()
                case .failure(let error):
                    self.error = "Could not determine address: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Ride Services
    
    private func fetchRideEstimates() {
        // In a real app, this would integrate with ride service APIs
        // For now, we'll simulate the estimates
        
        let delay = Double.random(in: 0.5...1.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            // Update ride options with estimates
            self.updateRideEstimates()
            self.isLoading = false
        }
    }
    
    private func updateRideEstimates() {
        // Simulate ride estimates
        var updatedOptions = rideOptions
        
        // Uber estimate
        if let index = updatedOptions.firstIndex(where: { $0.name == "Uber" }) {
            updatedOptions[index] = RideOption(
                name: "Uber",
                icon: "uber_icon",
                estimatedPrice: "$15-20",
                estimatedTime: "5 min",
                deepLinkURL: URL(string: "uber://"),
                appStoreURL: URL(string: "https://apps.apple.com/us/app/uber/id368677368")
            )
        }
        
        // Lyft estimate
        if let index = updatedOptions.firstIndex(where: { $0.name == "Lyft" }) {
            updatedOptions[index] = RideOption(
                name: "Lyft",
                icon: "lyft_icon",
                estimatedPrice: "$14-18",
                estimatedTime: "6 min",
                deepLinkURL: URL(string: "lyft://"),
                appStoreURL: URL(string: "https://apps.apple.com/us/app/lyft/id529379082")
            )
        }
        
        // Taxi estimate
        if let index = updatedOptions.firstIndex(where: { $0.name == "Taxi" }) {
            updatedOptions[index] = RideOption(
                name: "Taxi",
                icon: "taxi_icon",
                estimatedPrice: "$22-25",
                estimatedTime: "10-15 min",
                deepLinkURL: nil,
                appStoreURL: nil
            )
        }
        
        rideOptions = updatedOptions
    }
    
    // MARK: - Actions
    
    func openRideApp(option: RideOption) -> Bool {
        guard let deepLinkURL = option.deepLinkURL else { return false }
        
        if UIApplication.shared.canOpenURL(deepLinkURL) {
            UIApplication.shared.open(deepLinkURL, options: [:], completionHandler: nil)
            return true
        }
        
        return false
    }
    
    func openAppStore(option: RideOption) -> Bool {
        guard let appStoreURL = option.appStoreURL else { return false }
        
        UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        return true
    }
    
    func callEmergencyContact() {
        guard let phoneURL = URL(string: "tel://911") else { return }
        
        UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
    }
    
    func callTaxi() {
        // This would integrate with a local taxi service API
        // For now, we'll just show how this would work
        
        isLoading = true
        
        // Simulate calling a taxi
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            // In a real app, you would display confirmation of the taxi request
        }
    }
}
