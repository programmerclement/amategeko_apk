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
    return _makeRequest("GET", "/auth/me");
  }

  // ========== EXAMS ==========
  static Future<Map<String, dynamic>> fetchExamHistory() {
    return _makeRequest("GET", "/exam/history");
  }

  static Future<Map<String, dynamic>> checkExamEligibility() {
    return _makeRequest("GET", "/exam/check-eligibility");
  }

  static Future<Map<String, dynamic>> generateExam({
    String category = 'all',
    String difficulty = 'all',
    int numberOfQuestions = 20,
  }) {
    print('🔄 [ApiService] Generating exam - category: $category, difficulty: $difficulty, questions: $numberOfQuestions');
    return _makeRequest(
      "POST",
      "/exam/generate",
      body: {
        "category": category,
        "difficulty": difficulty,
        "numberOfQuestions": numberOfQuestions,
      },
    );
  }

  static Future<Map<String, dynamic>> submitExam({
    required Map<String, dynamic> answers,
    required int timeSpent,
    required Map<String, dynamic> examData,
  }) {
    print('📤 [ApiService] Submitting exam - answers: ${answers.length}, timeSpent: $timeSpent');
    return _makeRequest(
      "POST",
      "/exam/submit",
      body: {
        "answers": answers,
        "timeSpent": timeSpent,
        "examData": examData,
      },
    );
  }

  static Future<Map<String, dynamic>> startExam(String examId) {
    return _makeRequest("POST", "/exam/start", body: {"examId": examId});
  }

  // ========== PAYMENTS ==========
  static Future<Map<String, dynamic>> fetchUserPayments(String userId) {
    return _makeRequest("GET", "/payments/user/$userId");
  }

  // Public pricing plans (no authentication required)
  static Future<dynamic> fetchPublicPricingPlans() async {
    try {
      final uri = Uri.parse("$baseUrl/pricing/plans");
      print("📡 Fetching pricing plans from: $uri");
      
      final response = await http.get(uri).timeout(Duration(seconds: 10));

      print("✅ API GET /pricing/plans - Status: ${response.statusCode}");
      print("📝 Raw Response: ${response.body}");
      print("📊 Response Type: ${response.body.runtimeType}");

      if (response.statusCode >= 400) {
        print("❌ Server error: ${response.statusCode}");
        return {"success": false, "message": "Server error: ${response.statusCode}", "data": []};
      }

      final decoded = jsonDecode(response.body);
      print("✨ Decoded Response: $decoded");
      print("✨ Response Type after decode: ${decoded.runtimeType}");
      
      return decoded;
    } catch (e) {
      print("❌ API Error: $e");
      print("❌ Error Type: ${e.runtimeType}");
      return {"success": false, "message": "Network error: $e", "data": []};
    }
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

  // Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(String reference) {
    return _makeRequest("GET", "/payments/status/$reference");
  }

  // Manual payment check
  static Future<Map<String, dynamic>> manualPaymentCheck(String reqRef) {
    return _makeRequest("GET", "/payments/manual-check/$reqRef");
  }

  // Confirm payment manually
  static Future<Map<String, dynamic>> confirmPayment(String reference) {
    return _makeRequest("POST", "/payments/confirm/$reference", body: {});
  }

  static Future<Map<String, dynamic>> activatePlan({
    required String planId,
  }) {
    return _makeRequest("POST", "/users/activate-plan", body: {"planId": planId});
  }

  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> data,
  ) {
    return _makeRequest("PUT", "/users/profile", body: data);
  }

  static Future<Map<String, dynamic>> changeUserPassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _makeRequest("PUT", "/users/password", body: {
      "currentPassword": currentPassword,
      "newPassword": newPassword,
    });
  }
}
