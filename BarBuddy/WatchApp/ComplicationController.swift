//
//  ComplicationController.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "com.barbuddy.bac",
                displayName: "BAC Status",
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
    // MARK: - Helper Methods
    
    private func bacColor(bac: Double) -> UIColor {
        if bac < 0.04 {
            return UIColor.green
        } else if bac < 0.08 {
            return UIColor.yellow
        } else {
            return UIColor.red
        }
    }
    
    private func bacSafetyText(bac: Double) -> String {
        if bac < 0.04 {
            return "Safe to drive"
        } else if bac < 0.08 {
            return "Borderline - use caution"
        } else {
            return "DO NOT DRIVE"
        }
    }
    
    private func bacSafetyImageName(bac: Double) -> String {
        if bac < 0.04 {
            return "checkmark.circle"
        } else if bac < 0.08 {
            return "exclamationmark.triangle"
        } else {
            return "xmark.octagon"
        }
    }
}
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Since BAC changes over time, we need to update periodically
        // Return the date when we'll stop providing data
        let endDate = Date().addingTimeInterval(24 * 60 * 60) // 24 hours from now
        handler(endDate)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Privacy is important for BAC data
        handler(.hideOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get current BAC from app shared data
        let bac = UserDefaults.standard.double(forKey: "currentBAC")
        let timeUntilSober = UserDefaults.standard.double(forKey: "timeUntilSober")
        
        // Create the template based on the complication family
        var template: CLKComplicationTemplate?
        
        switch complication.family {
        case .modularSmall:
            template = createModularSmallTemplate(bac: bac)
        case .modularLarge:
            template = createModularLargeTemplate(bac: bac, timeUntilSober: timeUntilSober)
        case .utilitarianSmall, .utilitarianSmallFlat:
            template = createUtilitarianSmallTemplate(bac: bac)
        case .utilitarianLarge:
            template = createUtilitarianLargeTemplate(bac: bac, timeUntilSober: timeUntilSober)
        case .circularSmall:
            template = createCircularSmallTemplate(bac: bac)
        case .extraLarge:
            template = createExtraLargeTemplate(bac: bac)
        case .graphicCorner:
            template = createGraphicCornerTemplate(bac: bac)
        case .graphicCircular:
            template = createGraphicCircularTemplate(bac: bac)
        case .graphicRectangular:
            template = createGraphicRectangularTemplate(bac: bac, timeUntilSober: timeUntilSober)
        case .graphicBezel:
            template = createGraphicBezelTemplate(bac: bac, timeUntilSober: timeUntilSober)
        case .graphicExtraLarge:
            template = createGraphicExtraLargeTemplate(bac: bac)
        @unknown default:
            template = nil
        }
        
        if let template = template {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    // MARK: - Template Providers
    
    // Modular Small
    private func createModularSmallTemplate(bac: Double) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "BAC")
        template.line2TextProvider = CLKSimpleTextProvider(
            text: String(format: "%.3f", bac),
            shortText: String(format: "%.2f", bac)
        )
        return template
    }
    
    // Modular Large
    private func createModularLargeTemplate(bac: Double, timeUntilSober: TimeInterval) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularLargeStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "BarBuddy")
        
        template.body1TextProvider = CLKSimpleTextProvider(
            text: "BAC: \(String(format: "%.3f", bac))",
            shortText: "\(String(format: "%.3f", bac))"
        )
        
        if timeUntilSober > 0 {
            let hours = Int(timeUntilSober) / 3600
            let minutes = (Int(timeUntilSober) % 3600) / 60
            var timeText = ""
            
            if hours > 0 {
                timeText = "\(hours)h \(minutes)m until safe"
            } else {
                timeText = "\(minutes)m until safe"
            }
            
            template.body2TextProvider = CLKSimpleTextProvider(text: timeText)
        } else {
            template.body2TextProvider = CLKSimpleTextProvider(text: "Safe to drive")
        }
        
        return template
    }
    
    // Utilitarian Small
    private func createUtilitarianSmallTemplate(bac: Double) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: String(format: "BAC: %.2f", bac))
        return template
    }
    
    // Utilitarian Large
    private func createUtilitarianLargeTemplate(bac: Double, timeUntilSober: TimeInterval) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        
        var text = "BAC: \(String(format: "%.3f", bac))"
        
        if timeUntilSober > 0 {
            let hours = Int(timeUntilSober) / 3600
            let minutes = (Int(timeUntilSober) % 3600) / 60
            
            if hours > 0 {
                text += " (\(hours)h \(minutes)m)"
            } else {
                text += " (\(minutes)m)"
            }
        }
        
        template.textProvider = CLKSimpleTextProvider(text: text)
        return template
    }
    
    // Circular Small
    private func createCircularSmallTemplate(bac: Double) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateCircularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "BAC")
        template.line2TextProvider = CLKSimpleTextProvider(text: String(format: "%.2f", bac))
        return template
    }
    
    // Extra Large
    private func createExtraLargeTemplate(bac: Double) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateExtraLargeStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "BAC")
        template.line2TextProvider = CLKSimpleTextProvider(text: String(format: "%.3f", bac))
        return template
    }
    
    // Graphic Corner
    private func createGraphicCornerTemplate(bac: Double) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerTextImage()
        template.textProvider = CLKSimpleTextProvider(text: String(format: "BAC: %.3f", bac))
        
        // Create a different image based on BAC level
        let imageName = bacSafetyImageName(bac: bac)
        template.imageProvider = CLKImageProvider(onePieceImage: UIImage(systemName: imageName)!)
        
        return template
    }
    
    // Graphic Circular
    private func createGraphicCircularTemplate(bac: Double) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
        
        // Create gauge for BAC level
        template.gaugeProvider = CLKSimpleGaugeProvider(
            style: .fill,
            gaugeColor: bacColor(bac: bac),
            fillFraction: min(Float(bac) / 0.2, 1.0) // Scale to max at 0.2
        )
        
        template.centerTextProvider = CLKSimpleTextProvider(
            text: String(format: "%.2f", bac)
        )
        
        return template
    }
    
    // Graphic Rectangular
    private func createGraphicRectangularTemplate(bac: Double, timeUntilSober: TimeInterval) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicRectangularStandardBody()
        
        template.headerTextProvider = CLKSimpleTextProvider(text: "BarBuddy BAC Status")
        
        // Main BAC display
        template.body1TextProvider = CLKSimpleTextProvider(
            text: String(format: "BAC: %.3f", bac),
            shortText: String(format: "%.3f", bac)
        )
        
        // Status and time until sober
        if timeUntilSober > 0 {
            let hours = Int(timeUntilSober) / 3600
            let minutes = (Int(timeUntilSober) % 3600) / 60
            var timeText = ""
            
            if hours > 0 {
                timeText = "Safe to drive in \(hours)h \(minutes)m"
            } else {
                timeText = "Safe to drive in \(minutes)m"
            }
            
            template.body2TextProvider = CLKSimpleTextProvider(text: timeText)
        } else if bac > 0 {
            template.body2TextProvider = CLKSimpleTextProvider(text: bacSafetyText(bac: bac))
        } else {
            template.body2TextProvider = CLKSimpleTextProvider(text: "No alcohol detected")
        }
        
        return template
    }
    
    // Graphic Bezel
    private func createGraphicBezelTemplate(bac: Double, timeUntilSober: TimeInterval) -> CLKComplicationTemplate {
        let circularTemplate = createGraphicCircularTemplate(bac: bac)
        
        let bezelTemplate = CLKComplicationTemplateGraphicBezelCircularText()
        bezelTemplate.circularTemplate = circularTemplate
        
        if timeUntilSober > 0 {
            let hours = Int(timeUntilSober) / 3600
            let minutes = (Int(timeUntilSober) % 3600) / 60
            var timeText = ""
            
            if hours > 0 {
                timeText = "\(hours)h \(minutes)m until safe"
            } else {
                timeText = "\(minutes)m until safe"
            }
            
            bezelTemplate.textProvider = CLKSimpleTextProvider(text: timeText)
        } else if bac > 0 {
            bezelTemplate.textProvider = CLKSimpleTextProvider(text: bacSafetyText(bac: bac))
        }
        
        return bezelTemplate
    }
    
    // Graphic Extra Large
    private func createGraphicExtraLargeTemplate(bac: Double) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicExtraLargeCircularStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "BAC")
        template.line2TextProvider = CLKSimpleTextProvider(text: String(format: "%.3f", bac))
        return template
    }
