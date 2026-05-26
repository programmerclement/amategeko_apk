import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final referralCodeController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool showReferralInput = false;
  bool showReferralInfo = false;
  Map<String, String> validationErrors = {};

  void _validateForm() {
    validationErrors.clear();

    if (nameController.text.trim().isEmpty) {
      validationErrors['name'] = 'Full name is required';
    }

    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (phone.isEmpty && email.isEmpty) {
      validationErrors['contact'] = 'Either phone or email is required';
    }

    if (email.isNotEmpty && !email.contains('@')) {
      validationErrors['email'] = 'Enter a valid email address';
    }

    if (phone.isNotEmpty && phone.length != 10) {
      validationErrors['phone'] = 'Phone must be 10 digits';
    }

    if (passwordController.text.length < 6) {
      validationErrors['password'] = 'Password must be at least 6 characters';
    }

    setState(() {});
  }

  void handleSignup() async {
    _validateForm();

    if (validationErrors.isNotEmpty) {
      AppSnackbar.error(context, 'Please fix the errors below');
      return;
    }

    setState(() => isLoading = true);

    try {
      final phone = phoneController.text.trim();
      final email = emailController.text.trim();
      final referralCode = referralCodeController.text.trim();

      final response = await AuthService.register(
        username: nameController.text.trim(),
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
        password: passwordController.text.trim(),
        referralCode: referralCode.isEmpty ? null : referralCode.toUpperCase(),
      );

      if (!mounted) return;

      if (response["success"] == true) {
        AppSnackbar.success(
          context,
          "🎉 Welcome! You have 1 free exam attempt!",
        );
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        String errorMsg = response["message"] ?? "Registration failed";
        AppSnackbar.error(context, errorMsg);
        print("❌ Registration error: $errorMsg");
      }
    } catch (e) {
      print("❌ Signup exception: $e");
      if (mounted) {
        String errorMsg = "An unexpected error occurred. Please try again.";

        if (e.toString().contains("TimeoutException")) {
          errorMsg =
              "⏱️ Server took too long to respond. Please check your connection and try again.";
        } else if (e.toString().contains("Connection")) {
          errorMsg =
              "Cannot connect to server. Please check your internet connection.";
        }

        AppSnackbar.error(context, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    referralCodeController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword ? !showPassword : false,
            inputFormatters: keyboardType == TextInputType.phone
                ? [FilteringTextInputFormatter.digitsOnly]
                : [],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(icon, color: Colors.green.shade600, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => showPassword = !showPassword),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red.shade300
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red.shade300
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorStyle: TextStyle(fontSize: 0, height: 0),
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 6),
          Text(
            errorText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey.shade50,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.grey.shade700,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Login',
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 8),

                // Logo/Header Section
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 40,
                    color: Colors.green.shade600,
                  ),
                ),

                SizedBox(height: 24),

                // Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),

                SizedBox(height: 8),

                // Subtitle
                Text(
                  'Join thousands of learners',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 32),

                // Form Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full Name
                        _buildInputField(
                          label: 'Full Name',
                          hint: 'e.g., Clement Niyongira',
                          controller: nameController,
                          icon: Icons.person_outline,
                          errorText: validationErrors['name'],
                        ),

                        SizedBox(height: 20),

                        // Phone
                        _buildInputField(
                          label: 'Phone Number',
                          hint: '0781234567',
                          controller: phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          errorText: validationErrors['phone'],
                        ),

                        SizedBox(height: 20),

                        // Email (Optional)
                        _buildInputField(
                          label: 'Email (Optional)',
                          hint: 'your@email.com',
                          controller: emailController,
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          errorText: validationErrors['email'],
                        ),

                        SizedBox(height: 20),

                        // Password
                        _buildInputField(
                          label: 'Password',
                          hint: 'Minimum 6 characters',
                          controller: passwordController,
                          icon: Icons.lock_outline,
                          isPassword: true,
                          errorText: validationErrors['password'],
                        ),

                        // Contact validation error
                        if (validationErrors.containsKey('contact')) ...[
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              validationErrors['contact']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 24),

                        // Referral Code Section
                        if (!showReferralInput)
                          GestureDetector(
                            onTap: () =>
                                setState(() => showReferralInput = true),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Have a referral code?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),

                        if (showReferralInput) ...[
                          _buildInputField(
                            label: 'Referral Code',
                            hint: 'e.g., ABC123XYZ',
                            controller: referralCodeController,
                            icon: Icons.card_giftcard_outlined,
                          ),
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => setState(
                              () => showReferralInfo = !showReferralInfo,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue.shade600,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'How referrals work?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (showReferralInfo) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '💡 How Referrals Work:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ...[
                                    'Share your referral code with friends',
                                    'They enter your code when signing up',
                                    'Both you and your friend earn rewards!',
                                    'Earn points, discounts & free exams',
                                  ].map(
                                    (text) => Padding(
                                      padding: EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '• ',
                                            style: TextStyle(
                                              color: Colors.blue.shade600,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade800,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 20),
                        ],

                        // Sign Up Button
                        ElevatedButton(
                          onPressed: isLoading ? null : handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32),

                // Features List
                Column(
                  children: [
                    Text(
                      'Why join us?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...[
                      ('✓ Instant account creation', Icons.check_circle),
                      ('✓ Practice exams included', Icons.school),
                      ('✓ Secure payments & rewards', Icons.security),
                    ].map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              item.$2,
                              size: 18,
                              color: Colors.green.shade600,
                            ),
                            SizedBox(width: 10),
                            Text(
                              item.$1,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
