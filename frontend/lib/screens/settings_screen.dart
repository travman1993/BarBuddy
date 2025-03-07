import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/state/providers/settings_provider.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      debugPrint('Error loading app version: $e');
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }
  
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $url'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  Future<void> _showResetConfirmation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will reset all settings to their default values. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resetSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      await settingsProvider.resetToDefaults();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting settings: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'This will remove all your data from this device. Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.signOut();
                
                // Navigate to onboarding screen
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/disclaimer',
                    (_) => false,
                  );
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Theme Settings
                _buildSectionHeader('Appearance'),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) => SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: settings.isDarkMode,
                    onChanged: (_) => settings.toggleDarkMode(),
                  ),
                ),
                
                // Units Settings
                _buildSectionHeader('Units'),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) => SwitchListTile(
                    title: const Text('Use Metric Units'),
                    subtitle: Text(
                      'Weight: ${settings.useMetricUnits ? 'kg' : 'lbs'}, '
                      'Volume: ${settings.useMetricUnits ? 'ml' : 'oz'}',
                    ),
                    value: settings.useMetricUnits,
                    onChanged: (_) => settings.toggleUnits(),
                  ),
                ),
                
                // Notification Settings
                _buildSectionHeader('Notifications'),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) => Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Safety Alerts'),
                        subtitle: const Text('Alerts about high BAC levels'),
                        value: settings.enableSafetyAlerts,
                        onChanged: (value) => settings.updateNotificationSettings(
                          enableSafetyAlerts: value,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Check-in Reminders'),
                        subtitle: const Text('Reminders to check in with contacts'),
                        value: settings.enableCheckInReminders,
                        onChanged: (value) => settings.updateNotificationSettings(
                          enableCheckInReminders: value,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('BAC Updates'),
                        subtitle: const Text('Notifications about your BAC level'),
                        value: settings.enableBACUpdates,
                        onChanged: (value) => settings.updateNotificationSettings(
                          enableBACUpdates: value,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Hydration Reminders'),
                        subtitle: const Text('Reminders to drink water'),
                        value: settings.enableHydrationReminders,
                        onChanged: (value) => settings.updateNotificationSettings(
                          enableHydrationReminders: value,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Privacy Settings
                _buildSectionHeader('Privacy'),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) => Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Save Location Data'),
                        subtitle: const Text('Save location with your drinks'),
                        value: settings.saveLocationData,
                        onChanged: (value) => settings.updatePrivacySettings(
                          saveLocationData: value,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Usage Analytics'),
                        subtitle: const Text('Help improve BarBuddy by sharing anonymous usage data'),
                        value: settings.analyticsEnabled,
                        onChanged: (value) => settings.updatePrivacySettings(
                          analyticsEnabled: value,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Account Settings
                _buildSectionHeader('Account'),
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) => Column(
                    children: [
                      ListTile(
                        title: const Text('Your Name'),
                        subtitle: Text(userProvider.currentUser.name ?? 'Not set'),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _showEditNameDialog(context, userProvider),
                      ),
                      ListTile(
                        title: const Text('Weight'),
                        subtitle: Consumer<SettingsProvider>(
                          builder: (context, settings, _) {
                            final displayWeight = settings.useMetricUnits
                                ? settings.convertWeight(
                                    userProvider.currentUser.weight,
                                    toMetric: true,
                                  )
                                : userProvider.currentUser.weight;
                            
                            return Text(
                              '${displayWeight.toStringAsFixed(0)} ${settings.weightUnit}',
                            );
                          },
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _showEditWeightDialog(context, userProvider),
                      ),
                      ListTile(
                        title: const Text('Gender'),
                        subtitle: Text(_formatGender(userProvider.currentUser.gender)),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _showEditGenderDialog(context, userProvider),
                      ),
                    ],
                  ),
                ),
                
                // Legal & Support
                _buildSectionHeader('Legal & Support'),
                ListTile(
                  title: const Text('Privacy Policy'),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  onTap: () => _launchUrl(kPrivacyPolicyUrl),
                ),
                ListTile(
                  title: const Text('Terms of Service'),
                  leading: const Icon(Icons.description_outlined),
                  onTap: () => _launchUrl(kTermsOfServiceUrl),
                ),
                ListTile(
                  title: const Text('Contact Support'),
                  leading: const Icon(Icons.support_agent_outlined),
                  onTap: () => _launchUrl('mailto:$kSupportEmail'),
                ),
                
                // About & Debug
                _buildSectionHeader('About'),
                ListTile(
                  title: const Text('Version'),
                  subtitle: Text(_appVersion),
                  leading: const Icon(Icons.info_outlined),
                ),
                
                // Advanced Actions
                _buildSectionHeader('Advanced'),
                ListTile(
                  title: const Text('Reset Settings'),
                  subtitle: const Text('Reset all settings to defaults'),
                  leading: const Icon(Icons.settings_backup_restore),
                  onTap: _showResetConfirmation,
                ),
                ListTile(
                  title: const Text('Sign Out'),
                  subtitle: const Text('Remove all your data from this device'),
                  leading: const Icon(Icons.logout),
                  onTap: _signOut,
                ),
                
                const SizedBox(height: 32),
              ],
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  String _formatGender(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
  
  void _showEditNameDialog(BuildContext context, UserProvider userProvider) {
    final nameController = TextEditingController(
      text: userProvider.currentUser.name ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Your Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  await userProvider.updateUser(name: name);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating name: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
  
  void _showEditWeightDialog(BuildContext context, UserProvider userProvider) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final isMetric = settingsProvider.useMetricUnits;
    
    // Convert weight for display if necessary
    double currentWeight = userProvider.currentUser.weight;
    if (isMetric) {
      currentWeight = settingsProvider.convertWeight(currentWeight, toMetric: true);
    }
    
    double weight = currentWeight;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Weight (${settingsProvider.weightUnit})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weight.toStringAsFixed(0),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Slider(
                value: weight,
                min: isMetric ? 45 : 100,  // 100 lbs / 45 kg
                max: isMetric ? 150 : 330, // 330 lbs / 150 kg
                divisions: isMetric ? 105 : 230,
                onChanged: (value) {
                  setState(() {
                    weight = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  // Convert back to lbs for storage if necessary
                  double weightToSave = isMetric
                      ? settingsProvider.convertWeight(weight)
                      : weight;
                  
                  await userProvider.updateUser(weight: weightToSave);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weight updated'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating weight: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditGenderDialog(BuildContext context, UserProvider userProvider) {
    Gender selectedGender = userProvider.currentUser.gender;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your gender is used to calculate your BAC more accurately.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
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
                selected: {selectedGender},
                onSelectionChanged: (Set<Gender> selection) {
                  setState(() {
                    selectedGender = selection.first;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  await userProvider.updateUser(gender: selectedGender);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gender updated'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating gender: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}