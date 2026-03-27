import 'dart:convert';
import 'package:http/http.dart' as http;

class ExamService {
  static const String baseUrl = "https://amategeko-backend-new.onrender.com/api";

  // Fetch user exam history
  static Future<Map<String, dynamic>> fetchExamHistory(String token) async {
    try {
      print('🔄 [ExamService] Fetching exam history...');
      
      final url = "$baseUrl/exam/history";
      print('📡 [ExamService] Requesting: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(Duration(seconds: 15));

      print('📊 [ExamService] Status Code: ${response.statusCode}');
      print('📝 [ExamService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('✅ [ExamService] Exam history fetched successfully');
        
        // Handle different response formats
        if (decoded is List) {
          return {
            "success": true,
            "data": decoded,
          };
        } else if (decoded is Map && decoded.containsKey('exams')) {
          return {
            "success": true,
            "data": decoded['exams'] ?? [],
          };
        } else if (decoded is Map && decoded.containsKey('data')) {
          return {
            "success": true,
            "data": decoded['data'] ?? [],
          };
        } else {
          return {
            "success": true,
            "data": [decoded],
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ [ExamService] Unauthorized');
        return {
          "success": false,
          "message": "Unauthorized. Please login again.",
        };
      } else if (response.statusCode == 404) {
        print('⚠️ [ExamService] No exam history found (404)');
        return {
          "success": true,
          "data": [],
        };
      } else {
        print('❌ [ExamService] Error: ${response.statusCode}');
        return {
          "success": false,
          "message": "Failed to fetch exam history: ${response.statusCode}",
        };
      }
    } catch (e) {
      print('❌ [ExamService] Exception: $e');
      return {
        "success": false,
        "message": "Network error: $e",
      };
    }
  }
}