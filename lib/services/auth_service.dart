import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String baseUrl =
      "https://amategeko-backend-new.onrender.com/api/auth";

  // Session/Profile storage keys
  static const String _tokenKey = "token";
  static const String _userIdKey = "userId";
  static const String _userProfileKey = "user_profile";
  static const String _isLoggedInKey = "is_logged_in";

  // Google Sign-In initialization
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        "764416304687-qddp4a8rl42fagtk05n7pe48l0gh44iu.apps.googleusercontent.com",
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String username,
    String? phone,
    String? email,
    required String password,
    String? referralCode,
  }) async {
    try {
      // Extract first and last name from username
      final nameParts = username.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final body = {
        "username":
            username.toLowerCase().replaceAll(' ', '') +
            DateTime.now().millisecond.toString().substring(0, 3),
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "password": password,
        "phone": phone,
      };

      // Add referral code if provided
      if (referralCode != null && referralCode.isNotEmpty) {
        body["referralCode"] = referralCode;
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 15));

      print("REGISTER BODY: ${response.body}");

      final data = jsonDecode(response.body);
      if (data.containsKey("token")) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data["token"]);

        // Save userId from response (_id or id field from backend)
        final userId = data["user"]?["_id"] ?? data["_id"] ?? data["id"] ?? "";
        if (userId.isNotEmpty) {
          await prefs.setString(_userIdKey, userId);
        }

        // Store user profile data
        final profileData = {
          "username": data["username"] ?? username,
          "email": email,
          "phone": phone,
          "firstName": firstName,
          "lastName": lastName,
        };
        await prefs.setString(_userProfileKey, jsonEncode(profileData));
        await prefs.setBool(_isLoggedInKey, true);

        data["success"] = true;
      } else {
        data["success"] = false;
        if (!data.containsKey("message")) {
          data["message"] = "Registration failed";
        }
      }
      return data;
    } on TimeoutException {
      print("Registration timeout");
      return {
        "success": false,
        "message":
            "Server took too long to respond. Please check your connection and try again.",
      };
    } on FormatException {
      print("Registration response format error");
      return {
        "success": false,
        "message": "Invalid response from server. Please try again.",
      };
    } catch (e) {
      print("Registration error: $e");
      final errorMsg = e.toString();

      if (errorMsg.contains("Connection refused")) {
        return {
          "success": false,
          "message":
              "Cannot connect to server. Please check your internet connection.",
        };
      } else if (errorMsg.contains("Connection timed out")) {
        return {
          "success": false,
          "message":
              "Connection timeout. Please check your internet and try again.",
        };
      } else if (errorMsg.contains("Network is unreachable")) {
        return {
          "success": false,
          "message":
              "No internet connection detected. Please check your network.",
        };
      } else {
        return {
          "success": false,
          "message": "An error occurred. Please try again later.",
        };
      }
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "phone": phone, // ✅ NOT telephone
              "password": password,
            }),
          )
          .timeout(Duration(seconds: 15));

      print("LOGIN BODY: ${response.body}");

      final data = jsonDecode(response.body);
      print("LOGIN PARSED DATA: $data");

      if (data.containsKey("token")) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data["token"]);

        // Try to extract userId from various possible locations in response
        String? userId;

        // Try user object first
        if (data["user"] != null) {
          userId = data["user"]["_id"] ?? data["user"]["id"];
        }

        // Try direct fields
        userId ??= data["_id"] ?? data["id"] ?? data["userId"];

        print("📍 Extracted userId: $userId");
        print("📍 All keys in response: ${data.keys.toList()}");

        if (userId != null && userId.isNotEmpty) {
          await prefs.setString(_userIdKey, userId);
          print("✅ UserId saved to SharedPreferences: $userId");
        } else {
          print(
            "⚠️ WARN: userId could not be extracted! Response keys: ${data.keys}",
          );
        }

        // Store user profile data
        final profileData = {
          "username": data["username"] ?? "",
          "email": email ?? "",
          "phone": phone ?? "",
          "firstName": data["profile"]?["firstName"] ?? "",
          "lastName": data["profile"]?["lastName"] ?? "",
        };
        await prefs.setString(_userProfileKey, jsonEncode(profileData));
        await prefs.setBool(_isLoggedInKey, true);

        data["success"] = true;
      } else {
        data["success"] = false;
        if (!data.containsKey("message")) {
          data["message"] = "Login failed";
        }
      }

      return data;
    } on TimeoutException {
      print("Login timeout");
      return {
        "success": false,
        "message":
            "Server took too long to respond. Please check your connection and try again.",
      };
    } on FormatException {
      print("Login response format error");
      return {
        "success": false,
        "message": "Invalid response from server. Please try again.",
      };
    } catch (e) {
      print("Login error: $e");
      final errorMsg = e.toString();

      if (errorMsg.contains("Connection refused")) {
        return {
          "success": false,
          "message":
              "Cannot connect to server. Please check your internet connection.",
        };
      } else if (errorMsg.contains("Connection timed out")) {
        return {
          "success": false,
          "message":
              "Connection timeout. Please check your internet and try again.",
        };
      } else if (errorMsg.contains("Network is unreachable")) {
        return {
          "success": false,
          "message":
              "No internet connection detected. Please check your network.",
        };
      } else {
        return {
          "success": false,
          "message": "An error occurred. Please try again later.",
        };
      }
    }
  }

  // GOOGLE SIGN-IN
  static Future<Map<String, dynamic>> googleSignIn() async {
    try {
      // First, sign out from any previous session to clear state
      await _googleSignIn.signOut();

      print("🔐 Starting Google Sign-In...");
      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("🔐 Google sign-in cancelled by user");
        return {"success": false, "message": "Google sign-in cancelled"};
      }

      print("🔐 Google user selected: ${googleUser.email}");

      // Get Google ID token
      print("🔐 Getting authentication...");
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      print("🔐 ID Token received: ${idToken?.substring(0, 20)}...");

      if (idToken == null) {
        print("❌ ID Token is null!");
        await _googleSignIn.signOut();
        return {
          "success": false,
          "message": "Failed to get authentication token. Please try again.",
        };
      }

      // Send token to backend
      final response = await http
          .post(
            Uri.parse("$baseUrl/google-verify"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"token": idToken}),
          )
          .timeout(Duration(seconds: 15));

      print("🔐 GOOGLE SIGN-IN RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (data.containsKey("token") || data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();

        // Save token
        final token = data["token"] ?? data["jwtToken"] ?? "";
        if (token.isNotEmpty) {
          await prefs.setString(_tokenKey, token);
        }

        // Extract userId from various possible locations
        String? userId;
        if (data["user"] != null) {
          userId = data["user"]["_id"] ?? data["user"]["id"];
        }
        userId ??= data["_id"] ?? data["id"] ?? data["userId"];

        if (userId != null && userId.isNotEmpty) {
          await prefs.setString(_userIdKey, userId);
        }

        // Store user profile
        final profileData = {
          "email": googleUser.email,
          "displayName": googleUser.displayName,
          "photoUrl": googleUser.photoUrl,
          "firstName": googleUser.displayName?.split(' ').first ?? "",
          "lastName": (googleUser.displayName?.split(' ').length ?? 0) > 1
              ? googleUser.displayName?.split(' ').sublist(1).join(' ')
              : "",
        };
        await prefs.setString(_userProfileKey, jsonEncode(profileData));
        await prefs.setBool(_isLoggedInKey, true);

        return {
          "success": true,
          "token": token,
          "user": profileData,
          "message": "Google sign-in successful",
        };
      } else {
        // Logout from Google if backend fails
        print("❌ Backend authentication failed: ${data["message"]}");
        await _googleSignIn.signOut();
        return {
          "success": false,
          "message": data["message"] ?? "Google sign-in failed",
        };
      }
    } on TimeoutException {
      print("⏱️ Google sign-in timeout");
      await _googleSignIn.signOut();
      return {
        "success": false,
        "message":
            "Server took too long to respond. Please check your connection and try again.",
      };
    } catch (e) {
      print("❌ Google sign-in error: $e");
      print("❌ Error type: ${e.runtimeType}");
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        print("⚠️ Error during sign out: $signOutError");
      }
      return {
        "success": false,
        "message": "Google sign-in error: ${e.toString()}",
      };
    }
  }

  // Sign out from Google
  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print("Error signing out from Google: $e");
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored userId
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString(_userIdKey);
      print("🔍 [AuthService] getUserId() - Retrieved: '$storedUserId'");
      return storedUserId;
    } catch (e) {
      print("❌ [AuthService] Error getting userId: $e");
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get stored user profile
  static Future<Map<String, dynamic>?> getStoredProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    if (profileJson != null) {
      try {
        return jsonDecode(profileJson);
      } catch (e) {
        print("Error parsing stored profile: $e");
        return null;
      }
    }
    return null;
  }

  // Update stored profile
  static Future<void> updateStoredProfile(
    Map<String, dynamic> profileData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profileData));
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_isLoggedInKey);
  }
}
