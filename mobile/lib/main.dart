import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'providers/chat_provider.dart';
import 'theme.dart';

String _getBackendUrl() {
  if (kIsWeb) {
    return 'http://localhost:8080';
  }
  try {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // 10.0.2.2 resolves to localhost on the host machine from Android Emulator
    }
  } catch (_) {}
  return 'http://localhost:8080'; // Fallback for Windows desktop and iOS
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            baseUrl: _getBackendUrl(),
          ),
        ),
      ],
      child: const SahulatApp(),
    ),
  );
}

class SahulatApp extends StatelessWidget {
  const SahulatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahulat-AI',
      debugShowCheckedModeBanner: false,
      theme: SahulatTheme.lightTheme,
      darkTheme: SahulatTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark theme for the premium AI look
      home: const ChatScreen(),
    );
  }
}
