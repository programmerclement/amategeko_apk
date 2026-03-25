import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'dashboard_tab.dart';
import 'exams_tab.dart';
import 'payments_tab.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  String username = "User";
  String email = "user@example.com";
  String firstName = "";
  String lastName = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Fetch user profile from real API
      final response = await ApiService.fetchUserProfile();

      if (mounted) {
        setState(() {
          // Backend returns data directly with username/email fields
          if (response.containsKey('username')) {
            username = response['username'] ?? 'User';
            email = response['email'] ?? 'user@example.com';

            // Extract profile details
            final profile = response['profile'] ?? {};
            firstName = profile['firstName'] ?? '';
            lastName = profile['lastName'] ?? '';
            phone = profile['phone'] ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(),
      ExamsTab(),
      PaymentsTab(),
      ProfileScreen(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        onProfileUpdated: _loadUserInfo,
      )
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green.shade600,
        title: Text(
          _currentTab == 0
              ? "Dashboard"
              : _currentTab == 1
              ? "Exams"
              : _currentTab == 2
              ? "Payments"
              : "Profile",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      drawer: AppDrawer(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        onDashboard: () => setState(() => _currentTab = 0),
        onExams: () => setState(() => _currentTab = 1),
        onPayments: () => setState(() => _currentTab = 2),
        onProfile: () => setState(() => _currentTab = 3),
      ),
      body: SafeArea(
        child: IndexedStack(index: _currentTab, children: tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade600,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Exams'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
