import Foundation

extension String {
    // Capitalize first letter of each word
    var titleCased: String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
    // Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    // Check if string is a valid phone number (simple check)
    var isValidPhoneNumber: Bool {
        let phoneRegEx = "^[0-9+]{10,15}$"
        let phonePred = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: self.filter { $0.isNumber })
    }
    
    // Remove non-numeric characters from string (useful for phone numbers)
    var digitsOnly: String {
        return self.filter { $0.isNumber }
    }
    
    // Truncate string to max length with ellipsis
    func truncated(toLength length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
}
