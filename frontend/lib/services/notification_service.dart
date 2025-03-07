import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:barbuddy/utils/constants.dart';
import 'package:barbuddy/models/bac_model.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Future<void> init() async {
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );
    
    // Set up notification channels for Android
    await _setupNotificationChannels();
    
    // Request notification permissions
    await requestPermissions();
  }
  
  Future<void> _setupNotificationChannels() async {
    // Safety Alerts Channel
    const AndroidNotificationChannel safetyChannel = AndroidNotificationChannel(
      kSafetyAlertsChannelId,
      'Safety Alerts',
      description: 'Important safety notifications related to your BAC level',
      importance: Importance.high,
    );
    
    // Check-in Reminders Channel
    const AndroidNotificationChannel checkInChannel = AndroidNotificationChannel(
      kCheckInChannelId,
      'Check-in Reminders',
      description: 'Reminders to check in with emergency contacts',
      importance: Importance.high,
    );
    
    // BAC Updates Channel
    const AndroidNotificationChannel bacUpdatesChannel = AndroidNotificationChannel(
      kBACUpdatesChannelId,
      'BAC Updates',
      description: 'Updates about your BAC level and when you\'ll be sober',
      importance: Importance.low,
    );
    
    // Create the channels
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannels([
      safetyChannel,
      checkInChannel,
      bacUpdatesChannel,
    ]);
  }
  
  Future<void> requestPermissions() async {
    await Permission.notification.request();
  }
  
  void onNotificationTap(NotificationResponse response) {
    // Handle notification taps based on payload
    if (response.payload != null) {
      // Parse payload and handle accordingly
      // e.g. navigate to specific screens
    }
  }
  
  // Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? kSafetyAlertsChannelId,
      channelId ?? 'Safety Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iOSDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  // Schedule a notification for the future
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? kSafetyAlertsChannelId,
      channelId ?? 'Safety Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iOSDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
  
  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // BAC-specific notifications
  Future<void> scheduleBACNotifications(BACEstimate bacEstimate) async {
    // Cancel any existing BAC notifications
    await cancelNotification(1);
    await cancelNotification(2);
    
    // Only schedule if BAC is above zero
    if (bacEstimate.bac <= 0) {
      return;
    }
    
    // Schedule notification for when BAC reaches legal limit
    if (bacEstimate.bac > kLegalDrivingLimit) {
      await scheduleNotification(
        id: 1,
        title: 'BAC Update',
        body: 'Your BAC is now below the legal driving limit. Remember that impairment can occur at any BAC level.',
        scheduledTime: bacEstimate.legalTime,
        channelId: kBACUpdatesChannelId,
        payload: 'bac_legal',
      );
    }
    
    // Schedule notification for when BAC reaches zero
    await scheduleNotification(
      id: 2,
      title: 'BAC Update',
      body: 'Your estimated BAC has returned to zero.',
      scheduledTime: bacEstimate.soberTime,
      channelId: kBACUpdatesChannelId,
      payload: 'bac_zero',
    );
  }
  
  // Safety alert based on BAC level
  Future<void> showSafetyAlert(BACEstimate bacEstimate) async {
    if (bacEstimate.bac >= kHighBACThreshold) {
      await showNotification(
        id: 3,
        title: 'High BAC Alert',
        body: 'Your BAC is at a high level. DO NOT drive. Please stay hydrated and consider getting assistance if you feel unwell.',
        channelId: kSafetyAlertsChannelId,
        payload: 'high_bac_alert',
      );
    } else if (bacEstimate.bac >= kLegalDrivingLimit) {
      await showNotification(
        id: 4,
        title: 'BAC Above Legal Limit',
        body: 'Your BAC is above the legal driving limit. DO NOT drive. Consider using a ride-sharing service or calling a friend.',
        channelId: kSafetyAlertsChannelId,
        payload: 'legal_limit_alert',
      );
    }
  }
  
  // Schedule check-in reminder
  Future<void> scheduleCheckInReminder(DateTime drinkTime) async {
    final reminderTime = drinkTime.add(Duration(minutes: kCheckInReminderMinutes));
    
    // Only schedule if reminder time is in the future
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 5,
        title: 'Check-In Reminder',
        body: 'It\'s been a while since your last drink. Would you like to check in with your emergency contacts?',
        scheduledTime: reminderTime,
        channelId: kCheckInChannelId,
        payload: 'check_in_reminder',
      );
    }
  }
  
  // Hydration reminder
  Future<void> scheduleHydrationReminder() async {
    final reminderTime = DateTime.now().add(const Duration(hours: 1));
    
    await scheduleNotification(
      id: 6,
      title: 'Hydration Reminder',
      body: 'Remember to drink water between alcoholic beverages to stay hydrated.',
      scheduledTime: reminderTime,
      channelId: kBACUpdatesChannelId,
      payload: 'hydration_reminder',
    );
  }
}