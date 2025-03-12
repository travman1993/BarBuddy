//
//  BACComplication.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import ClockKit

extension ComplicationController {
    // MARK: - Modular Templates
    
    func createModularSmallTemplate(bacString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularSmallSimpleText()
        template.textProvider = CLKSimpleTextProvider(text: bacString)
        template.tintColor = color
        return template
    }
    
    func createModularLargeTemplate(bacString: String, timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularLargeTallBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "BAC")
        template.bodyTextProvider = CLKSimpleTextProvider(text: bacString)
        
        if !timeString.isEmpty {
            template.headerTextProvider.tintColor = color
        }
        
        return template
    }
    
    // MARK: - Utilitarian Templates
    
    func createUtilitarianSmallTemplate(bacString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: bacString)
        template.tintColor = color
        return template
    }
    
    func createUtilitarianLargeTemplate(bacString: String, timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        template.textProvider = CLKSimpleTextProvider(text: "BAC \(bacString)")
        template.tintColor = color
        return template
    }
    
    // MARK: - Circular Templates
    
    func createCircularSmallTemplate(bacString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateCircularSmallSimpleText()
        template.textProvider = CLKSimpleTextProvider(text: bacString)
        template.tintColor = color
        return template
    }
    
    // MARK: - Extra Large Templates
    
    func createExtraLargeTemplate(bacString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateExtraLargeSimpleText()
        template.textProvider = CLKSimpleTextProvider(text: bacString)
        template.tintColor = color
        return template
    }
    
    // MARK: - Graphic Templates
    
    func createGraphicCornerTemplate(bacString: String, timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerTextImage()
        template.textProvider = CLKSimpleTextProvider(text: "BAC \(bacString)")
        
        // Create an image for graphic templates
        if let image = UIImage(systemName: "gauge") {
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        }
        
        return template
    }
    
    func createGraphicCircularTemplate(bacString: String, timeString: String, color: UIColor) -> CLKComplicationTemplate {
        if #available(watchOSApplicationExtension 6.0, *) {
            let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
            template.centerTextProvider = CLKSimpleTextProvider(text: bacString)
            
            // Set up gauge to show percentage of BAC
            let value = Float(min(0.25, Double(bacString) ?? 0)) / 0.25
            template.gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: color,
                fillFraction: value
            )
            
            return template
        } else {
            let template = CLKComplicationTemplateGraphicCircularView()
            return template
        }
    }
    
    func createGraphicRectangularTemplate(bacString: String, timeString: String, color: UIColor) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicRectangularStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "BAC Level")
        template.body1TextProvider = CLKSimpleTextProvider(text: bacString)
        
        if !timeString.isEmpty {
            template.body2TextProvider = CLKSimpleTextProvider(text: timeString)
        }
        
        return template
    }
    
    func createGraphicBezelTemplate(bacString: String, timeString: String, color: UIColor) -> CLKComplicationTemplate {
        if #available(watchOSApplicationExtension 6.0, *) {
            let circularTemplate = createGraphicCircularTemplate(bacString: bacString, timeString: timeString, color: color)
            
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            template.circularTemplate = circularTemplate as? CLKComplicationTemplateGraphicCircular
            template.textProvider = CLKSimpleTextProvider(text: "Sober in \(timeString)")
            
            return template
        } else {
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            return template
        }
    }
    
    func createGraphicExtraLargeTemplate(bacString: String, color: UIColor) -> CLKComplicationTemplate {
        if #available(watchOSApplicationExtension 7.0, *) {
            let template = CLKComplicationTemplateGraphicExtraLargeCircularView()
            return template
        } else {
            let template = CLKComplicationTemplateExtraLargeSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: bacString)
            template.tintColor = color
            return template
        }
    }
}
