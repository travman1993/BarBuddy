//
//  ComplicationController.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

// ComplicationController.swift
// ComplicationController.swift
import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        // Time travel is not supported in this app
        handler([])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Timeline starts now
        handler(Date())
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // We only support the current time
        handler(Date())
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Show BAC data on the lock screen
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get the current BAC data
        let storageService = StorageService()
        
        Task {
            do {
                guard let userId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId),
                      let bacEstimate = try await storageService.getBAC(userId: userId) else {
                    // No BAC data available
                    handler(nil)
                    return
                }
                
                // Create a timeline entry
                let template = createTemplate(for: complication, with: bacEstimate)
                if let template = template {
                    let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                    handler(entry)
                } else {
                    handler(nil)
                }
            } catch {
                handler(nil)
            }
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // We only support the current time
        handler(nil)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // Create a sample template
        let sampleBAC = BACEstimate(
            bac: 0.045,
            timestamp: Date(),
            soberTime: Date().addingTimeInterval(3 * 60 * 60),
            legalTime: Date(),
            drinkIds: []
        )
        
        let template = createTemplate(for: complication, with: sampleBAC)
        handler(template)
    }
    
    // MARK: - Complication Descriptors
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "com.barbuddy.bac",
                displayName: "BAC Level",
                supportedFamilies: [
                    .modularSmall,
                    .modularLarge,
                    .utilitarianSmall,
                    .utilitarianSmallFlat,
                    .utilitarianLarge,
                    .circularSmall,
                    .extraLarge,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular,
                    .graphicBezel,
                    .graphicExtraLarge
                ]
            )
        ]
        
        handler(descriptors)
    }
    
    // MARK: - Template Creation
    
    private func createTemplate(for complication: CLKComplication, with bacEstimate: BACEstimate) -> CLKComplicationTemplate? {
        let bacString = bacEstimate.bac.bacString
        let timeString = bacEstimate.timeUntilSoberFormatted
        
        let color = getColorForBAC(bacEstimate.bac)
        
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(bacString: bacString, color: color)
        case .modularLarge:
            return createModularLargeTemplate(bacString: bacString, timeString: timeString, color: color)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallTemplate(bacString: bacString, color: color)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(bacString: bacString, timeString: timeString, color: color)
        case .circularSmall:
            return createCircularSmallTemplate(bacString: bacString, color: color)
        case .extraLarge:
            return createExtraLargeTemplate(bacString: bacString, color: color)
        case .graphicCorner:
            return createGraphicCornerTemplate(bacString: bacString, timeString: timeString, color: color)
        case .graphicCircular:
            return createGraphicCircularTemplate(bacString: bacString, timeString: timeString, color: color)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(bacString: bacString, timeString: timeString, color: color)
        case .graphicBezel:
            return createGraphicBezelTemplate(bacString: bacString, timeString: timeString, color: color)
        case .graphicExtraLarge:
            return createGraphicExtraLargeTemplate(bacString: bacString, color: color)
        @unknown default:
            return nil
        }
    }
    
    private func getColorForBAC(_ bac: Double) -> UIColor {
        if bac >= Constants.BAC.legalLimit {
            return UIColor.red
        } else if bac >= Constants.BAC.cautionThreshold {
            return UIColor.orange
        } else {
            return UIColor.green
        }
    }
}
