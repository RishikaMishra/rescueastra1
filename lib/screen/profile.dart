import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening email & phone links
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Login.dart';

// void main() {
//   runApp(const RescueAstraApp());
// }

class RescueAstraApp extends StatelessWidget {
  const RescueAstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    setState(() {
      currentUser = FirebaseAuth.instance.currentUser;
      isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'logout':
        _showLogoutDialog();
        break;
      case 'settings':
        // TODO: Navigate to settings page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon!')),
        );
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text(
          "RescueAstra Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ProfileSection(user: currentUser),
    );
  }
}

class ProfileSection extends StatefulWidget {
  final User? user;

  const ProfileSection({super.key, this.user});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  Map<String, dynamic> userProfile = {};
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (widget.user != null) {
      try {
        // Try to get additional user data from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user!.uid)
            .get();

        if (doc.exists) {
          setState(() {
            userProfile = doc.data() ?? {};
            isLoadingProfile = false;
          });
        } else {
          // Create default profile data if not exists
          setState(() {
            userProfile = {
              'phone': '',
              'address': '',
              'emergencyContacts': [],
              'joinedDate': DateTime.now().toIso8601String(),
            };
            isLoadingProfile = false;
          });
        }
      } catch (e) {
        setState(() {
          userProfile = {};
          isLoadingProfile = false;
        });
      }
    } else {
      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  void _launchEmail() async {
    if (widget.user?.email != null) {
      final Uri emailUri = Uri(scheme: 'mailto', path: widget.user!.email!);
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    }
  }

  void _launchPhone() async {
    final phone = userProfile['phone'] ?? '';
    if (phone.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    }
  }

  String _getDisplayName() {
    if (widget.user?.displayName != null && widget.user!.displayName!.isNotEmpty) {
      return widget.user!.displayName!;
    }
    return widget.user?.email?.split('@')[0] ?? 'User';
  }

  String _getInitials() {
    final name = _getDisplayName();
    if (name.contains(' ')) {
      final parts = name.split(' ');
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No user logged in', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Header Card
          _buildProfileHeader(),
          const SizedBox(height: 20),

          // Account Information Card
          _buildAccountInfoCard(),
          const SizedBox(height: 20),

          // App Statistics Card
          _buildAppStatsCard(),
          const SizedBox(height: 20),

          // Quick Actions Card
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFA82B66), const Color(0xFF8E1B5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA82B66).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: widget.user?.photoURL != null
                  ? NetworkImage(widget.user!.photoURL!)
                  : null,
                child: widget.user?.photoURL == null
                  ? Text(
                      _getInitials(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA82B66),
                      ),
                    )
                  : null,
              ),
            ),
            const SizedBox(height: 16),

            // User Name
            Text(
              _getDisplayName(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // User Email
            Text(
              widget.user?.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),

            // Verification Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.user?.emailVerified == true
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.user?.emailVerified == true
                    ? Colors.green
                    : Colors.orange,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.user?.emailVerified == true
                      ? Icons.verified
                      : Icons.warning,
                    size: 16,
                    color: widget.user?.emailVerified == true
                      ? Colors.green
                      : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.user?.emailVerified == true
                      ? 'Verified Account'
                      : 'Unverified Account',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.user?.emailVerified == true
                        ? Colors.green
                        : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: widget.user?.email ?? 'Not provided',
              onTap: _launchEmail,
              isClickable: widget.user?.email != null,
            ),
            const Divider(height: 24),

            // Phone
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: userProfile['phone']?.isEmpty ?? true
                ? 'Not provided'
                : userProfile['phone'],
              onTap: _launchPhone,
              isClickable: userProfile['phone']?.isNotEmpty ?? false,
            ),
            const Divider(height: 24),

            // User ID
            _buildInfoRow(
              icon: Icons.fingerprint,
              label: 'User ID',
              value: widget.user?.uid.substring(0, 8) ?? 'Unknown',
              isClickable: false,
            ),
            const Divider(height: 24),

            // Account Created
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Member Since',
              value: widget.user?.metadata.creationTime != null
                ? '${widget.user!.metadata.creationTime!.day}/${widget.user!.metadata.creationTime!.month}/${widget.user!.metadata.creationTime!.year}'
                : 'Unknown',
              isClickable: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isClickable ? Colors.blue : Colors.black87,
                    decoration: isClickable ? TextDecoration.underline : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isClickable)
            Icon(Icons.open_in_new, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }



  Widget _buildAppStatsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'App Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.login,
                    title: 'Last Login',
                    value: widget.user?.metadata.lastSignInTime != null
                      ? '${widget.user!.metadata.lastSignInTime!.day}/${widget.user!.metadata.lastSignInTime!.month}'
                      : 'Unknown',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.shield,
                    title: 'Safety Score',
                    value: '95%',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.emergency,
                    title: 'SOS Used',
                    value: '0 times',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.verified_user,
                    title: 'Account Status',
                    value: widget.user?.emailVerified == true ? 'Verified' : 'Pending',
                    color: widget.user?.emailVerified == true ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action buttons
            Column(
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your information',
                  onTap: () => _showEditProfileDialog(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.security,
                  title: 'Privacy Settings',
                  subtitle: 'Manage your privacy',
                  onTap: () => _showPrivacySettings(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and support',
                  onTap: () => _showHelpSupport(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.share,
                  title: 'Share App',
                  subtitle: 'Share RescueAstra with friends',
                  onTap: () => _shareApp(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.deepPurple, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  // Quick Action Methods
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController(text: _getDisplayName());
        final phoneController = TextEditingController(text: userProfile['phone'] ?? '');

        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update display name in Firebase Auth
                  if (nameController.text.isNotEmpty) {
                    await widget.user?.updateDisplayName(nameController.text);
                  }

                  // Update phone in Firestore
                  if (widget.user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.user!.uid)
                        .set({
                      'phone': phoneController.text,
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                  }

                  // Refresh the profile
                  _loadUserProfile();

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Profile Visibility'),
                subtitle: const Text('Control who can see your profile'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // Handle privacy setting change
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location Sharing'),
                subtitle: const Text('Share location with emergency contacts'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // Handle location sharing setting
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Emergency Notifications'),
                subtitle: const Text('Receive emergency alerts'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // Handle notification setting
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('FAQ'),
                  subtitle: const Text('Frequently asked questions'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('FAQ section coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contact_support),
                  title: const Text('Contact Support'),
                  subtitle: const Text('Get help from our team'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'support@rescueastra.com',
                      query: 'subject=Support Request&body=Hello RescueAstra Support Team,',
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Report Bug'),
                  subtitle: const Text('Report issues or bugs'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'bugs@rescueastra.com',
                      query: 'subject=Bug Report&body=Please describe the bug:',
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('App Version'),
                  subtitle: const Text('RescueAstra v1.0.0'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _shareApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share RescueAstra'),
          content: const Text(
            'Help spread safety awareness by sharing RescueAstra with your friends and family!\n\n'
            'RescueAstra - Your personal safety companion with SOS alerts, live tracking, and emergency assistance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // In a real app, you would use share_plus package
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share link copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }
}