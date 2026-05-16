import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
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

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
