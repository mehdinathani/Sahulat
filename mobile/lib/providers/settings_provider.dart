import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark for premium look
  String _languageCode = 'auto'; // 'auto', 'en-US', 'ur-PK'
  String _voicePreset = 'electrician'; // 'electrician', 'ac', 'plumber', 'tutor'

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  String get voicePreset => _voicePreset;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

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
}
