import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/custom_button.dart';
import 'package:barbuddy/models/emergency_contact_model.dart';
import 'package:barbuddy/services/emergency_service.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  bool _isAdding = false;
  bool _showAddForm = false;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isPrimary = false;
  bool _enableAutoCheckIn = true;
  bool _enableEmergencyAlerts = true;
  
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  // Load emergency contacts
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _contacts = await _emergencyService.getUserContacts(userProvider.currentUser.id);
      
      // If no contacts exist yet, show the add form by default
      if (_contacts.isEmpty) {
        _showAddForm = true;
        _isPrimary = true; // First contact is primary by default
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading contacts: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Add a new emergency contact
  Future<void> _addContact() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      _isAdding = true;
    });
    
    try {
      final newContact = await _emergencyService.addContact(
        userId: userProvider.currentUser.id,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''),
        isPrimary: _isPrimary,
        enableAutoCheckIn: _enableAutoCheckIn,
        enableEmergencyAlerts: _enableEmergencyAlerts,
      );
      
      // Add contact ID to user
      await userProvider.addEmergencyContact(newContact.id);
      
      // Reset form
      _nameController.clear();
      _phoneController.clear();
      _isPrimary = false;
      _enableAutoCheckIn = true;
      _enableEmergencyAlerts = true;
      
      // Hide form and reload contacts
      setState(() {
        _showAddForm = false;
      });
      
      await _loadContacts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contact added successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }
  
  // Delete an emergency contact
  Future<void> _deleteContact(EmergencyContact contact) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _emergencyService.deleteContact(contact.id);
      await userProvider.removeEmergencyContact(contact.id);
      
      await _loadContacts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contact deleted'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting contact: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  // Set contact as primary
  Future<void> _setPrimaryContact(String contactId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _emergencyService.setPrimaryContact(contactId, userProvider.currentUser.id);
      
      await _loadContacts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary contact updated'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating primary contact: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  // Pick a contact from device contacts
  Future<void> _pickContact() async {
    final status = await Permission.contacts.request();
    
    if (status.isGranted) {
      try {
        final Contact? contact = await ContactsService.openDeviceContactPicker();
        
        if (contact != null && mounted) {
          final phone = contact.phones?.firstOrNull?.value?.trim();
          
          if (phone != null && phone.isNotEmpty) {
            setState(() {
              _nameController.text = contact.displayName ?? '';
              _phoneController.text = phone;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected contact doesn\'t have a phone number'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error picking contact: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact permission denied'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  // Send emergency alert
  Future<void> _sendEmergencyAlert() async {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts added yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Emergency Alert'),
        content: const Text(
          'This will send an emergency alert with your current location to all your emergency contacts. Continue?'
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
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sending emergency alert...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
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
              }
            },
            child: Text(
              'SEND ALERT',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Emergency Contacts',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Emergency alert button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomButton(
                    onPressed: _sendEmergencyAlert,
                    text: 'SEND EMERGENCY ALERT',
                    icon: Icons.emergency,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                
                // Contact list or empty state
                Expanded(
                  child: _contacts.isEmpty && !_showAddForm
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _contacts.length + (_showAddForm ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_showAddForm && index == 0) {
                              return _buildAddContactForm();
                            }
                            
                            final contactIndex = _showAddForm ? index - 1 : index;
                            final contact = _contacts[contactIndex];
                            
                            return _buildContactCard(contact);
                          },
                        ),
                ),
                
                // Add contact button
                if (!_showAddForm)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomButton(
                      onPressed: () {
                        setState(() {
                          _showAddForm = true;
                          
                          // Reset form
                          _nameController.clear();
                          _phoneController.clear();
                          _isPrimary = _contacts.isEmpty;
                          _enableAutoCheckIn = true;
                          _enableEmergencyAlerts = true;
                        });
                      },
                      text: 'ADD CONTACT',
                      icon: Icons.add,
                    ),
                  ),
              ],
            ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contact_phone,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Emergency Contacts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts who can help in case of an emergency',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showAddForm = true;
                _isPrimary = true; // First contact is primary by default
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('ADD YOUR FIRST CONTACT'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddContactForm() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Emergency Contact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Contact name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _pickContact,
                    icon: const Icon(Icons.contacts),
                    tooltip: 'Choose from contacts',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Phone number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\+\-\(\) ]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  
                  // Basic validation: ensure there are at least 10 digits
                  final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                  if (digitsOnly.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Options
              SwitchListTile(
                title: const Text('Mark as primary contact'),
                subtitle: const Text('This contact will be called first in emergencies'),
                value: _isPrimary,
                onChanged: (value) {
                  setState(() {
                    _isPrimary = value;
                  });
                },
              ),
              
              SwitchListTile(
                title: const Text('Enable auto check-in'),
                subtitle: const Text('Send automatic check-in messages to this contact'),
                value: _enableAutoCheckIn,
                onChanged: (value) {
                  setState(() {
                    _enableAutoCheckIn = value;
                  });
                },
              ),
              
              SwitchListTile(
                title: const Text('Enable emergency alerts'),
                subtitle: const Text('Send SOS alerts to this contact'),
                value: _enableEmergencyAlerts,
                onChanged: (value) {
                  setState(() {
                    _enableEmergencyAlerts = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Form actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAddForm = false;
                      });
                    },
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isAdding ? null : _addContact,
                    child: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('SAVE CONTACT'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: contact.isPrimary
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                  foregroundColor: contact.isPrimary ? Colors.white : Colors.black,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (contact.isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'PRIMARY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.formattedPhoneNumber,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Contact options
            Wrap(
              spacing: 8.0,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.call, size: 16),
                  label: const Text('Call'),
                  onPressed: () => _emergencyService.callEmergencyContact(contact),
                ),
                ActionChip(
                  avatar: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Check-in'),
                  onPressed: () async {
                    try {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      
                      await _emergencyService.sendCheckInMessage(
                        userId: userProvider.currentUser.id,
                        userName: userProvider.currentUser.name ?? 'Your friend',
                        onlyPrimary: contact.isPrimary,
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
                  },
                ),
                if (!contact.isPrimary)
                  ActionChip(
                    avatar: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Make Primary'),
                    onPressed: () => _setPrimaryContact(contact.id),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  onPressed: () => _confirmDeleteContact(contact),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDeleteContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete ${contact.name} from your emergency contacts?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContact(contact);
            },
            child: Text(
              'DELETE',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}