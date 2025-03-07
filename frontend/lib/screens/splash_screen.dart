import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/state/providers/auth_provider.dart';
import 'package:barbuddy/routes.dart';
import 'package:barbuddy/utils/constants.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Start animations
    _animationController.forward();
    
    // Navigate after a delay
    _navigateAfterDelay();
  }
  
  Future<void> _navigateAfterDelay() async {
    // Wait for animations to complete
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Check auth status and navigate accordingly
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    switch (authProvider.authStatus) {
      case AuthStatus.authenticated:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case AuthStatus.onboarding:
        Navigator.pushReplacementNamed(context, AppRoutes.disclaimer);
        break;
      case AuthStatus.unauthenticated:
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        break;
      case AuthStatus.unknown:
        // Stay on splash screen until auth status is determined
        // The auth provider should eventually update this
        break;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo_white.png',
                      height: 150,
                    ),
                    const SizedBox(height: 24),
                    
                    // App Name
                    const Text(
                      kAppName,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tagline
                    const Text(
                      kAppTagline,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 64),
                    
                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}