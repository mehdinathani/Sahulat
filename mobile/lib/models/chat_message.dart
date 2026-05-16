import 'provider.dart';

class AgentTrace {
  final String step;
  final String thought;
  final String? action;
  final String? observation;

  AgentTrace({
    required this.step,
    required this.thought,
    this.action,
    this.observation,
  });

  factory AgentTrace.fromJson(Map<String, dynamic> json) {
    return AgentTrace(
      step: json['step'] ?? '',
      thought: json['thought'] ?? '',
      action: json['action'],
      observation: json['observation'],
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  final List<AgentTrace>? trace;
  final List<String>? suggestedActions;
  final List<ServiceProvider>? providers;
  final DateTime timestamp;
  final String? bookingId;

  ChatMessage({
    required this.role,
    required this.content,
    this.trace,
    this.suggestedActions,
    this.providers,
    this.bookingId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      trace: (json['trace'] as List?)
          ?.map((t) => AgentTrace.fromJson(t))
          .toList(),
      suggestedActions: (json['suggested_actions'] as List?)
          ?.map((a) => a.toString())
          .toList(),
      providers: (json['providers'] as List?)
          ?.map((p) => ServiceProvider.fromJson(p))
          .toList(),
      bookingId: json['booking_id'],
    );
  }
}
