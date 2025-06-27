import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/sos_emergency_service.dart';

class EmergencySettingsPage extends StatefulWidget {
  const EmergencySettingsPage({super.key});

  @override
  State<EmergencySettingsPage> createState() => _EmergencySettingsPageState();
}

class _EmergencySettingsPageState extends State<EmergencySettingsPage> {
  final SOSEmergencyService _sosService = SOSEmergencyService();
  final TextEditingController _emergencyNumberController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  List<String> _emergencyContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emergencyNumberController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await _sosService.initialize();
    setState(() {
      _emergencyContacts = List.from(_sosService.emergencyContacts);
      _emergencyNumberController.text = _sosService.emergencyNumber;
      _isLoading = false;
    });
  }

  Future<void> _saveEmergencyNumber() async {
    final number = _emergencyNumberController.text.trim();
    if (number.isNotEmpty) {
      await _sosService.saveEmergencyNumber(number);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency number updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _addEmergencyContact() async {
    final contact = _contactController.text.trim();
    if (contact.isNotEmpty && !_emergencyContacts.contains(contact)) {
      setState(() {
        _emergencyContacts.add(contact);
      });
      await _sosService.saveEmergencyContacts(_emergencyContacts);
      _contactController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency contact added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (_emergencyContacts.contains(contact)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact already exists'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _removeEmergencyContact(int index) async {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    await _sosService.saveEmergencyContacts(_emergencyContacts);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency contact removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _contactController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1234567890',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Include country code (e.g., +91 for India)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _contactController.clear();
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addEmergencyContact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _testPermissions() async {
    final permissionResults = await _sosService.requestPermissions();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: Text('Permission Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: permissionResults.entries.map((entry) {
            final permission = entry.key.toString().split('.').last;
            final isGranted = entry.value == PermissionStatus.granted;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isGranted ? Icons.check_circle : Icons.error,
                    color: isGranted ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      permission,
                      style: TextStyle(
                        color: isGranted ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Emergency Settings'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.security),
            onPressed: _testPermissions,
            tooltip: 'Test Permissions',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Emergency Number Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Service Number',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _emergencyNumberController,
                    decoration: InputDecoration(
                      labelText: 'Emergency Number',
                      hintText: '112, 911, etc.',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.save),
                        onPressed: _saveEmergencyNumber,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This number will be called automatically during SOS activation',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Emergency Contacts Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddContactDialog,
                        icon: Icon(Icons.add),
                        label: Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'These contacts will receive SMS alerts during emergencies',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),

                  if (_emergencyContacts.isEmpty)
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.contacts, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No emergency contacts added',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(_emergencyContacts.length, (index) {
                      final contact = _emergencyContacts[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(contact),
                          subtitle: Text('Emergency Contact ${index + 1}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeEmergencyContact(index),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Information Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How SOS Works',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.location_on,
                    'Location Sharing',
                    'Your GPS location is automatically shared with emergency contacts',
                  ),
                  _buildInfoItem(
                    Icons.sms,
                    'SMS Alerts',
                    'Emergency SMS with your location is sent to all contacts',
                  ),
                  _buildInfoItem(
                    Icons.call,
                    'Emergency Call',
                    'Automatic call to emergency services',
                  ),
                  _buildInfoItem(
                    Icons.mic,
                    'Audio Recording',
                    '30-second audio recording for evidence',
                  ),
                  _buildInfoItem(
                    Icons.cloud_upload,
                    'Cloud Backup',
                    'Recordings are uploaded to secure cloud storage',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
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
