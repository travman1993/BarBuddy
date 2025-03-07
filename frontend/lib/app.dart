import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/routes.dart';
import 'package:barbuddy/utils/theme.dart';
import 'package:barbuddy/state/providers/settings_provider.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/screens/onboarding_screen.dart';
import 'package:barbuddy/screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:barbuddy/localization/app_localizations.dart';

class BarBuddyApp extends StatelessWidget {
  const BarBuddyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    
    return MaterialApp(
      title: 'BarBuddy',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
        Locale('fr', ''), // French
      ],
      home: userProvider.isFirstTime 
        ? const OnboardingScreen() 
        : const HomeScreen(),
    );
  }
}