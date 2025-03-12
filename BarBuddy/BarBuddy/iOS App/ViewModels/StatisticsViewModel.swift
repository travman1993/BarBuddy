//
//  StatisticsViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

//
//  StatisticsViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import Foundation
import Combine
import SwiftUI

class StatisticsViewModel: ObservableObject {
    private let drinkService = DrinkService()
    
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var stats: DrinkingStats?
    @Published var timeframe: Timeframe = .week
    
    enum Timeframe: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    struct DrinkingStats {
        var totalDrinks: Int
        var totalStandardDrinks: Double
        var averageDrinksPerDay: Double
        var mostCommonDrink: DrinkType
        var highestBACRecorded: Double
        var sobriestDays: Int
        var drinksByDay: [Date: Int]
        var drinksByType: [DrinkType: Int]
        
        init(fromRawStats: [String: Any]) {
            // Parse the stats from the dictionary returned by DrinkService
            self.totalDrinks = 0
            self.totalStandardDrinks = 0
            self.averageDrinksPerDay = 0
            self.mostCommonDrink = .beer
            self.highestBACRecorded = 0
            self.sobriestDays = 0
            self.drinksByDay = [:]
            self.drinksByType = [:]
            
            // Parse stats based on timeframe
            if let pastMonth = fromRawStats["pastMonth"] as? [String: Any] {
                self.totalDrinks = pastMonth["count"] as? Int ?? 0
                self.totalStandardDrinks = pastMonth["standardDrinks"] as? Double ?? 0
                self.averageDrinksPerDay = pastMonth["dailyAverage"] as? Double ?? 0
                
                if let typeString = pastMonth["mostCommonType"] as? String,
                   let type = DrinkType(rawValue: typeString) {
                    self.mostCommonDrink = type
                }
            }
            
            // Additional stats would be parsed here if available
        }
    }
    
    // MARK: - Methods
    
    func loadStats(userId: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                let statsData = try await drinkService.getUserDrinkingStats(userId: userId)
                
                await MainActor.run {
                    self.stats = DrinkingStats(fromRawStats: statsData)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load stats: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadDetailedStats(userId: String, timeframe: Timeframe) {
        isLoading = true
        error = nil
        self.timeframe = timeframe
        
        Task {
            do {
                let end = Date()
                let start = Calendar.current.date(byAdding: .day, value: -timeframe.days, to: end)!
                
                let drinks = try await drinkService.getDrinksInRange(userId: userId, start: start, end: end)
                
                // Process the drinks to get detailed stats
                let processedStats = processDetailedStats(drinks: drinks, timeframe: timeframe)
                
                await MainActor.run {
                    self.stats = processedStats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load detailed stats: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func processDetailedStats(drinks: [Drink], timeframe: Timeframe) -> DrinkingStats {
        // Group drinks by day
        let calendar = Calendar.current
        var drinksByDay: [Date: [Drink]] = [:]
        var drinksByType: [DrinkType: Int] = [:]
        
        for drink in drinks {
            let startOfDay = calendar.startOfDay(for: drink.timestamp)
            
            // Add to drinks by day
            if drinksByDay[startOfDay] != nil {
                drinksByDay[startOfDay]?.append(drink)
            } else {
                drinksByDay[startOfDay] = [drink]
            }
            
            // Add to drinks by type
            drinksByType[drink.type, default: 0] += 1
        }
        
        // Calculate stats
        let totalDrinks = drinks.count
        let totalStandardDrinks = drinks.reduce(0) { $0 + $1.standardDrinks }
        let averageDrinksPerDay = Double(totalDrinks) / Double(timeframe.days)
        
        // Find most common drink type
        let mostCommonDrink = drinksByType.max(by: { $0.value < $1.value })?.key ?? .beer
        
        // Count sober days
        let sobriestDays = timeframe.days - drinksByDay.count
        
        // Create simplified drinks by day for the chart
        let simplifiedDrinksByDay = drinksByDay.reduce(into: [Date: Int]()) { result, entry in
            result[entry.key] = entry.value.count
        }
        
        return DrinkingStats(
            totalDrinks: totalDrinks,
            totalStandardDrinks: totalStandardDrinks,
            averageDrinksPerDay: averageDrinksPerDay,
            mostCommonDrink: mostCommonDrink,
            highestBACRecorded: 0, // Would require BAC history
            sobriestDays: sobriestDays,
            drinksByDay: simplifiedDrinksByDay,
            drinksByType: drinksByType
        )
    }
    
    // Helper to get chart data in the right format
    func getChartData() -> [(date: Date, count: Int)] {
        guard let stats = stats else { return [] }
        
        let sortedDates = stats.drinksByDay.keys.sorted()
        return sortedDates.map { date in
            (date: date, count: stats.drinksByDay[date] ?? 0)
        }
    }
    
    // Helper to get drink type distribution data
    func getDrinkTypeData() -> [(type: DrinkType, count: Int, color: Color)] {
        guard let stats = stats else { return [] }
        
        let colors: [DrinkType: Color] = [
            .beer: .yellow,
            .wine: .purple,
            .liquor: .blue,
            .cocktail: .pink,
            .custom: .green
        ]
        
        return stats.drinksByType.map { type, count in
            (type: type, count: count, color: colors[type] ?? .gray)
        }.sorted { $0.count > $1.count }
    }
}
