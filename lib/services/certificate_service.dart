import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CertificateService {
  static const String baseUrl =
      "https://amategeko-backend-new.onrender.com/api";

  // Get token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Get certificate for user
  static Future<Map<String, dynamic>> getCertificateForUser(
    String userId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "No authentication token found"};
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final uri = Uri.parse("$baseUrl/certificate/$userId");
      final response = await http.get(uri, headers: headers);

      print("API GET /certificate/$userId - Status: ${response.statusCode}");
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

  // Verify certificate by code
  static Future<Map<String, dynamic>> verifyCertificate(
    String certificateCode,
  ) async {
    try {
      final uri = Uri.parse("$baseUrl/certificate/verify/$certificateCode");
      final response = await http.get(uri);

      print(
        "API GET /certificate/verify/$certificateCode - Status: ${response.statusCode}",
      );
      print("Response: ${response.body}");

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

  // Download certificate PDF
  static Future<http.Response> downloadCertificatePdf(
    String certificateId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No authentication token found");
      }

      final headers = {"Authorization": "Bearer $token"};

      final uri = Uri.parse("$baseUrl/certificate/$certificateId/download");
      final response = await http.get(uri, headers: headers);

      print(
        "API GET /certificate/$certificateId/download - Status: ${response.statusCode}",
      );

      if (response.statusCode >= 400) {
        throw Exception(
          "Failed to download certificate: ${response.statusCode}",
        );
      }

      return response;
    } catch (e) {
      print("API Error: $e");
      rethrow;
    }
  }
}
