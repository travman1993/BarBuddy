// App Info
const String kAppName = 'BarBuddy';
const String kAppVersion = '1.0.0';
const String kAppDescription = 'Your personal drinking companion';
const String kAppTagline = 'Drink Smart, Stay Safe';

// Legal
const String kPrivacyPolicyUrl = 'https://barbuddy.app/privacy';
const String kTermsOfServiceUrl = 'https://barbuddy.app/terms';
const String kSupportEmail = 'support@barbuddy.app';

// BAC Constants
const double kLegalDrivingLimit = 0.08; // Legal BAC limit in most US states
const double kCautionBACThreshold = 0.05; // Start showing caution at this BAC
const double kHighBACThreshold = 0.15; // High intoxication level

// Drink Standard Sizes & Alcohol Content (US Standards)
const Map<String, Map<String, dynamic>> kStandardDrinks = {
  'Beer': {
    'standardOz': 12.0,
    'defaultAbv': 5.0, // 5% ABV
    'icon': 'beer',
    'description': '12 oz of regular beer (5% alcohol)',
  },
  'Wine': {
    'standardOz': 5.0,
    'defaultAbv': 12.0, // 12% ABV
    'icon': 'wine',
    'description': '5 oz of wine (12% alcohol)',
  },
  'Liquor': {
    'standardOz': 1.5,
    'defaultAbv': 40.0, // 40% ABV (80 proof)
    'icon': 'liquor',
    'description': '1.5 oz of 80 proof liquor (40% alcohol)',
  },
  'Cocktail': {
    'standardOz': 1.5, // Based on typical liquor content
    'defaultAbv': 40.0, // Default to liquor strength
    'icon': 'cocktail',
    'description': 'Varies based on ingredients',
  },
};

// Time Constants
const int kMinutesInHour = 60;
const int kSecondsInMinute = 60;
const int kMillisecondsInSecond = 1000;
const int kCheckInReminderMinutes = 30; // Reminder to check in after drinking

// BAC Calculation Constants
// Widmark formula constants
const double kMaleConstant = 0.68; // Male body water constant
const double kFemaleConstant = 0.55; // Female body water constant
const double kMetabolismRate = 0.015; // Average alcohol metabolism rate per hour

// Onboarding
const List<String> kWeightOptions = [
  'Less than 100 lbs (45 kg)',
  '100-120 lbs (45-54 kg)',
  '121-140 lbs (55-64 kg)',
  '141-160 lbs (65-73 kg)',
  '161-180 lbs (74-82 kg)',
  '181-200 lbs (83-91 kg)',
  '201-220 lbs (92-100 kg)',
  '221-240 lbs (101-109 kg)',
  'More than 240 lbs (109+ kg)',
];

// App Strings
const String kDisclaimerText = '''
DISCLAIMER: BarBuddy provides BAC estimates for informational purposes only. Many factors can affect individual BAC levels, and the app should not be used as a definitive guide for determining whether you are legally fit to drive.

The only truly safe amount of alcohol to consume before driving is zero. Always err on the side of caution and arrange alternative transportation if you have been drinking.

By using this app, you acknowledge these limitations and agree that the developers accept no responsibility for any decisions made based on information provided by the app.
''';

// Notification Channel IDs
const String kSafetyAlertsChannelId = 'safety_alerts';
const String kCheckInChannelId = 'check_in_reminders';
const String kBACUpdatesChannelId = 'bac_updates';

// Error Messages
const String kGenericErrorMessage = 'Something went wrong. Please try again.';
const String kNetworkErrorMessage = 'Network error. Please check your connection.';
const String kLocationPermissionDeniedMessage = 'Location permission denied. Some features will be limited.';

// Button Texts
const String kEmergencyButtonText = 'EMERGENCY CONTACT';
const String kRideShareButtonText = 'GET A RIDE';
const String kAddDrinkButtonText = 'ADD DRINK';
const String kCheckInButtonText = 'CHECK IN';

// Navigation Labels
const String kHomeLabel = 'Home';
const String kHistoryLabel = 'History';
const String kProfileLabel = 'Profile';
const String kSettingsLabel = 'Settings';