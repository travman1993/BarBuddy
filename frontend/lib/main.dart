import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/state/providers/drink_provider.dart';
import 'package:barbuddy/state/providers/settings_provider.dart';
import 'package:barbuddy/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Notification Service
  await NotificationService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => DrinkProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: const BarBuddyApp(),
    ),
  );
}