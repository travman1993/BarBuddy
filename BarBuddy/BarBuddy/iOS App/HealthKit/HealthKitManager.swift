//
//  HealthKitManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

//
//  HealthKitManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import Foundation
import HealthKit

class HealthKitManager {
    // Shared instance for easy access
    static let shared = HealthKitManager()
    
    // The HealthKit store
    private let healthStore = HKHealthStore()
    
    // Health data types we'll be accessing
    private let alcoholConsumptionType = HKQuantityType.quantityType(forIdentifier: .alcoholConsumption)!
    private let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    
    // Check if HealthKit is available on the device
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    private init() {}
    
    // MARK: - Authorization
    
    /// Request authorization to access HealthKit data
    /// - Parameter completion: Callback with success/failure of authorization request
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Exit early if HealthKit is not available
        guard isHealthKitAvailable else {
            completion(false, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Define the data types we want to read and write
        let typesToRead: Set<HKObjectType> = [
            alcoholConsumptionType,
            bodyMassType
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            alcoholConsumptionType
        ]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            completion(success, error)
        }
    }
    
    // MARK: - Alcohol Consumption
    
    /// Save a drink to HealthKit
    /// - Parameters:
    ///   - drink: The drink to save
    ///   - completion: Callback with success/failure of the save operation
    func saveDrinkToHealthKit(drink: Drink, completion: @escaping (Bool, Error?) -> Void) {
        // Exit early if HealthKit is not available
        guard isHealthKitAvailable else {
            completion(false, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Calculate alcohol content in grams
        // 1 standard drink = 14g of pure alcohol
        let alcoholGrams = drink.standardDrinks * 14.0
        
        // Create a quantity for the alcohol consumption
        let quantity = HKQuantity(unit: HKUnit.gram(), doubleValue: alcoholGrams)
        
        // Create metadata for the sample
        let metadata: [String: Any] = [
            HKMetadataKeyAlcoholContent: drink.alcoholPercentage / 100.0,
            "drinkType": drink.type.rawValue,
            "drinkName": drink.name ?? drink.type.defaultName,
            "drinkVolume": drink.amount,
            "drinkId": drink.id
        ]
        
        // Create the sample
        let sample = HKQuantitySample(
            type: alcoholConsumptionType,
            quantity: quantity,
            start: drink.timestamp,
            end: drink.timestamp,
            metadata: metadata
        )
        
        // Save the sample
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    /// Retrieve alcohol consumption data from HealthKit
    /// - Parameters:
    ///   - startDate: Start date for the query
    ///   - endDate: End date for the query
    ///   - completion: Callback with the retrieved samples or an error
    func getAlcoholConsumption(startDate: Date, endDate: Date, completion: @escaping ([HKQuantitySample]?, Error?) -> Void) {
        // Exit early if HealthKit is not available
        guard isHealthKitAvailable else {
            completion(nil, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Create a predicate for the date range
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Configure the query
        let query = HKSampleQuery(
            sampleType: alcoholConsumptionType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            DispatchQueue.main.async {
                completion(samples as? [HKQuantitySample], error)
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    /// Delete a specific drink from HealthKit
    /// - Parameters:
    ///   - drinkId: The ID of the drink to delete
    ///   - completion: Callback with success/failure of the delete operation
    func deleteDrinkFromHealthKit(drinkId: String, completion: @escaping (Bool, Error?) -> Void) {
        // Exit early if HealthKit is not available
        guard isHealthKitAvailable else {
            completion(false, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Create a predicate to find samples with the matching drinkId
        let predicate = HKQuery.predicateForObjects(withMetadataKey: "drinkId", allowedValues: [drinkId])
        
        // Configure the query
        let query = HKSampleQuery(
            sampleType: alcoholConsumptionType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            guard let samplesToDelete = samples, !samplesToDelete.isEmpty else {
                DispatchQueue.main.async {
                    completion(false, error ?? NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No matching samples found"]))
                }
                return
            }
            
            // Delete the found samples
            self.healthStore.delete(samplesToDelete) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    // MARK: - Body Mass
    
    /// Get the latest weight record from HealthKit
    /// - Parameter completion: Callback with the weight in kilograms or an error
    func getLatestWeight(completion: @escaping (Double?, Error?) -> Void) {
        // Exit early if HealthKit is not available
        guard isHealthKitAvailable else {
            completion(nil, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Configure the query for the most recent weight sample
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async {
                    completion(nil, error ?? NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No weight data available"]))
                }
                return
            }
            
            // Get the weight in kilograms
            let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            
            DispatchQueue.main.async {
                completion(weightInKg, nil)
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    // MARK: - Sync Methods
    
    /// Sync all drinks to HealthKit
    /// - Parameters:
    ///   - drinks: Array of drinks to sync
    ///   - completion: Callback with success count, fail count, and optional error
    func syncDrinksToHealthKit(drinks: [Drink], completion: @escaping (Int, Int, Error?) -> Void) {
        // Exit early if HealthKit is not available
        guard isHealthKitAvailable else {
            completion(0, drinks.count, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        let group = DispatchGroup()
        var successCount = 0
        var failCount = 0
        
        for drink in drinks {
            group.enter()
            
            saveDrinkToHealthKit(drink: drink) { success, _ in
                if success {
                    successCount += 1
                } else {
                    failCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(successCount, failCount, nil)
        }
    }
    
    /// Update user weight from HealthKit
    /// - Parameters:
    ///   - userViewModel: The user view model to update
    ///   - completion: Callback when complete
    func updateUserWeightFromHealthKit(userViewModel: UserViewModel, completion: @escaping () -> Void) {
        getLatestWeight { weight, error in
            if let weightInKg = weight {
                // Convert kg to lbs for the app
                let weightInLbs = weightInKg * 2.20462
                
                Task {
                    try? await userViewModel.updateUserProfile(weight: weightInLbs)
                }
            }
            
            completion()
        }
    }
    
    // MARK: - Import Methods
    
    /// Import alcohol consumption data from HealthKit
    /// - Parameters:
    ///   - userId: The user ID to associate with imported drinks
    ///   - startDate: Start date for the import
    ///   - endDate: End date for the import
    ///   - drinkService: The service to use for saving drinks
    ///   - completion: Callback with success/failure of the import operation
    func importAlcoholConsumptionData(userId: String, startDate: Date, endDate: Date, drinkService: DrinkService, completion: @escaping (Bool, Error?) -> Void) {
        getAlcoholConsumption(startDate: startDate, endDate: endDate) { samples, error in
            guard let samples = samples, !samples.isEmpty else {
                completion(false, error ?? NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No samples found to import"]))
                return
            }
            
            let group = DispatchGroup()
            var successCount = 0
            var failCount = 0
            
            for sample in samples {
                // Extract metadata
                let metadata = sample.metadata ?? [:]
                
                // Get drink type from metadata or default to beer
                let drinkTypeString = metadata["drinkType"] as? String ?? DrinkType.beer.rawValue
                let drinkType = DrinkType(rawValue: drinkTypeString) ?? .beer
                
                // Get drink name
                let drinkName = metadata["drinkName"] as? String
                
                // Get alcohol percentage
                let alcoholContent = metadata[HKMetadataKeyAlcoholContent] as? Double ?? 0.05
                let alcoholPercentage = alcoholContent * 100
                
                // Get drink volume
                let amount = metadata["drinkVolume"] as? Double ?? drinkType.defaultAmount
                
                // Create the drink
                let drink = Drink(
                    userId: userId,
                    type: drinkType,
                    name: drinkName,
                    alcoholPercentage: alcoholPercentage,
                    amount: amount,
                    timestamp: sample.startDate
                )
                
                group.enter()
                
                Task {
                    do {
                        _ = try await drinkService.addDrink(drink: drink)
                        successCount += 1
                    } catch {
                        failCount += 1
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let success = failCount == 0
                completion(success, success ? nil : NSError(domain: "HealthKitManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to import \(failCount) drinks"]))
            }
        }
    }
}
