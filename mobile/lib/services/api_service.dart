import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/provider.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'https://sahulat-backend-118267129512.us-central1.run.app'});

  // --------------------------------------------------------------------------
  // Chat: send a text message and receive an agentic response.
  // --------------------------------------------------------------------------
  Future<ChatMessage> sendChatMessage(String content) async {
    final url = Uri.parse('$baseUrl/api/chat');
    debugPrint('Calling API: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': 'user', 'content': content}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        List<AgentTrace>? trace;
        if (data['trace'] != null) {
          trace = (data['trace'] as List).map((t) => AgentTrace.fromJson(t)).toList();
        }

        List<ServiceProvider>? providers;
        if (data['providers'] != null) {
          providers = (data['providers'] as List).map((p) => ServiceProvider.fromJson(p)).toList();
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
      throw Exception('Chat API returned ${response.statusCode}');
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  // --------------------------------------------------------------------------
  // Speech-to-Text: upload an audio recording for transcription.
  //
  // The backend POST /api/stt endpoint accepts multipart/form-data with an
  // "audio" file field and returns {"transcript": "..."}.
  //
  // Usage in chat_screen.dart:
  //   final transcript = await apiService.transcribeAudio(File(path));
  //   if (transcript.isNotEmpty) sendChatMessage(transcript);
  //
  // Returns an empty string on any error so the UI can degrade gracefully.
  // --------------------------------------------------------------------------
  Future<String> transcribeAudio(File audioFile, {String? languageCode, String? preset}) async {
    final url = Uri.parse('$baseUrl/api/stt');

    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFile.path),
      );

      if (languageCode != null) {
        request.fields['language_code'] = languageCode;
      }
      if (preset != null) {
        request.fields['preset'] = preset;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return (data['transcript'] as String? ?? '').trim();
      } else {
        debugPrint('STT API error: ${response.statusCode} — ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('STT transcription failed: $e');
      return '';
    }
  }

  // --------------------------------------------------------------------------
  // Booking: confirm a provider booking.
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> confirmBooking(String providerId, {String? requestId}) async {
    final url = Uri.parse('$baseUrl/api/booking/confirm');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider_id': providerId,
          'request_id': requestId,
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

  // --------------------------------------------------------------------------
  // Bookings: fetch all bookings for the current user.
  // --------------------------------------------------------------------------
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
