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
import 'providers_map_screen.dart';
import '../theme.dart';
import '../providers/settings_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AudioRecorder _audioRecorder;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chatProvider = context.read<ChatProvider>();
        if (chatProvider.messages.isEmpty) {
          chatProvider.fetchLocationAndLoadNearbyServices();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording(ChatProvider provider) async {
    final settings = context.read<SettingsProvider>();
    final isRecording = await _audioRecorder.isRecording();
    if (isRecording) {
      final path = await _audioRecorder.stop();
      provider.setListening(false);
      if (path != null) {
        provider.sendVoiceMessage(
          path,
          languageCode: settings.languageCode,
          preset: settings.voicePreset,
        );
      }
    } else {
      try {
        if (await _audioRecorder.hasPermission()) {
          // Use temporary directory for recording
          final tempDir = Directory.systemTemp;
          final path = p.join(tempDir.path, 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a');
          
          const config = RecordConfig(); // Default config
          await _audioRecorder.start(config, path: path);
          provider.setListening(true);
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

  String _getStateText(ChatState state) {
    switch (state) {
      case ChatState.listening:
        return 'Listening...';
      case ChatState.processingVoice:
        return 'Processing voice...';
      case ChatState.thinking:
        return 'Thinking...';
      case ChatState.idle:
        return '';
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsBottomSheet(context),
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
          if (chatProvider.state != ChatState.idle)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStateText(chatProvider.state),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          _buildInputSection(context, chatProvider),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, ChatProvider provider) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('chat_input'),
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Ask for a service...',
                ),
                onSubmitted: (value) {
                  provider.sendMessage(value);
                  _controller.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            _VoiceRecordButton(
              isRecording: provider.state == ChatState.listening,
              onPressed: () => _toggleRecording(provider),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
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

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            final theme = Theme.of(context);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'App Settings',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Theme Mode setting
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Dark Theme',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: settings.isDarkMode,
                          activeThumbColor: theme.colorScheme.primary,
                          onChanged: (bool value) {
                            settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Language selection
                    Text(
                      'Voice Language Filter',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Constrain speech-to-text to a specific language or auto-detect.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildChoiceChip(
                          context,
                          label: 'Auto Detect',
                          selected: settings.languageCode == 'auto',
                          onSelected: () => settings.setLanguageCode('auto'),
                        ),
                        const SizedBox(width: 8),
                        _buildChoiceChip(
                          context,
                          label: 'Urdu',
                          selected: settings.languageCode == 'ur-PK',
                          onSelected: () => settings.setLanguageCode('ur-PK'),
                        ),
                        const SizedBox(width: 8),
                        _buildChoiceChip(
                          context,
                          label: 'English',
                          selected: settings.languageCode == 'en-US',
                          onSelected: () => settings.setLanguageCode('en-US'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Simulation Preset selection
                    Text(
                      'Voice Simulation Preset',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a mock scenario to run with unconfigured API key backend fallback.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: settings.voicePreset,
                      dropdownColor: theme.colorScheme.surface,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'electrician',
                          child: Text('Electrician Booking Mock'),
                        ),
                        DropdownMenuItem(
                          value: 'ac',
                          child: Text('AC Repair Booking Mock'),
                        ),
                        DropdownMenuItem(
                          value: 'plumber',
                          child: Text('Plumber Booking Mock'),
                        ),
                        DropdownMenuItem(
                          value: 'tutor',
                          child: Text('Tutor Booking Mock'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          settings.setVoicePreset(newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChoiceChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
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
                  : theme.colorScheme.surface,
              border: isUser
                  ? null
                  : Border.all(color: theme.colorScheme.outlineVariant, width: 1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: SahulatTheme.primaryGlow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: SahulatTheme.primaryGlow,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Orchestrator Active',
                        style: GoogleFonts.plusJakartaSans(
                          color: SahulatTheme.primaryGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                MarkdownBody(
                  data: message.content,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isUser && message.trace != null && message.trace!.isNotEmpty)
            _ReasoningPanel(trace: message.trace!),
          if (!isUser && message.providers != null && message.providers!.isNotEmpty) ...[  
            // 'View All on Map' button
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProvidersMapScreen(
                        providers: message.providers!,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: SahulatTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SahulatTheme.primaryColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 16, color: SahulatTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'View ${message.providers!.length} Provider${message.providers!.length > 1 ? 's' : ''} on Map',
                          style: TextStyle(
                            color: SahulatTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Provider cards horizontal list
            SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.providers!.length,
                itemBuilder: (context, index) {
                  final provider = message.providers![index];
                  return ProviderCard(
                    provider: provider,
                    onViewMap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProvidersMapScreen(
                          providers: message.providers!,
                          focusedProvider: provider,
                        ),
                      ),
                    ),
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
          ],
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
          );
        }).toList(),
      ),
    );
  }
}

class _ReasoningPanel extends StatefulWidget {
  final List<AgentTrace> trace;

  const _ReasoningPanel({required this.trace});

  @override
  State<_ReasoningPanel> createState() => _ReasoningPanelState();
}

class _ReasoningPanelState extends State<_ReasoningPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Agent Reasoning System',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.trace.map((step) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.step.isNotEmpty ? step.step : 'Reasoning Step',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (step.thought.isNotEmpty) ...[
                          Text(
                            'Thought:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            step.thought,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (step.action != null && step.action!.isNotEmpty) ...[
                          Text(
                            'Action:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              step.action!,
                              style: GoogleFonts.firaCode(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (step.observation != null && step.observation!.isNotEmpty) ...[
                          Text(
                            'Observation:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              step.observation!,
                              style: GoogleFonts.firaCode(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _VoiceRecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const _VoiceRecordButton({
    required this.isRecording,
    required this.onPressed,
  });

  @override
  State<_VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<_VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isRecording) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.isRecording;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isRecording
                ? [
                    BoxShadow(
                      color: SahulatTheme.errorColor.withValues(alpha: 0.3),
                      blurRadius: _animation.value + 4,
                      spreadRadius: _animation.value / 2,
                    ),
                  ]
                : [],
          ),
          child: CircleAvatar(
            backgroundColor: isRecording ? SahulatTheme.errorColor : SahulatTheme.primaryColor,
            child: IconButton(
              tooltip: 'voice_record_button',
              icon: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
              onPressed: widget.onPressed,
            ),
          ),
        );
      },
    );
  }
}
