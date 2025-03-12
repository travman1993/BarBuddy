# BarBuddy Architecture

This document outlines the architectural approach used in the BarBuddy app.

## Overview

BarBuddy follows a Model-View-ViewModel (MVVM) architecture pattern, with a focus on separation of concerns and code reuse between iOS and watchOS apps.

## Layers

### 1. Models

Core data structures that represent entities in the app:

- `User` - Represents the user's profile and physical characteristics
- `Drink` - Represents an alcoholic drink consumed by the user
- `BACEstimate` - Represents a Blood Alcohol Content calculation
- `EmergencyContact` - Represents an emergency contact

### 2. Services

Business logic layer responsible for data operations:

- `BACCalculator` - Calculates BAC based on user data and drinks
- `DrinkService` - Manages drink data (CRUD operations)
- `UserService` - Manages user data
- `EmergencyService` - Handles emergency contact functionality
- `SettingsService` - Manages app settings
- `NotificationService` - Handles local notifications
- `LocationService` - Manages location operations
- `StorageService` - Handles persistent storage

### 3. ViewModels

Connects the data models with the views:

- `UserViewModel` - Manages user data for the UI
- `DrinkViewModel` - Manages drink data for the UI
- `BACViewModel` - Manages BAC calculations for the UI
- `EmergencyViewModel` - Manages emergency contact features for the UI
- `SettingsViewModel` - Manages settings for the UI

### 4. Views

The UI layer, implemented using SwiftUI:

- iOS-specific views for the main app
- watchOS-specific views for the Apple Watch app
- Shared components used by both platforms

## Data Flow

1. User interacts with a View
2. View notifies ViewModel of the action
3. ViewModel calls appropriate Service(s)
4. Service performs business logic and updates Models
5. ViewModel receives updated data and notifies View
6. View updates to reflect the new state

## Code Sharing

- Shared models, services, and utilities are used by both iOS and watchOS apps
- Platform-specific code is isolated in respective targets
- Common UI components are designed to work on both platforms when possible

## Dependencies

BarBuddy minimizes external dependencies for better maintainability:

- Uses built-in frameworks like SwiftUI, CoreLocation, and UserNotifications
- Implements custom utilities rather than relying on third-party libraries where practical
