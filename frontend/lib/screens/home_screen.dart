import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/bac_timer_widget.dart';
import 'package:barbuddy/widgets/drink_card.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/models/bac_model.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/models/user_model.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/state/providers/drink_provider.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:barbuddy/routes.dart';
import 'package:barbuddy/services/notification_service.dart';
import 'package:barbuddy/services/rideshare_service.dart';
import 'package:barbuddy/services/emergency_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final RideShareService _rideShareService = RideShareService();
  final EmergencyService _emergencyService = EmergencyService();
  
  // Refresher for recent drinks
  Future<void> _refreshDrinks() async {
    final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
    await drinkProvider.loadRecentDrinks();
  }
  
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
    
    // Check if disclaimer has been accepted
    if (!userProvider.currentUser.hasAcceptedDisclaimer) {
      Navigator.pushNamed(context, AppRoutes.disclaimer);
      return;
    }
    
    // Load user's drinks
    await drinkProvider.loadRecentDrinks();
  }
  
  void _navigateToDrinkLogging() {
    Navigator.pushNamed(context, AppRoutes.drinkLogging)
        .then((_) => _refreshDrinks());
  }
  
  void _navigateToEmergencyContacts() {
    Navigator.pushNamed(context, AppRoutes.emergencyContact);
  }
  
  Future<void> _getRideshare() async {
    final options = await _rideShareService.getAvailableRideOptions();
    
    if (!mounted) return;
    
    if (options.isEmpty) {
      // Fallback to maps if no ride options available
      _rideShareService.launchRideShare(RideShareApp.taxi);
      return;
    }
    
    // Show options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Get a Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose your preferred ride service:'),
            const SizedBox(height: 16),
            ...options.map((option) => 
              ListTile(
                leading: _getRideShareIcon(option),
                title: Text(_getRideShareName(option)),
                onTap: () {
                  Navigator.pop(context);
                  _rideShareService.launchRideShare(option);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Icon _getRideShareIcon(RideShareApp app) {
    switch (app) {
      case RideShareApp.uber:
        return const Icon(Icons.local_taxi);
      case RideShareApp.lyft:
        return const Icon(Icons.directions_car);
      case RideShareApp.taxi:
        return const Icon(Icons.map);
      case RideShareApp.other:
        return const Icon(Icons.more_horiz);
    }
  }
  
  String _getRideShareName(RideShareApp app) {
    switch (app) {
      case RideShareApp.uber:
        return 'Uber';
      case RideShareApp.lyft:
        return 'Lyft';
      case RideShareApp.taxi:
        return 'Maps/Taxi';
      case RideShareApp.other:
        return 'Other Options';
    }
  }
  
  Future<void> _showCheckInOptions() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Let others know you\'re okay'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Quick Check-In'),
              subtitle: const Text('Send a simple check-in message'),
              onTap: () {
                Navigator.pop(context);
                _sendCheckIn(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Emergency Contact'),
              subtitle: const Text('Call your primary contact directly'),
              onTap: () {
                Navigator.pop(context);
                _callEmergencyContact();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _sendCheckIn(User user) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending check-in message...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      await _emergencyService.sendCheckInMessage(
        userId: user.id,
        userName: user.name ?? 'Your friend',
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in message sent successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send check-in: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
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
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to call emergency contact: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final drinkProvider = Provider.of<DrinkProvider>(context);
    
    return Scaffold(
      appBar: const CustomAppBar(title: 'BarBuddy'),
      body: RefreshIndicator(
        onRefresh: _refreshDrinks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BAC Card
              BACTimerWidget(
                bacEstimate: drinkProvider.currentBAC,
                onRefresh: _refreshDrinks,
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: _getRideshare,
                      text: 'GET A RIDE',
                      icon: Icons.local_taxi,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      onPressed: _showCheckInOptions,
                      text: 'CHECK IN',
                      icon: Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Emergency Button
              CustomButton(
                onPressed: _navigateToEmergencyContacts,
                text: kEmergencyButtonText,
                icon: Icons.emergency,
                color: Theme.of(context).colorScheme.error,
              ),
              
              const SizedBox(height: 24),
              
              // Recent Drinks Section
              Text(
                'Recent Drinks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              
              const SizedBox(height: 8),
              
              // Recent Drinks List
              if (drinkProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (drinkProvider.recentDrinks.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/empty_drinks.png',
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        const Text('No drinks logged yet'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _navigateToDrinkLogging,
                          child: const Text('Add your first drink'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: drinkProvider.recentDrinks.length,
                  itemBuilder: (context, index) {
                    final drink = drinkProvider.recentDrinks[index];
                    return DrinkCard(
                      drink: drink,
                      onDelete: () async {
                        await drinkProvider.deleteDrink(drink.id);
                        _refreshDrinks();
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToDrinkLogging,
        child: const Icon(Icons.add),
        tooltip: 'Add Drink',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBar.item(
            icon: Icon(Icons.home),
            label: kHomeLabel,
          ),
          BottomNavigationBar.item(
            icon: Icon(Icons.history),
            label: kHistoryLabel,
          ),
          BottomNavigationBar.item(
            icon: Icon(Icons.settings),
            label: kSettingsLabel,
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.history);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.settings);
              break;
          }
        },
      ),
    );
  }
}