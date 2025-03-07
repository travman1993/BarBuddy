import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/state/providers/auth_provider.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/routes.dart';
import 'package:barbuddy/utils/validators.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:barbuddy/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  Gender _selectedGender = Gender.male;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if email is already in use
    final isEmailInUse = await authProvider.isEmailInUse(_emailController.text.trim());
    
    if (isEmailInUse && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This email is already in use. Please try another one.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final success = await authProvider.createUserWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      name: _nameController.text.trim(),
      gender: _selectedGender,
    );
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.disclaimer);
    }
  }
  
  Future<void> _googleSignUp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithGoogle();
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.disclaimer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    
                    // Registration Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validateName,
                            enabled: !authProvider.isLoading,
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validateEmail,
                            enabled: !authProvider.isLoading,
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validatePassword,
                            enabled: !authProvider.isLoading,
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            validator: (value) => Validators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                            enabled: !authProvider.isLoading,
                          ),
                          const SizedBox(height: 24),
                          
                          // Gender Selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gender',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'This helps us calculate your BAC more accurately',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Register Button
                          CustomButton(
                            onPressed: _register,
                            text: 'CREATE ACCOUNT',
                            isLoading: authProvider.isLoading,
                          ),
                          
                          // Error Message
                          if (authProvider.error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              authProvider.error!,
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Google Sign Up Button
                          OutlinedButton.icon(
                            onPressed: authProvider.isLoading
                                ? null
                                : _googleSignUp,
                            icon: Image.asset(
                              'assets/images/google_logo.png',
                              height: 24,
                            ),
                            label: const Text('Sign up with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          AppRoutes.login,
                                        );
                                      },
                                child: const Text('Log In'),
                              ),
                            ],
                          ),
                        ],
                      ),
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