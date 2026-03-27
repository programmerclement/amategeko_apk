import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final VoidCallback onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController usernameController;
  late TextEditingController locationController;
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  bool isLoadingProfile = false;
  bool isLoadingPassword = false;
  String? userId; // Track userId for profile operations
  String successMessage = '';
  String errorMessage = '';
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;
  
  // View/Edit mode toggle
  bool isEditMode = false;
  bool isLoadingFullProfile = false;

  @override
  void initState() {
    super.initState();
    print('👤 [ProfileScreen] Init state - loading user data');
    _loadUserData();
    _loadFullProfile();
    
    firstNameController = TextEditingController(text: widget.firstName);
    lastNameController = TextEditingController(text: widget.lastName);
    phoneController = TextEditingController(text: widget.phone);
    emailController = TextEditingController(text: widget.email);
    usernameController = TextEditingController(text: widget.username);
    locationController = TextEditingController();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void activate() {
    print('👋 [ProfileScreen] Tab activated - reloading user data');
    super.activate();
    _loadUserData();
    _loadFullProfile();
  }

  void _refreshProfile() {
    print('🔄 [ProfileScreen] Manual refresh triggered');
    _loadUserData();
    _loadFullProfile();
  }

  Future<void> _loadUserData() async {
    try {
      print('🔄 [ProfileScreen] Loading user ID...');
      final loadedUserId = await AuthService.getUserId();
      
      if (mounted) {
        setState(() {
          userId = loadedUserId;
        });
      }
      
      print('👤 [ProfileScreen] User ID loaded: $userId');
      if (userId != null && userId!.isNotEmpty) {
        print('✅ [ProfileScreen] User ID confirmed: $userId');
      } else {
        print('⚠️ [ProfileScreen] No user ID found');
      }
    } catch (e) {
      print('❌ [ProfileScreen] Error loading user ID: $e');
    }
  }

  Future<void> _loadFullProfile() async {
    setState(() => isLoadingFullProfile = true);
    try {
      print('🔄 [ProfileScreen] Loading full profile from API...');
      final response = await ApiService.fetchUserProfile();
      print('📥 [ProfileScreen] Profile response: $response');

      if (mounted) {
        // Check if response has user data (success field or direct user object)
        bool hasError = response['success'] == false || response.containsKey('message');
        
        if (!hasError && response['username'] != null) {
          // Response is the user object directly
          final userData = response;
          
          // Extract profile data
          final profile = userData['profile'] ?? {};
          final firstName = profile['firstName'] ?? userData['firstName'] ?? '';
          final lastName = profile['lastName'] ?? userData['lastName'] ?? '';
          final phone = profile['phone'] ?? userData['phone'] ?? '';
          final email = userData['email'] ?? '';
          final username = userData['username'] ?? '';
          final location = profile['location'] ?? userData['location'] ?? '';

          setState(() {
            firstNameController.text = firstName;
            lastNameController.text = lastName;
            phoneController.text = phone;
            emailController.text = email;
            usernameController.text = username;
            locationController.text = location;
            isLoadingFullProfile = false;
          });

          print('✅ [ProfileScreen] Profile data loaded successfully');
          print('   - Username: $username');
          print('   - Name: $firstName $lastName');
          print('   - Email: $email');
          print('   - Phone: $phone');
          print('   - Location: $location');
        } else {
          setState(() => isLoadingFullProfile = false);
          print('⚠️ [ProfileScreen] Failed to load profile: ${response['message'] ?? 'Unknown error'}');
        }
      }
    } catch (e) {
      setState(() => isLoadingFullProfile = false);
      print('❌ [ProfileScreen] Error loading profile: $e');
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    usernameController.dispose();
    locationController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() {
      isLoadingProfile = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      final updateData = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'location': locationController.text.trim(),
      };

      print('DEBUG: Sending profile update data: $updateData');
      final response = await ApiService.updateUserProfile(updateData);
      print('DEBUG: Profile update response: $response');

      if (mounted) {
        setState(() {
          isLoadingProfile = false;
        });
        
        if (response['success'] == true) {
          AppSnackbar.success(context, '✅ Profile updated successfully!');
          
          // Reload profile data and return to view mode
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              _loadFullProfile();
              setState(() => isEditMode = false);
            }
          });
          
          widget.onProfileUpdated();
        } else {
          String errMsg = response['message'] ?? 'Failed to update profile';
          AppSnackbar.error(context, errMsg);
        }
      }
    } catch (e) {
      print('DEBUG: Profile update error: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Error: ${e.toString()}');
        setState(() {
          isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    // Validation
    if (currentPasswordController.text.isEmpty) {
      AppSnackbar.error(context, '❌ Current password is required!');
      return;
    }

    if (newPasswordController.text.isEmpty) {
      AppSnackbar.error(context, '❌ New password is required!');
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      AppSnackbar.error(context, '❌ New passwords do not match!');
      return;
    }

    if (newPasswordController.text.length < 6) {
      AppSnackbar.error(context, '❌ Password must be at least 6 characters long');
      return;
    }

    setState(() {
      isLoadingPassword = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      print('DEBUG: Changing password...');
      // Call dedicated password change endpoint
      final response = await ApiService.changeUserPassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );
      print('DEBUG: Password change response: $response');

      if (mounted) {
        setState(() {
          isLoadingPassword = false;
        });
        
        if (response['success'] == true) {
          AppSnackbar.success(context, '✅ Password changed successfully! Logging out...');
          currentPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
          
          // Logout after password change success
          Future.delayed(Duration(seconds: 2), () async {
            if (mounted) {
              print('🔐 [ProfileScreen] Logging out after password change');
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            }
          });
        } else {
          String errMsg = response['message'] ?? 'Failed to change password';
          // Check if it's an auth error and provide user-friendly message
          if (errMsg.toLowerCase().contains('unauthorized') || 
              errMsg.toLowerCase().contains('invalid credentials') ||
              response.toString().contains('401')) {
            errMsg = '❌ Incorrect current password';
          }
          AppSnackbar.error(context, errMsg);
        }
      }
    } catch (e) {
      print('DEBUG: Password change error: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Error: ${e.toString()}');
        setState(() {
          isLoadingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${firstNameController.text} ${lastNameController.text}'.trim();
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _refreshProfile();
          // Wait a bit for the data to load
          await Future.delayed(Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Display Mode Card (View Only)
                if (!isEditMode) ...[
                  _buildProfileViewCard(fullName),
                  SizedBox(height: 24),
                ],

                // Edit Profile Card (Hidden in view mode)
                if (isEditMode)
                  _buildEditProfileCard(),
                
                if (isEditMode)
                  SizedBox(height: 24),

                // Change Password Card
                _buildChangePasswordCard(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileViewCard(String fullName) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                  letterSpacing: 0.3,
                ),
              ),
              Spacer(),
              // Refresh Button
              IconButton(
                onPressed: _refreshProfile,
                icon: Icon(Icons.refresh_outlined, size: 20),
                tooltip: 'Refresh Profile',
              ),
              SizedBox(width: 4),
              // Edit Button
              TextButton.icon(
                onPressed: () => setState(() => isEditMode = true),
                icon: Icon(Icons.edit_outlined, size: 18),
                label: Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Username Display (Read-only)
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Username',
            value: usernameController.text.isEmpty ? '—' : usernameController.text,
          ),
          SizedBox(height: 16),
          
          // Full Name Display
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: fullName.isEmpty ? '—' : fullName,
          ),
          SizedBox(height: 16),
          
          // Email Display
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: emailController.text.isEmpty ? '—' : emailController.text,
          ),
          SizedBox(height: 16),
          
          // Phone Display
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: phoneController.text.isEmpty ? '—' : phoneController.text,
          ),
          SizedBox(height: 16),
          
          // Location Display
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: locationController.text.isEmpty ? '—' : locationController.text,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green.shade600, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                  letterSpacing: 0.3,
                ),
              ),
              Spacer(),
              // Cancel Button
              TextButton(
                onPressed: isLoadingProfile ? null : () {
                  // Reset controllers to current values
                  _loadFullProfile();
                  setState(() => isEditMode = false);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: usernameController,
            label: 'Username',
            icon: Icons.badge_outlined,
            hint: 'Your username',
            enabled: false,
          ),
          SizedBox(height: 14),
          _buildTextField(
            controller: firstNameController,
            label: 'First Name',
            icon: Icons.person_outline,
            hint: 'Enter your first name',
          ),
          SizedBox(height: 14),
          _buildTextField(
            controller: lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline,
            hint: 'Enter your last name',
          ),
          SizedBox(height: 14),
          _buildTextField(
            controller: emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            hint: 'Your email',
            enabled: true,
          ),
          SizedBox(height: 14),
          _buildTextField(
            controller: phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            hint: 'Enter your phone number',
            enabled: false,
          ),
          SizedBox(height: 14),
          _buildTextField(
            controller: locationController,
            label: 'Location',
            icon: Icons.location_on_outlined,
            hint: 'Enter your location',
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoadingProfile ? null : _updateProfile,
              icon: isLoadingProfile
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.check_outlined),
              label: Text(
                isLoadingProfile ? 'Saving Changes...' : 'Save Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Keep your account secure by updating your password regularly',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 18),
          _buildPasswordField(
            controller: currentPasswordController,
            label: 'Current Password',
            hint: 'Enter your current password',
            isVisible: showCurrentPassword,
            onToggle: () => setState(() => showCurrentPassword = !showCurrentPassword),
          ),
          SizedBox(height: 14),
          _buildPasswordField(
            controller: newPasswordController,
            label: 'New Password',
            hint: 'Enter your new password',
            isVisible: showNewPassword,
            onToggle: () => setState(() => showNewPassword = !showNewPassword),
          ),
          SizedBox(height: 14),
          _buildPasswordField(
            controller: confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your new password',
            isVisible: showConfirmPassword,
            onToggle: () => setState(() => showConfirmPassword = !showConfirmPassword),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoadingPassword ? null : _changePassword,
              icon: isLoadingPassword
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.vpn_key_outlined),
              label: Text(
                isLoadingPassword ? 'Updating Password...' : 'Update Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: enabled ? Color(0xFF1E293B) : Colors.grey.shade500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.green.shade600 : Colors.grey.shade400,
          ),
          filled: true,
          fillColor: enabled ? Color(0xFFF8FAFC) : Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green.shade600, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(
            Icons.lock_outlined,
            size: 20,
            color: Colors.grey.shade600,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
      ),
    );
  }
}
  

