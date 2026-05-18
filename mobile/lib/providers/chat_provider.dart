import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  late final ApiService _apiService;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  ChatProvider({String? baseUrl}) {
    _apiService = ApiService(baseUrl: baseUrl ?? 'http://localhost:8080');
  }

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    debugPrint('Sending message: $content');
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(role: 'user', content: content);
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      final assistantMessage = await _apiService.sendChatMessage(content);
      _messages.add(assistantMessage);
    } catch (e) {
      _messages.add(ChatMessage(
        role: 'assistant',
        content: 'Sorry, I encountered an error: ${e.toString()}',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendVoiceMessage(String audioPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final transcript = await _apiService.transcribeAudio(File(audioPath));
      if (transcript.isNotEmpty) {
        await sendMessage(transcript);
      } else {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'I couldn\'t understand the audio. Please try again or type your request.',
        ));
      }
    } catch (e) {
      _messages.add(ChatMessage(
        role: 'assistant',
        content: 'Voice processing failed: ${e.toString()}',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
