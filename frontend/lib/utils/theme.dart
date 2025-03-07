import 'package:flutter/material.dart';

// Colors
const Color kPrimaryColor = Color(0xFF7B61FF);
const Color kSecondaryColor = Color(0xFF6C63FF);
const Color kAccentColor = Color(0xFF00B0FF);
const Color kBackgroundColor = Color(0xFFF8F9FA);
const Color kDarkBackgroundColor = Color(0xFF121212);
const Color kCardColor = Colors.white;
const Color kDarkCardColor = Color(0xFF1E1E1E);
const Color kTextColor = Color(0xFF212121);
const Color kDarkTextColor = Color(0xFFE0E0E0);
const Color kSubtitleColor = Color(0xFF757575);
const Color kDarkSubtitleColor = Color(0xFFBDBDBD);
const Color kErrorColor = Color(0xFFE57373);
const Color kWarningColor = Color(0xFFFFB74D);
const Color kSuccessColor = Color(0xFF81C784);

// BAC Level Colors
const Color kSafeBAC = Color(0xFF43A047);    // Green for safe BAC
const Color kCautionBAC = Color(0xFFFFA000); // Yellow/amber for caution
const Color kDangerBAC = Color(0xFFE53935);  // Red for danger/high BAC

// Text Styles
const TextStyle kHeadingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  letterSpacing: 0.5,
);

const TextStyle kSubheadingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.25,
);

const TextStyle kBodyStyle = TextStyle(
  fontSize: 16,
  letterSpacing: 0.15,
);

const TextStyle kSmallStyle = TextStyle(
  fontSize: 14,
  letterSpacing: 0.1,
);

// Light Theme
final ThemeData lightTheme = ThemeData(
  primaryColor: kPrimaryColor,
  colorScheme: ColorScheme.light(
    primary: kPrimaryColor,
    secondary: kSecondaryColor,
    background: kBackgroundColor,
    error: kErrorColor,
  ),
  scaffoldBackgroundColor: kBackgroundColor,
  cardColor: kCardColor,
  textTheme: TextTheme(
    headlineMedium: kHeadingStyle.copyWith(color: kTextColor),
    titleMedium: kSubheadingStyle.copyWith(color: kTextColor),
    bodyMedium: kBodyStyle.copyWith(color: kTextColor),
    bodySmall: kSmallStyle.copyWith(color: kSubtitleColor),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 1,
  ),
  useMaterial3: true,
);

// Dark Theme
final ThemeData darkTheme = ThemeData(
  primaryColor: kPrimaryColor,
  colorScheme: ColorScheme.dark(
    primary: kPrimaryColor,
    secondary: kSecondaryColor,
    background: kDarkBackgroundColor,
    error: kErrorColor,
  ),
  scaffoldBackgroundColor: kDarkBackgroundColor,
  cardColor: kDarkCardColor,
  textTheme: TextTheme(
    headlineMedium: kHeadingStyle.copyWith(color: kDarkTextColor),
    titleMedium: kSubheadingStyle.copyWith(color: kDarkTextColor),
    bodyMedium: kBodyStyle.copyWith(color: kDarkTextColor),
    bodySmall: kSmallStyle.copyWith(color: kDarkSubtitleColor),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2C2C2C),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF424242),
    thickness: 1,
  ),
  useMaterial3: true,
);