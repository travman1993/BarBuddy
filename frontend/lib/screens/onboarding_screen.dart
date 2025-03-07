import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/state/providers/settings_provider.dart';
import 'package:barbuddy/models/user_model.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:barbuddy/routes.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  Gender _selectedGender = Gender.male;
  double _weight = 160; // Default in pounds
  int _age = 25; // Default age
  
  int _currentPageIndex = 0;
  bool _isCompleting = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _completeOnboarding() async {
    if (_currentPageIndex < 3) return; // Not on final page
    
    if (!_formKey.currentState!.validate()) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      _isCompleting = true;
    });
    
    try {
      await userProvider.completeOnboarding(
        name: _nameController.text.trim(),
        gender: _selectedGender,
        weight: _weight,
        age: _age,
      );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing setup: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isMetric = settingsProvider.useMetricUnits;
    
    // Convert weight for display if necessary
    final displayWeight = isMetric 
        ? settingsProvider.convertWeight(_weight, toMetric: true) 
        : _weight;
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Welcome to BarBuddy',
      ),
      body: SafeArea(
        child: IntroductionScreen(
          onChange: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          showBackButton: _currentPageIndex > 0,
          back: const Icon(Icons.arrow_back),
          next: const Icon(Icons.arrow_forward),
          done: const Text('FINISH'),
          onDone: _completeOnboarding,
          dotsDecorator: DotsDecorator(
            activeColor: Theme.of(context).colorScheme.primary,
            size: const Size(10.0, 10.0),
            activeSize: const Size(22.0, 10.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          pages: [
            // Welcome page
            PageViewModel(
              title: 'Track Your Drinks Safely',
              body: 'BarBuddy helps you monitor your alcohol consumption, estimate your BAC, and make safer decisions when drinking.',
              image: Center(
                child: Image.asset('assets/images/onboarding_1.png'),
              ),
              decoration: const PageDecoration(
                pageColor: Colors.white,
                bodyPadding: EdgeInsets.symmetric(horizontal: 16),
                titlePadding: EdgeInsets.only(top: 24, bottom: 16),
              ),
            ),
            
            // Features page
            PageViewModel(
              title: 'Features That Keep You Safe',
              bodyWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    icon: Icons.access_time,
                    title: 'Real-time BAC Tracking',
                    description: 'Estimate your Blood Alcohol Content based on your drinks',
                  ),
                  _buildFeatureItem(
                    icon: Icons.confirmation_num,
                    title: 'Check-in System',
                    description: 'Let loved ones know you\'re safe',
                  ),
                  _buildFeatureItem(
                    icon: Icons.local_taxi,
                    title: 'Ride Service Integration',
                    description: 'Quickly get a ride when needed',
                  ),
                  _buildFeatureItem(
                    icon: Icons.notifications,
                    title: 'Smart Reminders',
                    description: 'Stay hydrated and safe with timely reminders',
                  ),
                ],
              ),
              image: Center(
                child: Image.asset('assets/images/onboarding_2.png'),
              ),
              decoration: const PageDecoration(
                pageColor: Colors.white,
                bodyPadding: EdgeInsets.symmetric(horizontal: 16),
                titlePadding: EdgeInsets.only(top: 24, bottom: 16),
              ),
            ),
            
            // Set up profile page
            PageViewModel(
              title: 'Tell Us About Yourself',
              bodyWidget: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Gender',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<Gender>(
                      segments: const [
                        ButtonSegment(
                          value: Gender.male,
                          label: Text('Male'),
                          icon: Icon(Icons.male),
                        ),
                        ButtonSegment(
                          value: Gender.female,
                          label: Text('Female'),
                          icon: Icon(Icons.female),
                        ),
                        ButtonSegment(
                          value: Gender.other,
                          label: Text('Other'),
                          icon: Icon(Icons.person),
                        ),
                      ],
                      selected: {_selectedGender},
                      onSelectionChanged: (Set<Gender> selection) {
                        setState(() {
                          _selectedGender = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Age',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _age,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.cake),
                      ),
                      items: List.generate(83, (index) => index + 18) // Ages 18-100
                          .map((age) => DropdownMenuItem<int>(
                                value: age,
                                child: Text('$age years'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _age = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value < 18) {
                          return 'You must be at least 18 years old';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              image: Center(
                child: Image.asset('assets/images/onboarding_3.png'),
              ),
              decoration: const PageDecoration(
                pageColor: Colors.white,
                bodyPadding: EdgeInsets.symmetric(horizontal: 16),
                titlePadding: EdgeInsets.only(top: 24, bottom: 16),
              ),
            ),
            
            // Weight page (important for BAC calculation)
            PageViewModel(
              title: 'One Last Thing',
              bodyWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We need your weight to accurately calculate BAC',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: Text(
                      '${displayWeight.toStringAsFixed(0)} ${settingsProvider.weightUnit}',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Slider(
                    value: isMetric ? displayWeight : _weight,
                    min: isMetric ? 45 : 100,  // 100 lbs / 45 kg
                    max: isMetric ? 150 : 330, // 330 lbs / 150 kg
                    divisions: isMetric ? 105 : 230,
                    label: '${isMetric ? displayWeight.toStringAsFixed(0) : _weight.toStringAsFixed(0)} ${settingsProvider.weightUnit}',
                    onChanged: (value) {
                      setState(() {
                        if (isMetric) {
                          // Convert from kg to lbs for storage
                          _weight = settingsProvider.convertWeight(value);
                        } else {
                          _weight = value;
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Imperial (lbs)'),
                      Switch(
                        value: isMetric,
                        onChanged: (value) {
                          settingsProvider.toggleUnits();
                        },
                      ),
                      const Text('Metric (kg)'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Why do we need this?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your body weight is a key factor in calculating blood alcohol concentration (BAC). The same amount of alcohol affects people of different weights differently.',
                  ),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: CustomButton(
                      onPressed: _completeOnboarding,
                      text: 'FINISH SETUP',
                      isLoading: _isCompleting,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
              image: null,
              decoration: const PageDecoration(
                pageColor: Colors.white,
                bodyPadding: EdgeInsets.symmetric(horizontal: 16),
                titlePadding: EdgeInsets.only(top: 24, bottom: 16),
                imageFlex: 0,
                bodyFlex: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}