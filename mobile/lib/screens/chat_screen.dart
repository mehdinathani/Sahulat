import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
            color: Colors.black.withOpacity(0.05),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
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

import '../components/provider_card.dart';
import '../components/agent_brain_console.dart';

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
              height: 250,
              margin: const EdgeInsets.only(top: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.providers!.length,
                itemBuilder: (context, index) {
                  final provider = message.providers![index];
                  return ProviderCard(
                    provider: provider,
                    onBook: () {
                      context.read<ChatProvider>().sendMessage('Book ${provider.name}');
                    },
                  );
                },
              ),
            ),
          if (!isUser && message.trace != null && message.trace!.isNotEmpty)
            AgentBrainConsole(trace: message.trace!),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: actions.map((action) {
          return ActionChip(
            label: Text(action),
            onPressed: () {
              context.read<ChatProvider>().sendMessage(action);
            },
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
