import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      "https://amategeko-backend-new.onrender.com/api/auth";

  // Session/Profile storage keys
  static const String _tokenKey = "token";
  static const String _userIdKey = "userId";
  static const String _userProfileKey = "user_profile";
  static const String _isLoggedInKey = "is_logged_in";

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String username,
    String? phone,
    String? email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": username,
              "email": email,
              "password": password,
              "profile": {"phone": phone},
            }),
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
          "username": username,
          "email": email,
          "phone": phone,
          "firstName": data["profile"]?["firstName"] ?? "",
          "lastName": data["profile"]?["lastName"] ?? "",
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
    } catch (e) {
      return {"success": false, "message": "Network error"};
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
      print("🔐 LOGIN PARSED DATA: $data");
      
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
          print("⚠️ WARN: userId could not be extracted! Response keys: ${data.keys}");
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
    } catch (e) {
      return {"success": false, "message": "Network error"};
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
  static Future<void> updateStoredProfile(Map<String, dynamic> profileData) async {
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
