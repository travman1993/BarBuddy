import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/bac_timer_widget.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/models/bac_model.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/state/providers/drink_provider.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:barbuddy/services/bac_calculator.dart';
import 'package:barbuddy/services/rideshare_service.dart';
import 'package:intl/intl.dart';

class BacEstimateScreen extends StatefulWidget {
  const BacEstimateScreen({Key? key}) : super(key: key);

  @override
  State<BacEstimateScreen> createState() => _BacEstimateScreenState();
}

class _BacEstimateScreenState extends State<BacEstimateScreen> {
  final RideShareService _rideShareService = RideShareService();
  late Timer _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBAC();
    });
    
    // Set up timer to refresh BAC every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _refreshBAC();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }
  
  Future<void> _refreshBAC() async {
    final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
    await drinkProvider.recalculateBAC();
  }
  
  void _getRideshare() {
    _rideShareService.launchRideShare(RideShareApp.uber);
  }
  
  @override
  Widget build(BuildContext context) {
    final drinkProvider = Provider.of<DrinkProvider>(context);
    final bacEstimate = drinkProvider.currentBAC;
    final contributingDrinks = drinkProvider.getContributingDrinks(bacEstimate);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'BAC Estimate',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBAC,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BAC Timer Widget
              BACTimerWidget(
                bacEstimate: bacEstimate,
                onRefresh: _refreshBAC,
                showDetailedInfo: true,
              ),
              
              const SizedBox(height: 24),
              
              // Get a Ride Button (shown if BAC is above legal limit)
              if (bacEstimate.bac >= kLegalDrivingLimit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: CustomButton(
                    onPressed: _getRideshare,
                    text: kRideShareButtonText,
                    icon: Icons.local_taxi,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              
              // Disclaimer
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Disclaimer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This BAC estimate is for informational purposes only and should not be used to determine if you are legally fit to drive. The only safe amount of alcohol for driving is zero.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Effects section
              Text(
                'Possible Effects at Current BAC',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Level: ${BACCalculator.getRiskLevel(bacEstimate.bac)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _getBACColor(bacEstimate.level),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...BACCalculator.getPossibleEffects(bacEstimate.bac)
                          .map((effect) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.arrow_right, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(effect)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Contributing drinks section
              Text(
                'Contributing Drinks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (contributingDrinks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No drinks are currently contributing to your BAC'),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contributingDrinks.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final drink = contributingDrinks[index];
                      return ListTile(
                        leading: _getDrinkTypeIcon(drink.type),
                        title: Text(drink.displayName),
                        subtitle: Text(
                          '${drink.amount.toStringAsFixed(1)} oz • ${drink.standardDrinks.toStringAsFixed(1)} standard drinks • ${DateFormat.jm().format(drink.timestamp)}',
                        ),
                        trailing: Text(
                          '${DateFormat.jm().format(drink.timestamp)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Standard drink explanation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What is a Standard Drink?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A standard drink contains about 0.6 fluid ounces (14 grams) of pure alcohol. This is approximately:',
                      ),
                      const SizedBox(height: 8),
                      _buildStandardDrinkItem(
                        icon: Icons.sports_bar,
                        text: '12 oz of regular beer (5% alcohol)',
                      ),
                      _buildStandardDrinkItem(
                        icon: Icons.wine_bar,
                        text: '5 oz of wine (12% alcohol)',
                      ),
                      _buildStandardDrinkItem(
                        icon: Icons.local_bar,
                        text: '1.5 oz of distilled spirits (40% alcohol)',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStandardDrinkItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  Icon _getDrinkTypeIcon(DrinkType type) {
    switch (type) {
      case DrinkType.beer:
        return const Icon(Icons.sports_bar);
      case DrinkType.wine:
        return const Icon(Icons.wine_bar);
      case DrinkType.liquor:
        return const Icon(Icons.local_bar);
      case DrinkType.cocktail:
        return const Icon(Icons.nightlife);
      case DrinkType.custom:
        return const Icon(Icons.local_drink);
    }
  }
  
  Color _getBACColor(BACLevel level) {
    switch (level) {
      case BACLevel.safe:
        return kSafeBAC;
      case BACLevel.caution:
        return kCautionBAC;
      case BACLevel.warning:
      case BACLevel.danger:
        return kDangerBAC;
    }
  }
}