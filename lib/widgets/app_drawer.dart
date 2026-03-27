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
