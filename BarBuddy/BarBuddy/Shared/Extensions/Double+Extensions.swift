import Foundation

extension Double {
    // Round to specified number of decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    // Format to display as BAC
    var bacString: String {
        return Formatters.formatBAC(self)
    }
    
    // Format to display as percentage
    var percentString: String {
        return Formatters.formatPercent(self)
    }
    
    // Format to display as weight
    func weightString(isMetric: Bool) -> String {
        return Formatters.formatWeight(self, isMetric: isMetric)
    }
    
    // Format to display as volume
    func volumeString(isMetric: Bool) -> String {
        return Formatters.formatVolume(self, isMetric: isMetric)
    }
    
    // Convert minutes to formatted time string
    var timeString: String {
        let hours = Int(self) / 60
        let minutes = Int(self) % 60
        
        if hours > 0 {
            return "\(hours) hr \(String(format: "%02d", minutes)) min"
        } else {
            return "\(minutes) min"
        }
    }
    
    // Convert ounces to milliliters
    var ozToML: Double {
        return self * 29.5735
    }
    
    // Convert milliliters to ounces
    var mlToOZ: Double {
        return self * 0.033814
    }
    
    // Convert pounds to kilograms
    var lbsToKg: Double {
        return self * 0.453592
    }
    
    // Convert kilograms to pounds
    var kgToLbs: Double {
        return self * 2.20462
    }
}
