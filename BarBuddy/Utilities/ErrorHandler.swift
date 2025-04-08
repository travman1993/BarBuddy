//
//  ErrorHandler.swift
//  BarBuddy
//

import Foundation
import os

/**
 * Centralized error handling for the app.
 *
 * This class provides consistent error handling, logging, and user feedback
 * for errors that occur throughout the app.
 */
enum AppError: Error {
    /// Errors related to data processing or persistence
    case dataError(String)
    
    /// Errors related to network operations
    case networkError(String)
    
    /// Errors related to insufficient permissions
    case permissionError(String)
    
    /// Errors related to Apple Watch connectivity
    case watchConnectivityError(String)
    
    /// General errors that don't fit other categories
    case generalError(String)
    
    var localizedDescription: String {
        switch self {
        case .dataError(let message):
            return "Data Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .permissionError(let message):
            return "Permission Error: \(message)"
        case .watchConnectivityError(let message):
            return "Watch Error: \(message)"
        case .generalError(let message):
            return "Error: \(message)"
        }
    }
}

/**
 * Handles error logging and presentation throughout the app.
 */
class ErrorHandler {
    /// Shared singleton instance
    static let shared = ErrorHandler()
    
    /// Logger for recording errors to the system log
    private let logger = Logger(subsystem: "com.yourapp.BarBuddy", category: "ErrorHandler")
    
    /// The current error being presented to the user
    @Published var currentError: AppError?
    
    private init() {}
    
    /**
     * Handles an error by logging it and storing it for presentation.
     *
     * - Parameters:
     *   - error: The error to handle
     *   - file: Source file where the error occurred (auto-populated)
     *   - line: Line number where the error occurred (auto-populated)
     */
    func handle(_ error: Error, file: String = #file, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.error("Error at \(fileName):\(line) - \(error.localizedDescription)")
        
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = .generalError(error.localizedDescription)
        }
    }
    
    /**
     * Clears the current error.
     *
     * Call this after the error has been presented to the user.
     */
    func clearError() {
        currentError = nil
    }
}
