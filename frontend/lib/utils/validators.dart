class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    
    // Email regex pattern
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, {String fieldName = 'field'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    
    // Remove non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Check if there are at least 10 digits
    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }
  
  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    
    final age = int.tryParse(value);
    
    if (age == null) {
      return 'Please enter a valid number';
    }
    
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }
  
  // Weight validation
  static String? validateWeight(String? value, {bool isMetric = false}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your weight';
    }
    
    final weight = double.tryParse(value);
    
    if (weight == null) {
      return 'Please enter a valid number';
    }
    
    if (isMetric) {
      // Metric validation (kg)
      if (weight < 40) {
        return 'Weight seems too low (min 40 kg)';
      }
      
      if (weight > 200) {
        return 'Weight seems too high (max 200 kg)';
      }
    } else {
      // Imperial validation (lbs)
      if (weight < 88) {
        return 'Weight seems too low (min 88 lbs)';
      }
      
      if (weight > 440) {
        return 'Weight seems too high (max 440 lbs)';
      }
    }
    
    return null;
  }
  
  // Numeric validation
  static String? validateNumeric(String? value, {String fieldName = 'number'}) {
    if (value == null || value.isEmpty) {
      return 'Please enter a $fieldName';
    }
    
    if (double.tryParse(value) == null) {
      return 'Please enter a valid $fieldName';
    }
    
    return null;
  }
  
  // Positive number validation
  static String? validatePositiveNumber(String? value, {String fieldName = 'number'}) {
    final numericError = validateNumeric(value, fieldName: fieldName);
    
    if (numericError != null) {
      return numericError;
    }
    
    final number = double.parse(value!);
    
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }
}