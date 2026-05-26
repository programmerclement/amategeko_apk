import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;

  void handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final input = loginController.text.trim();

    try {
      final response = await AuthService.login(
        email: input.contains("@") ? input : null,
        phone: input.contains("@") ? null : input,
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      if (response["success"] == true && response.containsKey("token")) {
        AppSnackbar.success(context, "Login successful! Redirecting...");
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        AppSnackbar.error(
          context,
          response["message"] ?? "Login failed. Please check your credentials.",
        );
      }
    } catch (e) {
      AppSnackbar.error(context, "Network error. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void handleGoogleSignIn() async {
    setState(() => isLoading = true);

    try {
      final response = await AuthService.googleSignIn();

      if (!mounted) return;

      if (response["success"] == true) {
        AppSnackbar.success(
          context,
          "Google sign-in successful! Redirecting...",
        );
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        AppSnackbar.error(
          context,
          response["message"] ?? "Google sign-in failed. Please try again.",
        );
      }
    } catch (e) {
      AppSnackbar.error(context, "Google sign-in error. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration inputStyle(String hint, {bool isPassword = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: () => setState(() => showPassword = !showPassword),
            )
          : null,
    );
  }

  void _showForgotPasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Icon
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade50,
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          size: 36,
                          color: Colors.blue.shade600,
                        ),
                      ),

                      SizedBox(height: 20),

                      // Title
                      Text(
                        "Reset Your Password",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 12),

                      // Description
                      Text(
                        "To reset your password, you have two options:",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 24),

                      // Option 1: Contact Administrator
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 20,
                                  color: Colors.blue.shade600,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Contact Administrator",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Reach out to our support team via WhatsApp or Email to help you reset your password.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 14),
                            // WhatsApp Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openWhatsApp(),
                                icon: Icon(Icons.chat, size: 18),
                                label: Text("WhatsApp: 0780100211"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            // Email Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openEmail(),
                                icon: Icon(Icons.email_outlined, size: 18),
                                label: Text("Email: kncshools@gmail.com"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade600,
                                  side: BorderSide(
                                    color: Colors.blue.shade300,
                                    width: 1.5,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 18),

                      // Option 2: Google Sign In
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  size: 20,
                                  color: Colors.orange.shade600,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Use Google Sign-In",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Sign in with your Google account to access your account without needing to reset your password.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    handleGoogleSignIn();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Google Logo Icon
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF4285F4), // Blue
                                                Color(0xFF34A853), // Green
                                              ],
                                            ),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Background circle
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.95),
                                                ),
                                                margin: EdgeInsets.all(4),
                                              ),
                                              // G Letter
                                              Text(
                                                'G',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF1F2937),
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            "Sign In with Google",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1F2937),
                                              letterSpacing: 0.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        SizedBox(
                                          width: 28,
                                        ), // Spacer to balance the icon
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Support Info Box
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "📞 Support Information",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "kncshools@gmail.com",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "+250 780 100 211",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Got it, Close",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openWhatsApp() async {
    final phone = "250780100211"; // WhatsApp format without +
    final message =
        "Mwaramutse! Nkeneye guhindura ijambo ry'ibinga ryanjye. Mwamfasha?";

    try {
      // Try WhatsApp web URL first (more reliable)
      final whatsappWebUrl =
          "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

      if (await canLaunchUrl(Uri.parse(whatsappWebUrl))) {
        await launchUrl(
          Uri.parse(whatsappWebUrl),
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // Fallback: Try opening WhatsApp app directly
      final whatsappAppUrl =
          "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}";
      if (await canLaunchUrl(Uri.parse(whatsappAppUrl))) {
        await launchUrl(
          Uri.parse(whatsappAppUrl),
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // If WhatsApp not available, show fallback options
      _showWhatsAppNotAvailable(phone);
    } catch (e) {
      print("❌ Error opening WhatsApp: $e");
      _showWhatsAppNotAvailable(phone);
    }
  }

  Future<void> _openEmail() async {
    final email = "kncshools@gmail.com";
    final subject = "Reset Password Request";
    final body =
        "Mwaramutse,\n\nNkeneye guhindura ijambo ry'ibinga ryanjye. Mwamfasha?\n\nUrakoze.";

    final mailtoUrl =
        "mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}";

    try {
      final Uri mailUri = Uri.parse(mailtoUrl);
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri, mode: LaunchMode.externalApplication);
      } else {
        // Email client not available, offer copy option
        _showEmailNotAvailable(email);
      }
    } catch (e) {
      print("❌ Error opening email: $e");
      _showEmailNotAvailable(email);
    }
  }

  void _showWhatsAppNotAvailable(String phone) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(Icons.info, color: Colors.orange),
        title: Text("WhatsApp Not Available"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "WhatsApp is not installed on your device. You can:",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              "📱 Phone: 0780 100 211",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              "💬 WhatsApp: +250 780 100 211",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              "📧 Email: kncshools@gmail.com",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showEmailNotAvailable(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(Icons.info, color: Colors.orange),
        title: Text("Email Client Not Available"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "No email client found. Contact support at:",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              "📧 Email: $email",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              "📱 WhatsApp: +250 780 100 211",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LOGO - Will shrink with keyboard
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Hero(
                            tag: 'login_logo',
                            child: Image.asset(
                              "assets/logo.png",
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      // TITLE
                      Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        "Login to your account",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(height: 32),

                      // EMAIL/PHONE FIELD
                      Text(
                        "Email or Phone",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: loginController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: inputStyle("Enter your email or phone"),
                        validator: (v) =>
                            v!.isEmpty ? "Enter email or phone" : null,
                      ),

                      SizedBox(height: 20),

                      // PASSWORD FIELD
                      Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !showPassword,
                        decoration: inputStyle(
                          "Enter your password",
                          isPassword: true,
                        ),
                        validator: (v) => v!.isEmpty ? "Enter password" : null,
                      ),

                      SizedBox(height: 12),

                      // FORGOT PASSWORD
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 28),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
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
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // DIVIDER
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // GOOGLE SIGN-IN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading ? null : handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google Logo Icon
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF4285F4), // Blue
                                          Color(0xFF34A853), // Green
                                        ],
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Background circle
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                          ),
                                          margin: EdgeInsets.all(4),
                                        ),
                                        // G Letter
                                        Text(
                                          'G',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF1F2937),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      "Sign in with Google",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2937),
                                        letterSpacing: 0.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  SizedBox(
                                    width: 28,
                                  ), // Spacer to balance the icon
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // SIGN UP LINK
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  child: Text(
                                    "Create one",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
