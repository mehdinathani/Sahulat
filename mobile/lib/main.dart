import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/chat_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'theme.dart';

String _getBackendUrl() {
  // Production Cloud Run Backend
  return 'https://sahulat-backend-118267129512.us-central1.run.app';

  // Local development fallback
  /*
  if (kIsWeb) {
    return 'http://localhost:8080';
  }
  try {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // 10.0.2.2 resolves to localhost on the host machine from Android Emulator
    }
  } catch (_) {}
  return 'http://localhost:8080'; // Fallback for Windows desktop and iOS
  */
}

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Trace Logging
  debugPrint('[UI State: Agentic System Initializing...]');

  // Simulate Agentic Brain Initialization
  Future.delayed(const Duration(milliseconds: 2500), () {
    FlutterNativeSplash.remove();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
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
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Sahulat-AI',
      debugShowCheckedModeBanner: false,
      theme: SahulatTheme.lightTheme,
      darkTheme: SahulatTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const ChatScreen(),
    );
  }
}
