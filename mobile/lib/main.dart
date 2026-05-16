import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'providers/chat_provider.dart';
import 'theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
