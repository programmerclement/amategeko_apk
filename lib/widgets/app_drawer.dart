import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final VoidCallback onDashboard;
  final VoidCallback onExams;
  final VoidCallback onPayments;
  final VoidCallback onProfile;

  const AppDrawer({
    super.key,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.onDashboard,
    required this.onExams,
    required this.onPayments,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    // Build full name
    String fullName = '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      fullName = '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      fullName = firstName;
    } else if (lastName.isNotEmpty) {
      fullName = lastName;
    } else {
      fullName = username;
    }

    print('📱 [AppDrawer] Building drawer with phone: "$phone" (length: ${phone.length})');

    return Drawer(
      child: Column(
        children: [
          // Drawer Header - Well Organized Profile
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rounded Profile Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : "U",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Profile Details
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Full Name
                        if (fullName.isNotEmpty)                      
                          Text(
                            fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                        if (fullName.isNotEmpty) SizedBox(height: 4),

                        // Email
                        if (email.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                Icon(Icons.email, size: 12, color: Colors.white70),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Phone Number - Below Email
                        if (phone.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: Colors.white70),
                              SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  phone,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.dashboard,
                  label: "Dashboard",
                  onTap: () {
                    Navigator.pop(context);
                    onDashboard();
                  },
                ),
                _DrawerItem(
                  icon: Icons.assignment,
                  label: "Exams",
                  onTap: () {
                    Navigator.pop(context);
                    onExams();
                  },
                ),
                _DrawerItem(
                  icon: Icons.payment,
                  label: "Payments",
                  onTap: () {
                    Navigator.pop(context);
                    onPayments();
                  },
                ),
                _DrawerItem(
                  icon: Icons.info_outline,
                  label: "About",
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutModal(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.person,
                  label: "Profile",
                  onTap: () {
                    Navigator.pop(context);
                    onProfile();
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1),
          Padding(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
                icon: Icon(Icons.logout, size: 16),
                label: Text("Logout", style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Icon(
                        Icons.close,
                        size: 28,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // App Icon/Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.school,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // App Name
                Text(
                  'Tsindira Provisoir',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),

                // Version
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Version 1.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Description
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Traffic rule simulation exam based in Rwanda (RW). Helps people to test and improve their skills about the temporary or provisional RNP (Rwandan National Police) driving examination.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),

                // Developer Info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 18, color: Colors.blue.shade600),
                          SizedBox(width: 8),
                          Text(
                            'Developer',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Designed by Programmer Clement',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // License Info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.article, size: 18, color: Colors.purple.shade600),
                          SizedBox(width: 8),
                          Text(
                            'License',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.purple.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        'All rights reserved © 2026 Tsindira Provisoir',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade600),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      hoverColor: Colors.grey.shade100,
    );
  }
}
