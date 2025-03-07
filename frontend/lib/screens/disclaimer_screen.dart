import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:barbuddy/routes.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({Key? key}) : super(key: key);

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _disclaimer1Accepted = false;
  bool _disclaimer2Accepted = false;
  bool _isAccepting = false;
  
  bool get _canAccept => _disclaimer1Accepted && _disclaimer2Accepted;
  
  Future<void> _acceptDisclaimer() async {
    if (!_canAccept) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      _isAccepting = true;
    });
    
    try {
      await userProvider.acceptDisclaimer();
      
      if (mounted) {
        // Check if user needs to complete onboarding
        if (userProvider.isFirstTime) {
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting disclaimer: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Important Disclaimer',
        backgroundColor: Colors.red,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please Read Carefully',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        kDisclaimerText,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Additional Health Warning',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Excessive alcohol consumption poses serious health risks, including but not limited to liver damage, addiction, increased risk of accidents, and impaired judgment. If you believe you may have a drinking problem, please seek professional help.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      CheckboxListTile(
                        title: const Text(
                          'I understand that BAC estimates provided by BarBuddy are approximate and should not be used to determine if I am legally fit to drive.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _disclaimer1Accepted,
                        onChanged: (value) {
                          setState(() {
                            _disclaimer1Accepted = value ?? false;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text(
                          'I understand that the only truly safe amount of alcohol to consume before driving is ZERO.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _disclaimer2Accepted,
                        onChanged: (value) {
                          setState(() {
                            _disclaimer2Accepted = value ?? false;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: _canAccept ? _acceptDisclaimer : null,
                text: 'I UNDERSTAND AND AGREE',
                color: _canAccept ? Theme.of(context).colorScheme.primary : Colors.grey,
                isLoading: _isAccepting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}