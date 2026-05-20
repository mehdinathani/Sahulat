import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/splash_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'theme.dart';

String _getBackendUrl() {
  // Production Cloud Run Backend
  return 'https://sahulat-ai-backend-823935698067.us-central1.run.app';

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
      locale: settings.locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ur', 'PK'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Force the whole app to flip layout direction when Urdu is selected.
      // Wrapping in Directionality ensures even widgets that don't read Locale
      // (custom painters, manually-laid-out rows) get the right reading order.
      builder: (context, child) {
        return Directionality(
          textDirection: settings.textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
