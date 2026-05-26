import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  static const String baseUrl =
      "https://amategeko-backend-new.onrender.com/api";

  // Get token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Helper method for authenticated requests
  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "No authentication token found"};
      }

      final requestHeaders = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        ...?headers,
      };

      final uri = Uri.parse("$baseUrl$endpoint");
      late final http.Response response;

      if (method == "GET") {
        response = await http.get(uri, headers: requestHeaders);
      } else if (method == "POST") {
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body),
        );
      }

      print("API $method $endpoint - Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Unauthorized. Please login again.",
        };
      }

      if (response.statusCode >= 400) {
        return {
          "success": false,
          "message": "Server error: ${response.statusCode}",
        };
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("API Error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // Get user's referral information
  static Future<Map<String, dynamic>> getReferralInfo() {
    return _makeRequest("GET", "/referral");
  }

  // Get pending bonuses
  static Future<Map<String, dynamic>> getPendingBonuses() {
    return _makeRequest("GET", "/referral/pending-bonuses");
  }

  // Claim a bonus exam
  static Future<Map<String, dynamic>> claimBonusExam(int bonusIndex) {
    return _makeRequest(
      "POST",
      "/referral/claim-bonus",
      body: {"bonusIndex": bonusIndex},
    );
  }

  // Apply referral code
  static Future<Map<String, dynamic>> applyReferralCode(String referralCode) {
    return _makeRequest(
      "POST",
      "/referral/apply",
      body: {"referralCode": referralCode},
    );
  }

  // Get referral leaderboard
  static Future<Map<String, dynamic>> getLeaderboard() {
    return _makeRequest("GET", "/referral/leaderboard");
  }
}
