import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/state/providers/drink_provider.dart';
import 'package:barbuddy/models/bac_model.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:barbuddy/services/rideshare_service.dart';
import 'package:barbuddy/services/emergency_service.dart';
import 'package:barbuddy/services/notification_service.dart';
import 'package:barbuddy/state/providers/user_provider.dart';

class SafetyAlertsScreen extends StatefulWidget {
  const SafetyAlertsScreen({Key? key}) : super(key: key);

  @override
  State<SafetyAlertsScreen> createState() => _SafetyAlertsScreenState();
}

class _SafetyAlertsScreenState extends State<SafetyAlertsScreen> {
  final RideShareService _rideShareService = RideShareService();
  final EmergencyService _emergencyService = EmergencyService();
  final NotificationService _notificationService = NotificationService();
  
  bool _isSendingAlert = false;
  
  Future<void> _callEmergencyContact() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final primaryContact = await _emergencyService.getPrimaryContact(
        userProvider.currentUser.id,
      );
      
      if (primaryContact == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No primary emergency contact found. Please add one in settings.'),
          ),
        );
        return;
      }
      
      await _emergencyService.callEmergencyContact(primaryContact);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call emergency contact: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  Future<void> _sendEmergencyAlert() async {
    setState(() {
      _isSendingAlert = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      await _emergencyService.sendEmergencyAlert(
        userId: userProvider.currentUser.id,
        userName: userProvider.currentUser.name ?? 'Your friend',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent to your contacts'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending alert: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSendingAlert = false;
      });
    }
  }
  
  Future<void> _getRideshare() async {
    _rideShareService.launchRideShare(RideShareApp.uber);
  }
  
  Future<void> _sendCheckIn() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      await _emergencyService.sendCheckInMessage(
        userId: userProvider.currentUser.id,
        userName: userProvider.currentUser.name ?? 'Your friend',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in message sent'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending check-in: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final drinkProvider = Provider.of<DrinkProvider>(context);
    final bacEstimate = drinkProvider.currentBAC;
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Safety Tools',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alert Status Card
            _buildAlertStatusCard(bacEstimate),
            
            const SizedBox(height: 24),
            
            // Safety Tools Section
            Text(
              'Safety Tools',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Rideshare Button
            CustomButton(
              onPressed: _getRideshare,
              text: 'GET A RIDE',
              icon: Icons.local_taxi,
              color: Theme.of(context).colorScheme.primary,
            ),
            
            const SizedBox(height: 16),
            
            // Check-in Button
            CustomButton(
              onPressed: _sendCheckIn,
              text: 'SEND CHECK-IN',
              icon: Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.secondary,
            ),
            
            const SizedBox(height: 16),
            
            // Call Emergency Contact Button
            CustomButton(
              onPressed: _callEmergencyContact,
              text: 'CALL EMERGENCY CONTACT',
              icon: Icons.phone,
              color: Colors.orange,
            ),
            
            const SizedBox(height: 16),
            
            // Emergency Alert Button
            CustomButton(
              onPressed: _isSendingAlert ? null : _sendEmergencyAlert,
              text: 'SEND EMERGENCY ALERT',
              icon: Icons.emergency,
              color: Theme.of(context).colorScheme.error,
              isLoading: _isSendingAlert,
            ),
            
            const SizedBox(height: 32),
            
            // Safety Tips Section
            Text(
              'Safety Tips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Safety Tips Cards
            _buildSafetyTipCard(
              icon: Icons.water_drop,
              title: 'Stay Hydrated',
              content: 'Alternate alcoholic drinks with water to reduce dehydration and slow alcohol absorption.',
            ),
            
            const SizedBox(height: 16),
            
            _buildSafetyTipCard(
              icon: Icons.restaurant,
              title: 'Eat Before Drinking',
              content: 'Having food in your stomach slows alcohol absorption and helps prevent rapid BAC increases.',
            ),
            
            const SizedBox(height: 16),
            
            _buildSafetyTipCard(
              icon: Icons.group,
              title: 'Use the Buddy System',
              content: 'Always go out with friends and look out for one another. Never leave a friend behind.',
            ),
            
            const SizedBox(height: 16),
            
            _buildSafetyTipCard(
              icon: Icons.warning,
              title: 'Know Your Limits',
              content: 'Everyone metabolizes alcohol differently. Pay attention to how you feel and pace yourself accordingly.',
            ),
            
            const SizedBox(height: 32),
            
            // Emergency Resources
            Text(
              'Emergency Resources',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_police, color: Colors.blue),
                    title: const Text('Police / Ambulance / Fire'),
                    subtitle: const Text('For immediate emergency assistance'),
                    trailing: IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () => _callEmergencyNumber('911'),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.local_hospital, color: Colors.red),
                    title: const Text('Poison Control Center'),
                    subtitle: const Text('For alcohol poisoning concerns'),
                    trailing: IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () => _callEmergencyNumber('1-800-222-1222'),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.support_agent, color: Colors.green),
                    title: const Text('Substance Abuse Helpline'),
                    subtitle: const Text('For substance abuse support'),
                    trailing: IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () => _callEmergencyNumber('1-800-662-4357'),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlertStatusCard(BACEstimate bacEstimate) {
    Color statusColor;
    String statusText;
    String statusDescription;
    IconData statusIcon;
    
    switch (bacEstimate.level) {
      case BACLevel.safe:
        statusColor = kSafeBAC;
        statusText = 'Low Risk';
        statusDescription = 'Your BAC level indicates minimal risk. Always drink responsibly.';
        statusIcon = Icons.check_circle;
        break;
      case BACLevel.caution:
        statusColor = kCautionBAC;
        statusText = 'Caution';
        statusDescription = 'Your BAC level is approaching the legal limit. Consider slowing down.';
        statusIcon = Icons.warning;
        break;
      case BACLevel.warning:
        statusColor = kDangerBAC;
        statusText = 'Warning';
        statusDescription = 'Your BAC level is at or above the legal limit. DO NOT drive. Use a rideshare service.';
        statusIcon = Icons.warning_amber;
        break;
      case BACLevel.danger:
        statusColor = kDangerBAC;
        statusText = 'DANGER';
        statusDescription = 'Your BAC is at a high level. DO NOT drive. Seek help if feeling unwell.';
        statusIcon = Icons.dangerous;
        break;
    }
    
    return Card(
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Status: $statusText',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'BAC: ${bacEstimate.bac.toStringAsFixed(3)}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(statusDescription),
            if (bacEstimate.bac >= kLegalDrivingLimit) ...[
              const SizedBox(height: 16),
              CustomButton(
                onPressed: _getRideshare,
                text: 'GET A RIDE NOW',
                icon: Icons.local_taxi,
                color: bacEstimate.level == BACLevel.danger 
                    ? Theme.of(context).colorScheme.error 
                    : Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSafetyTipCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _callEmergencyNumber(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not call $phoneNumber'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}