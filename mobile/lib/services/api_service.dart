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
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }
}
