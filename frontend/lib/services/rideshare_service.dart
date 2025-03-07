import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

enum RideShareApp {
  uber,
  lyft,
  taxi,
  other
}

class RideShareService {
  // Check if a specific ride share app is installed
  Future<bool> isAppInstalled(RideShareApp app) async {
    // For iOS, we can't check if an app is installed without the custom URL scheme
    if (Platform.isIOS) {
      return true; // Assume it's installed, iOS will handle if it's not
    }
    
    // For Android, we can check by package name
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      
      // Android 11+ restrictions on package visibility
      if (androidInfo.version.sdkInt >= 30) {
        return true; // Assume it's installed due to Android 11+ restrictions
      }
      
      final String packageName = _getPackageName(app);
      try {
        // This functionality is limited on newer Android versions
        // and might not work properly
        return await canLaunchUrl(Uri.parse('package:$packageName'));
      } catch (e) {
        return false;
      }
    }
    
    return false;
  }
  
  // Get the package name for the ride share app
  String _getPackageName(RideShareApp app) {
    switch (app) {
      case RideShareApp.uber:
        return 'com.ubercab';
      case RideShareApp.lyft:
        return 'me.lyft.android';
      case RideShareApp.taxi:
        return 'com.google.android.apps.taxi.rider';
      case RideShareApp.other:
        return '';
    }
  }
  
  // Launch ride share app
  Future<bool> launchRideShare(RideShareApp app, {String? destinationAddress}) async {
    final Uri uri = await _buildRideShareUri(app, destinationAddress: destinationAddress);
    
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching ride share app: $e');
      return false;
    }
  }
  
  // Build the URI for the ride share app
  Future<Uri> _buildRideShareUri(RideShareApp app, {String? destinationAddress}) async {
    // Current location
    Position? position;
    try {
      final hasPermission = await _requestLocationPermission();
      if (hasPermission) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
    
    String? pickupLat, pickupLng;
    if (position != null) {
      pickupLat = position.latitude.toString();
      pickupLng = position.longitude.toString();
    }
    
    switch (app) {
      case RideShareApp.uber:
        return _buildUberUri(pickupLat, pickupLng, destinationAddress);
      case RideShareApp.lyft:
        return _buildLyftUri(pickupLat, pickupLng, destinationAddress);
      case RideShareApp.taxi:
        return _buildGoogleTaxiUri(destinationAddress);
      case RideShareApp.other:
        // Just open maps as a fallback
        return _buildMapsUri(destinationAddress);
    }
  }
  
  // Build URI for Uber
  Uri _buildUberUri(String? pickupLat, String? pickupLng, String? destinationAddress) {
    String path = 'order-ride';
    Map<String, dynamic> params = {};
    
    // Add pickup if available
    if (pickupLat != null && pickupLng != null) {
      params['pickup[latitude]'] = pickupLat;
      params['pickup[longitude]'] = pickupLng;
    }
    
    // Add destination if available
    if (destinationAddress != null && destinationAddress.isNotEmpty) {
      params['dropoff[formatted_address]'] = destinationAddress;
    }
    
    // Add app details
    params['product_id'] = 'a1111c8c-c720-46c3-8534-2fcdd730040d'; // UberX
    params['link_text'] = 'View ride';
    
    // Mobile deep link
    if (Platform.isIOS) {
      return Uri.https('m.uber.com', path, params);
    } else {
      return Uri.https('m.uber.com', path, params);
    }
  }
  
  // Build URI for Lyft
  Uri _buildLyftUri(String? pickupLat, String? pickupLng, String? destinationAddress) {
    Map<String, dynamic> params = {};
    
    // Add pickup if available
    if (pickupLat != null && pickupLng != null) {
      params['pickup[latitude]'] = pickupLat;
      params['pickup[longitude]'] = pickupLng;
    }
    
    // Add destination if available
    if (destinationAddress != null && destinationAddress.isNotEmpty) {
      params['destination'] = destinationAddress;
    }
    
    // Add ride type (standard Lyft)
    params['ride_type'] = 'lyft';
    
    // Mobile deep link
    if (Platform.isIOS) {
      return Uri.parse('lyft://ridetype?${Uri(queryParameters: params).query}');
    } else {
      return Uri.https('ride.lyft.com', '', params);
    }
  }
  
  // Build URI for Google Maps Taxi feature
  Uri _buildGoogleTaxiUri(String? destinationAddress) {
    Map<String, dynamic> params = {
      'action': 'taxi',
    };
    
    if (destinationAddress != null && destinationAddress.isNotEmpty) {
      params['destination'] = destinationAddress;
    }
    
    return Uri.https('maps.google.com', '/maps', params);
  }
  
  // Build URI for general maps as a fallback
  Uri _buildMapsUri(String? destinationAddress) {
    Map<String, dynamic> params = {};
    
    if (destinationAddress != null && destinationAddress.isNotEmpty) {
      params['daddr'] = destinationAddress;
    }
    
    return Uri.https('maps.google.com', '/maps', params);
  }
  
  // Launch phone dialer for taxi
  Future<bool> callTaxi(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      return await launchUrl(phoneUri);
    } catch (e) {
      debugPrint('Error launching phone call: $e');
      return false;
    }
  }
  
  // Request location permission
  Future<bool> _requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  // Get available ride options
  Future<List<RideShareApp>> getAvailableRideOptions() async {
    List<RideShareApp> available = [];
    
    if (await isAppInstalled(RideShareApp.uber)) {
      available.add(RideShareApp.uber);
    }
    
    if (await isAppInstalled(RideShareApp.lyft)) {
      available.add(RideShareApp.lyft);
    }
    
    // Google Maps is generally available on most devices
    available.add(RideShareApp.taxi);
    
    return available;
  }
}