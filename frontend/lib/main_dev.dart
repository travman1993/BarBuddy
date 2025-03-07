import 'package:flutter/material.dart';
import 'package:barbuddy/utils/app_config.dart';
import 'main.dart' as app;

void main() {
  // Set up development environment configuration
  AppConfig.setEnvironment(Environment.development);
  
  // Run the app with development settings
  app.main();
}