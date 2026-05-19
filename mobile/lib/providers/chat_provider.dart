import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/provider.dart';
import '../services/api_service.dart';
import '../services/map_service.dart';

enum ChatState {
  idle,
  listening,
  processingVoice,
  thinking,
}

class ChatProvider with ChangeNotifier {
  late final ApiService _apiService;
  final List<ChatMessage> _messages = [];
  ChatState _state = ChatState.idle;

  ChatProvider({String? baseUrl}) {
    _apiService = ApiService(baseUrl: baseUrl ?? 'https://sahulat-backend-118267129512.us-central1.run.app');
  }

  List<ChatMessage> get messages => _messages;
  ChatState get state => _state;
  bool get isLoading => _state != ChatState.idle;

  void setListening(bool isListening) {
    _state = isListening ? ChatState.listening : ChatState.idle;
    notifyListeners();
  }

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
    _state = ChatState.thinking;
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
      _state = ChatState.idle;
      notifyListeners();
    }
  }

  Future<void> sendVoiceMessage(String audioPath, {String? languageCode, String? preset}) async {
    _state = ChatState.processingVoice;
    notifyListeners();

    try {
      final transcript = await _apiService.transcribeAudio(
        File(audioPath),
        languageCode: languageCode,
        preset: preset,
      );
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
      if (_state == ChatState.processingVoice) {
        _state = ChatState.idle;
        notifyListeners();
      }
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> fetchLocationAndLoadNearbyServices() async {
    final loadingMessage = ChatMessage(
      role: 'assistant',
      content: '📍 *Detecting your location to find nearby services...*',
    );
    _messages.add(loadingMessage);
    _state = ChatState.thinking;
    notifyListeners();

    try {
      final userCoords = await MapService.getUserLocation();
      String neighborhood = 'Clifton, Karachi'; // Default fallback
      
      if (userCoords != null) {
        neighborhood = ServiceProvider.getClosestNeighborhood(
          userCoords.latitude,
          userCoords.longitude,
        );
      }

      final baseCoords = ServiceProvider.getNeighborhoodLatLng(neighborhood);

      // Generate mock services clustered in the resolved neighborhood
      final nearbyProviders = [
        ServiceProvider(
          id: 'prov_elec_start',
          name: 'Arsalan Ahmed',
          serviceType: 'Electrician',
          location: neighborhood,
          rating: 4.8,
          pricePerHour: 450,
          availability: true,
          distance: 0.4,
          latitude: baseCoords.latitude + 0.002,
          longitude: baseCoords.longitude - 0.003,
        ),
        ServiceProvider(
          id: 'prov_plumb_start',
          name: 'Waseem Akram',
          serviceType: 'Plumber',
          location: neighborhood,
          rating: 4.7,
          pricePerHour: 400,
          availability: true,
          distance: 0.9,
          latitude: baseCoords.latitude - 0.004,
          longitude: baseCoords.longitude + 0.002,
        ),
        ServiceProvider(
          id: 'prov_ac_start',
          name: 'Siddique AC & Cooling',
          serviceType: 'AC Repair',
          location: neighborhood,
          rating: 4.9,
          pricePerHour: 600,
          availability: true,
          distance: 0.6,
          latitude: baseCoords.latitude + 0.003,
          longitude: baseCoords.longitude + 0.004,
        ),
        ServiceProvider(
          id: 'prov_tutor_start',
          name: 'Zainab Fatima',
          serviceType: 'Tutor',
          location: neighborhood,
          rating: 4.9,
          pricePerHour: 1000,
          availability: true,
          distance: 1.2,
          latitude: baseCoords.latitude - 0.001,
          longitude: baseCoords.longitude - 0.005,
        ),
      ];

      _messages.remove(loadingMessage);
      _messages.add(ChatMessage(
        role: 'assistant',
        content: '📍 **Welcome to Sahulat-AI!**\n\nWe successfully detected your location near **$neighborhood**.\n\nHere are the top-rated service providers currently available nearby to assist you immediately:',
        providers: nearbyProviders,
        suggestedActions: [
          'I need an electrician',
          'Find a plumber nearby',
          'Book AC Repair',
          'Check my bookings',
        ],
      ));
    } catch (e) {
      debugPrint('Error fetching location or loading nearby services: $e');
      _messages.remove(loadingMessage);
      _messages.add(ChatMessage(
        role: 'assistant',
        content: 'Welcome to Sahulat-AI! Ask me for any service like electrician, plumber, AC repair, or tutoring.',
      ));
    } finally {
      _state = ChatState.idle;
      notifyListeners();
    }
  }
}
