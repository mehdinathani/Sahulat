import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark for premium look
  String _languageCode = 'auto'; // 'auto', 'en-US', 'ur-PK'
  String _voicePreset = 'electrician'; // 'electrician', 'ac', 'plumber', 'tutor'
  bool _showAgentReasoning = false; // Default to false so reasoning traces are hidden for clean prod look

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  String get voicePreset => _voicePreset;
  bool get showAgentReasoning => _showAgentReasoning;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Whether the UI should lay out right-to-left.
  /// True for Urdu (ur-PK); false otherwise (including 'auto' which defaults to LTR).
  bool get isRtl => _languageCode == 'ur-PK';

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  Locale get locale {
    switch (_languageCode) {
      case 'ur-PK':
        return const Locale('ur', 'PK');
      case 'en-US':
        return const Locale('en', 'US');
      default:
        return const Locale('en', 'US');
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLanguageCode(String langCode) {
    _languageCode = langCode;
    notifyListeners();
  }

  void setVoicePreset(String preset) {
    _voicePreset = preset;
    notifyListeners();
  }

  void setShowAgentReasoning(bool value) {
    _showAgentReasoning = value;
    notifyListeners();
  }
}
