import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ BACKEND URL CONFIGURED
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
      } else if (method == "PUT") {
        response = await http.put(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body),
        );
      } else if (method == "DELETE") {
        response = await http.delete(uri, headers: requestHeaders);
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

  // ========== USER PROFILE ==========
  static Future<Map<String, dynamic>> fetchUserProfile() {
    return _makeRequest("GET", "/users/profile");
  }

  // ========== EXAMS ==========
  static Future<Map<String, dynamic>> fetchExamHistory() {
    return _makeRequest("GET", "/exam/history");
  }

  static Future<Map<String, dynamic>> checkExamEligibility() {
    return _makeRequest("GET", "/exam/check-eligibility");
  }

  static Future<Map<String, dynamic>> startExam(String examId) {
    return _makeRequest("POST", "/exam/start", body: {"examId": examId});
  }

  // ========== PAYMENTS ==========
  static Future<Map<String, dynamic>> fetchUserPayments(String userId) {
    return _makeRequest("GET", "/payments/user/$userId");
  }

  static Future<Map<String, dynamic>> fetchPricingPlans() {
    return _makeRequest("GET", "/pricing/plans");
  }

  static Future<Map<String, dynamic>> initiatePayment({
    required String amount,
    required String phone,
    required String network,
    required String planId,
    required String userId,
  }) {
    return _makeRequest(
      "POST",
      "/payments/initiate",
      body: {
        "amount": amount,
        "phone": phone,
        "network": network,
        "planId": planId,
        "userId": userId,
      },
    );
  }

  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> data,
  ) {
    return _makeRequest("PUT", "/user/profile", body: data);
  }
}
