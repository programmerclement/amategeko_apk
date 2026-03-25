import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = "https://amategeko-backend-new.onrender.com/api";

  // Fetch user payment history
  static Future<Map<String, dynamic>> fetchPaymentHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payments"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": jsonDecode(response.body),
        };
      } else {
        return {
          "success": false,
          "message": "Failed to fetch payment history",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }
}