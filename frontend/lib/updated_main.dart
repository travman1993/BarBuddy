import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:barbuddy/utils/app_config.dart';
import 'package:barbuddy/services/firebase_service.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/state/providers/drink_provider.dart';
import 'package:barbuddy/state/providers/settings_provider.dart';
import 'package:barbuddy/state/providers/auth_provider.dart';
import 'package:barbuddy/services/notification_service.dart';
import 'package:barbuddy/updated_routes.dart' as routes;
import 'package:barbuddy/utils/theme.dart';

void main() async {
  // Ensure widgets are initialized
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Keep splash screen visible while initializing
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set app configuration
  AppConfig.setEnvironment(Environment.production);
  
  try {
    // Initialize Firebase services
    final firebaseService = FirebaseService();
    await firebaseService.initialize();
    
    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Remove splash screen once initialization is complete
    FlutterNativeSplash.remove();
    
    // Run the app
    runApp(const BarBuddyApp());
  } catch (e) {
    // Handle initialization errors
    debugPrint('Error initializing app: $e');
    
    // Remove splash screen and show error UI
    FlutterNativeSplash.remove();
    
    runApp(const AppInitializationError());
  }
}

class BarBuddyApp extends StatelessWidget {
  const BarBuddyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider needs to be first since others depend on it
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Other providers
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DrinkProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: 'BarBuddy',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: routes.AppRoutes.splash,
            onGenerateRoute: routes.AppRouter.generateRoute,
            navigatorKey: DrinkProvider.navigatorKey,
          );
        },
      ),
    );
  }
}

class AppInitializationError extends StatelessWidget {
  const AppInitializationError({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppErrorScreen(),
    );
  }
}

class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Initialization Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'There was a problem initializing the app. Please check your internet connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Attempt to restart the app
                  SystemNavigator.pop();
                },
                child: const Text('RESTART APP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}