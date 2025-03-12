//
//  TimeRemainingComplication.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import ClockKit

extension ComplicationController {
    // Helper method to format time remaining for complications
    func formatTimeForComplication(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    // Create a complication that shows time until sober
    func createTimeRemainingTemplate(for complication: CLKComplication, with bacEstimate: BACEstimate) -> CLKComplicationTemplate? {
        // If BAC is already 0, return nil
        if bacEstimate.bac <= 0 {
            return nil
        }
        
        let minutesRemaining = bacEstimate.minutesUntilSober
        let timeString = formatTimeForComplication(minutesRemaining)
        let color = getColorForBAC(bacEstimate.bac)
        
        switch complication.family {
        case .modularSmall:
            return createModularSmallTimeTemplate(timeString: timeString, color: color)
        case .modularLarge:
            return createModularLargeTimeTemplate(timeString: timeString, color: color)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallTimeTemplate(timeString: timeString, color: color)
        case .utilitarianLarge:
            return createUtilitarianLargeTimeTemplate(timeString: timeString, color: color)
        case .circularSmall:
            return createCircularSmallTimeTemplate(timeString: timeString, color: color)
        case .extraLarge:
            return createExtraLargeTimeTemplate(timeString: timeString, color: color)
        default:
            return nil
        }
    }
    
    // MARK: - Time Remaining Templates
    
    func createModularSmallTimeTemplate(timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "Sober")
        template.line2TextProvider = CLKSimpleTextProvider(text: timeString)
        template.tintColor = color
        return template
    }
    
    func createModularLargeTimeTemplate(timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularLargeTallBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "Sober in")
        template.bodyTextProvider = CLKSimpleTextProvider(text: timeString)
        template.headerTextProvider.tintColor = color
        return template
    }
    
    func createUtilitarianSmallTimeTemplate(timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: timeString)
        template.tintColor = color
        return template
    }
    
    func createUtilitarianLargeTimeTemplate(timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        template.textProvider = CLKSimpleTextProvider(text: "Sober in \(timeString)")
        template.tintColor = color
        return template
    }
    
    func createCircularSmallTimeTemplate(timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateCircularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "Sober")
        template.line2TextProvider = CLKSimpleTextProvider(text: timeString)
        template.tintColor = color
        return template
    }
    
    func createExtraLargeTimeTemplate(timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateExtraLargeStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "Sober")
        template.line2TextProvider = CLKSimpleTextProvider(text: timeString)
        template.tintColor = color
        return template
    }
}
