import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  static const String baseUrl = "https://amategeko-backend-new.onrender.com/api";

  // Get userId from storage
  static Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("userId");
      print('📍 [PaymentService] Retrieved userId: $userId');
      return userId;
    } catch (e) {
      print('❌ [PaymentService] Error getting userId: $e');
      return null;
    }
  }

  // Fetch user payment history
  static Future<Map<String, dynamic>> fetchPaymentHistory(String token) async {
    try {
      print('🔄 [PaymentService] Fetching payment history...');
      
      // Get userId from storage
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) {
        print('❌ [PaymentService] No userId found');
        return {
          "success": false,
          "message": "User ID not found. Please login again.",
        };
      }

      final url = "$baseUrl/payments/user/$userId";
      print('📡 [PaymentService] Requesting: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(Duration(seconds: 15));

      print('📊 [PaymentService] Status Code: ${response.statusCode}');
      print('📝 [PaymentService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('✅ [PaymentService] Payment history fetched successfully');
        
        // Handle different response formats from backend
        if (decoded is List) {
          return {
            "success": true,
            "data": decoded,
          };
        } else if (decoded is Map) {
          // Check for 'payments' key first (actual backend response)
          if (decoded.containsKey('payments')) {
            return {
              "success": true,
              "data": decoded['payments'] ?? [],
            };
          }
          // Check for 'data' key as fallback
          else if (decoded.containsKey('data')) {
            return {
              "success": true,
              "data": decoded['data'] ?? [],
            };
          }
          // Single item response
          else {
            return {
              "success": true,
              "data": [decoded],
            };
          }
        } else {
          return {
            "success": true,
            "data": [],
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ [PaymentService] Unauthorized');
        return {
          "success": false,
          "message": "Unauthorized. Please login again.",
        };
      } else if (response.statusCode == 404) {
        print('⚠️ [PaymentService] No payment history found (404)');
        return {
          "success": true,
          "data": [],
        };
      } else {
        print('❌ [PaymentService] Error: ${response.statusCode}');
        return {
          "success": false,
          "message": "Failed to fetch payment history: ${response.statusCode}",
        };
      }
    } catch (e) {
      print('❌ [PaymentService] Exception: $e');
      return {
        "success": false,
        "message": "Network error: $e",
      };
    }
  }
}