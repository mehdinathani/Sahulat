import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

import '../models/provider.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://localhost:8000'}); // Update with real IP for physical device

  Future<ChatMessage> sendChatMessage(String content) async {
    final url = Uri.parse('$baseUrl/api/chat');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': 'user',
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        List<AgentTrace>? trace;
        if (data['trace'] != null) {
          trace = (data['trace'] as List)
              .map((t) => AgentTrace.fromJson(t))
              .toList();
        }

        List<ServiceProvider>? providers;
        if (data['providers'] != null) {
          providers = (data['providers'] as List)
              .map((p) => ServiceProvider.fromJson(p))
              .toList();
        }

        return ChatMessage(
          role: 'assistant',
          content: data['content'],
          trace: trace,
          suggestedActions: data['suggested_actions'] != null 
              ? List<String>.from(data['suggested_actions']) 
              : null,
          providers: providers,
        );
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  Future<Map<String, dynamic>> confirmBooking(String providerId, {String? requestId}) async {
    final url = Uri.parse('$baseUrl/api/booking/confirm');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider_id': providerId,
          if (requestId != null) 'request_id': requestId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to confirm booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBookings() async {
    final url = Uri.parse('$baseUrl/api/booking/list');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch bookings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }
}
