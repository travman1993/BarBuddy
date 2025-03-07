import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  final Environment environment;
  final String apiUrl;
  final bool analytics;
  final bool crashReporting;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final String supportEmail;
  
  static AppConfig? _instance;
  
  factory AppConfig({
    required Environment environment,
    required String apiUrl,
    required bool analytics,
    required bool crashReporting,
    required String privacyPolicyUrl,
    required String termsOfServiceUrl,
    required String supportEmail,
  }) {
    _instance ??= AppConfig._internal(
      environment: environment,
      apiUrl: apiUrl,
      analytics: analytics,
      crashReporting: crashReporting,
      privacyPolicyUrl: privacyPolicyUrl,
      termsOfServiceUrl: termsOfServiceUrl,
      supportEmail: supportEmail,
    );
    
    return _instance!;
  }
  
  AppConfig._internal({
    required this.environment,
    required this.apiUrl,
    required this.analytics,
    required this.crashReporting,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
    required this.supportEmail,
  });
  
  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig must be initialized before accessing instance');
    }
    return _instance!;
  }
  
  static bool get isProduction => instance.environment == Environment.production;
  static bool get isStaging => instance.environment == Environment.staging;
  static bool get isDevelopment => instance.environment == Environment.development;
  
  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.development:
        _instance = AppConfig(
          environment: Environment.development,
          apiUrl: 'https://dev-api.barbuddy.app',
          analytics: false,
          crashReporting: false,
          privacyPolicyUrl: 'https://dev.barbuddy.app/privacy',
          termsOfServiceUrl: 'https://dev.barbuddy.app/terms',
          supportEmail: 'dev-support@barbuddy.app',
        );
        break;
      case Environment.staging:
        _instance = AppConfig(
          environment: Environment.staging,
          apiUrl: 'https://staging-api.barbuddy.app',
          analytics: true,
          crashReporting: true,
          privacyPolicyUrl: 'https://staging.barbuddy.app/privacy',
          termsOfServiceUrl: 'https://staging.barbuddy.app/terms',
          supportEmail: 'staging-support@barbuddy.app',
        );
        break;
      case Environment.production:
        _instance = AppConfig(
          environment: Environment.production,
          apiUrl: 'https://api.barbuddy.app',
          analytics: true,
          crashReporting: true,
          privacyPolicyUrl: 'https://barbuddy.app/privacy',
          termsOfServiceUrl: 'https://barbuddy.app/terms',
          supportEmail: 'support@barbuddy.app',
        );
        break;
    }
  }
  
  @override
  String toString() {
    return 'AppConfig{environment: $environment, apiUrl: $apiUrl, analytics: $analytics, crashReporting: $crashReporting}';
  }
}