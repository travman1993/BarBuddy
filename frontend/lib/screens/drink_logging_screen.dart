import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/state/providers/drink_provider.dart';
import 'package:barbuddy/services/bac_calculator.dart';
import 'package:barbuddy/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class DrinkLoggingScreen extends StatefulWidget {
  const DrinkLoggingScreen({Key? key}) : super(key: key);

  @override
  State<DrinkLoggingScreen> createState() => _DrinkLoggingScreenState();
}

class _DrinkLoggingScreenState extends State<DrinkLoggingScreen> {
  final NotificationService _notificationService = NotificationService();
  
  // Controllers
  final _customNameController = TextEditingController();
  final _customAlcoholController = TextEditingController();
  final _customAmountController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Form state
  DrinkType _selectedType = DrinkType.beer;
  double _alcoholPercentage = 5.0; // Default for beer
  double _amount = 12.0; // Default for beer (oz)
  String? _currentLocation;
  bool _isCustom = false;
  bool _isLoading = false;
  bool _showLocationLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize with default values for the selected drink type
    _updateDrinkDefaults();
    // Get current location if permission available
    _checkLocationPermission();
  }
  
  @override
  void dispose() {
    _customNameController.dispose();
    _customAlcoholController.dispose();
    _customAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  // Update drink defaults when type changes
  void _updateDrinkDefaults() {
    final String typeString = _selectedType.toString().split('.').last;
    final Map<String, dynamic> defaultValues = kStandardDrinks[typeString] ?? kStandardDrinks['Beer']!;
    
    setState(() {
      _alcoholPercentage = defaultValues['defaultAbv'];
      _amount = defaultValues['standardOz'];
      
      // Update controllers for custom drinks
      if (_isCustom) {
        _customAlcoholController.text = _alcoholPercentage.toString();
        _customAmountController.text = _amount.toString();
      }
    });
  }
  
  // Check location permission
  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }
  
  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _showLocationLoading = true;
    });
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationString = _formatLocation(place);
        
        setState(() {
          _currentLocation = locationString;
          _showLocationLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _showLocationLoading = false;
      });
    }
  }
  
  // Format location string
  String _formatLocation(Placemark place) {
    final List<String> components = [];
    
    if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      components.add(place.thoroughfare!);
    }
    
    if (place.locality != null && place.locality!.isNotEmpty) {
      components.add(place.locality!);
    }
    
    return components.join(', ');
  }
  
  // Request location permission
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }
  
  // Toggle between custom drink and preset
  void _toggleCustomDrink() {
    setState(() {
      _isCustom = !_isCustom;
      if (_isCustom) {
        // Initialize custom controllers
        _customAlcoholController.text = _alcoholPercentage.toString();
        _customAmountController.text = _amount.toString();
        _selectedType = DrinkType.custom;
      } else {
        // Reset to beer defaults
        _selectedType = DrinkType.beer;
        _updateDrinkDefaults();
      }
    });
  }
  
  // Update alcohol percentage and amount from controllers
  void _updateCustomValues() {
    final alcoholText = _customAlcoholController.text;
    final amountText = _customAmountController.text;
    
    setState(() {
      _alcoholPercentage = double.tryParse(alcoholText) ?? 5.0;
      _amount = double.tryParse(amountText) ?? 12.0;
    });
  }
  
  // Save the drink
  Future<void> _saveDrink() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // If custom, update values from controllers
      if (_isCustom) {
        _updateCustomValues();
      }
      
      // Create new drink
      final newDrink = await drinkProvider.addDrink(
        userId: userProvider.currentUser.id,
        type: _selectedType,
        name: _isCustom ? _customNameController.text : null,
        alcoholPercentage: _alcoholPercentage,
        amount: _amount,
        location: _currentLocation,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      // Schedule notifications
      await _notificationService.scheduleHydrationReminder();
      await _notificationService.scheduleCheckInReminder(newDrink.timestamp);
      
      // Calculate new BAC and show safety alerts if needed
      final newBac = await drinkProvider.recalculateBAC();
      await _notificationService.showSafetyAlert(newBac);
      
      // Go back to previous screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving drink: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  // Save a quick standard drink
  Future<void> _quickAddStandardDrink(DrinkType type) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Add standard drink
      final newDrink = await drinkProvider.addStandardDrink(
        userId: userProvider.currentUser.id,
        type: type,
        location: _currentLocation,
      );
      
      // Schedule notifications
      await _notificationService.scheduleHydrationReminder();
      await _notificationService.scheduleCheckInReminder(newDrink.timestamp);
      
      // Calculate new BAC and show safety alerts if needed
      final newBac = await drinkProvider.recalculateBAC();
      await _notificationService.showSafetyAlert(newBac);
      
      // Go back to previous screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving drink: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  // Get human-readable drink type name
  String _getDrinkTypeName(DrinkType type) {
    switch (type) {
      case DrinkType.beer:
        return 'Beer';
      case DrinkType.wine:
        return 'Wine';
      case DrinkType.liquor:
        return 'Liquor';
      case DrinkType.cocktail:
        return 'Cocktail';
      case DrinkType.custom:
        return 'Custom';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Add a Drink',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Add Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Add',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickAddButton(
                                icon: Icons.sports_bar,
                                label: 'Beer',
                                onTap: () => _quickAddStandardDrink(DrinkType.beer),
                              ),
                              _buildQuickAddButton(
                                icon: Icons.wine_bar,
                                label: 'Wine',
                                onTap: () => _quickAddStandardDrink(DrinkType.wine),
                              ),
                              _buildQuickAddButton(
                                icon: Icons.local_bar,
                                label: 'Liquor',
                                onTap: () => _quickAddStandardDrink(DrinkType.liquor),
                              ),
                              _buildQuickAddButton(
                                icon: Icons.nightlife,
                                label: 'Cocktail',
                                onTap: () => _quickAddStandardDrink(DrinkType.cocktail),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Custom Drink Toggle
                  SwitchListTile(
                    title: const Text('Custom Drink'),
                    subtitle: Text(_isCustom 
                        ? 'Define your own drink' 
                        : 'Select from presets'),
                    value: _isCustom,
                    onChanged: (value) => _toggleCustomDrink(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Drink Details Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drink Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          
                          if (_isCustom) ...[
                            // Custom Drink Form
                            TextField(
                              controller: _customNameController,
                              decoration: const InputDecoration(
                                labelText: 'Drink Name (Optional)',
                                hintText: 'E.g., Margarita, IPA, etc.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _customAlcoholController,
                              decoration: const InputDecoration(
                                labelText: 'Alcohol Percentage (%)',
                                hintText: 'E.g., 5.0 for 5% ABV',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateCustomValues(),
                            ),
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _customAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount (fluid oz)',
                                hintText: 'E.g., 12 for a 12 oz beer',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateCustomValues(),
                            ),
                          ] else ...[
                            // Preset Drink Form
                            DropdownButtonFormField<DrinkType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Drink Type',
                              ),
                              items: DrinkType.values
                                  .where((type) => type != DrinkType.custom)
                                  .map((type) {
                                return DropdownMenuItem<DrinkType>(
                                  value: type,
                                  child: Text(_getDrinkTypeName(type)),
                                );
                              }).toList(),
                              onChanged: (DrinkType? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedType = newValue;
                                    _updateDrinkDefaults();
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Alcohol Percentage Slider
                            Row(
                              children: [
                                const Text('Alcohol %:'),
                                Expanded(
                                  child: Slider(
                                    value: _alcoholPercentage,
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    label: _alcoholPercentage.toStringAsFixed(1) + '%',
                                    onChanged: (value) {
                                      setState(() {
                                        _alcoholPercentage = value;
                                      });
                                    },
                                  ),
                                ),
                                Text('${_alcoholPercentage.toStringAsFixed(1)}%'),
                              ],
                            ),
                            
                            // Amount Slider
                            Row(
                              children: [
                                const Text('Amount:'),
                                Expanded(
                                  child: Slider(
                                    value: _amount,
                                    min: 0,
                                    max: 32,
                                    divisions: 32,
                                    label: _amount.toStringAsFixed(1) + ' oz',
                                    onChanged: (value) {
                                      setState(() {
                                        _amount = value;
                                      });
                                    },
                                  ),
                                ),
                                Text('${_amount.toStringAsFixed(1)} oz'),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Location
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Location: ${_currentLocation ?? 'Unknown'}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              if (_showLocationLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.location_on),
                                  onPressed: _requestLocationPermission,
                                  tooltip: 'Get Current Location',
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Notes
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              hintText: 'E.g., With dinner, at the bar, etc.',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Save Button
                  CustomButton(
                    onPressed: _saveDrink,
                    text: 'SAVE DRINK',
                    icon: Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildQuickAddButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}