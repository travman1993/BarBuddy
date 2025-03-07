import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/screens/home_screen.dart';
import 'package:barbuddy/screens/drink_logging_screen.dart';
import 'package:barbuddy/screens/bac_estimate_screen.dart';
import 'package:barbuddy/screens/safety_alerts_screen.dart';
import 'package:barbuddy/screens/emergency_contact_screen.dart';
import 'package:barbuddy/screens/settings_screen.dart';
import 'package:barbuddy/screens/history_screen.dart';
import 'package:barbuddy/screens/disclaimer_screen.dart';
import 'package:barbuddy/screens/onboarding_screen.dart';
import 'package:barbuddy/screens/login_screen.dart';
import 'package:barbuddy/screens/register_screen.dart';
import 'package:barbuddy/screens/forgot_password_screen.dart';
import 'package:barbuddy/screens/splash_screen.dart';
import 'package:barbuddy/state/providers/auth_provider.dart';

class AppRoutes {
  // Auth routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // App routes
  static const String home = '/';
  static const String drinkLogging = '/drink-logging';
  static const String bacEstimate = '/bac-estimate';
  static const String safetyAlerts = '/safety-alerts';
  static const String emergencyContact = '/emergency-contact';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String disclaimer = '/disclaimer';
  static const String onboarding = '/onboarding';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth routes
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      
      // App routes
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.drinkLogging:
        return MaterialPageRoute(builder: (_) => const DrinkLoggingScreen());
      case AppRoutes.bacEstimate:
        return MaterialPageRoute(builder: (_) => const BacEstimateScreen());
      case AppRoutes.safetyAlerts:
        return MaterialPageRoute(builder: (_) => const SafetyAlertsScreen());
      case AppRoutes.emergencyContact:
        return MaterialPageRoute(builder: (_) => const EmergencyContactScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case AppRoutes.disclaimer:
        return MaterialPageRoute(builder: (_) => const DisclaimerScreen());
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

// Widgets to handle authentication state for routes
class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget? loginScreen;
  final Widget? onboardingScreen;
  
  const AuthGuard({
    Key? key,
    required this.child,
    this.loginScreen,
    this.onboardingScreen,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Check authentication status
        if (authProvider.authStatus == AuthStatus.unauthenticated) {
          return loginScreen ?? const LoginScreen();
        }
        
        // Check if user needs onboarding
        if (authProvider.authStatus == AuthStatus.onboarding) {
          return onboardingScreen ?? const DisclaimerScreen();
        }
        
        // Authenticated user
        return child;
      },
    );
  }
}

// Initial route widget that decides where to send the user
class AuthRouter extends StatelessWidget {
  const AuthRouter({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        switch (authProvider.authStatus) {
          case AuthStatus.authenticated:
            return const HomeScreen();
          case AuthStatus.onboarding:
            return const DisclaimerScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.unknown:
          default:
            return const SplashScreen();
        }
      },
    );
  }
}