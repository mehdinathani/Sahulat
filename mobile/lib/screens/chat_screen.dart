import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../components/provider_card.dart';
import 'booking_summary.dart';
import 'bookings_list.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording(ChatProvider provider) async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        provider.sendVoiceMessage(path);
      }
    } else {
      try {
        if (await _audioRecorder.hasPermission()) {
          // Use temporary directory for recording
          final tempDir = Directory.systemTemp;
          final path = p.join(tempDir.path, 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a');
          
          const config = RecordConfig(); // Default config
          await _audioRecorder.start(config, path: path);
          setState(() => _isRecording = true);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission denied')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error starting record: $e');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    // Scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sahulat-AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookingsListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => chatProvider.clearMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          if (chatProvider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          _buildInputSection(context, chatProvider),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('chat_input'),
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask for a service...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (value) {
                  provider.sendMessage(value);
                  _controller.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _isRecording 
                  ? Colors.red 
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: IconButton(
                tooltip: 'voice_record_button',
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? Colors.white : Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _toggleRecording(provider),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                tooltip: 'send_button',
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  provider.sendMessage(_controller.text);
                  _controller.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
            ),
            child: MarkdownBody(
              data: message.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isUser
                      ? Colors.white
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
          if (!isUser && message.providers != null && message.providers!.isNotEmpty)
            Container(
              height: 300,
              margin: const EdgeInsets.only(top: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.providers!.length,
                itemBuilder: (context, index) {
                  final provider = message.providers![index];
                  return ProviderCard(
                    provider: provider,
                    onBook: () async {
                      final confirmed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingSummaryScreen(provider: provider),
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        context.read<ChatProvider>().sendMessage('Book ${provider.name}');
                      }
                    },
                  );
                },
              ),
            ),
          if (!isUser &&
              message.suggestedActions != null &&
              message.suggestedActions!.isNotEmpty)
            _SuggestedActions(actions: message.suggestedActions!),
        ],
      ),
    );
  }
}

class _SuggestedActions extends StatelessWidget {
  final List<String> actions;

  const _SuggestedActions({required this.actions});

  /// Check if the action is a navigation or local command rather than a
  /// service query that should be sent to the backend chat API.
  void _handleAction(BuildContext context, String action) {
    final lower = action.toLowerCase();

    // Navigation: bookings list
    if (lower.contains('view') && lower.contains('booking') ||
        lower.contains('my booking')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookingsListScreen()),
      );
      return;
    }

    // Local feedback: contact provider
    if (lower.contains('contact')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider contact details will be available soon.'),
        ),
      );
      return;
    }

    // Local feedback: cancel booking
    if (lower.contains('cancel')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancellation will be available soon.'),
        ),
      );
      return;
    }

    // Default: send as a chat message to the backend
    context.read<ChatProvider>().sendMessage(action);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: actions.map((action) {
          return ActionChip(
            label: Text(action),
            onPressed: () => _handleAction(context, action),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }
}
