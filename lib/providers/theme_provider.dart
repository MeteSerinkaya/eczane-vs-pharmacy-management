// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode'; // SharedPreferences anahtarı

  ThemeMode _themeMode = ThemeMode.light; // Varsayılan tema

  // Constructor
  ThemeProvider() {
    _loadThemeFromPrefs(); // Uygulama açıldığında kayıtlı temayı yükle
  }

  // Getter - Dışarıdan tema durumunu al
  ThemeMode get themeMode => _themeMode;

  // Tema değiştirme fonksiyonu
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark; // Light'tan Dark'a geç
    } else {
      _themeMode = ThemeMode.light; // Dark'tan Light'a geç
    }

    _saveThemeToPrefs(); // Tercihi kaydet
    notifyListeners(); // UI'ı güncelle
  }

  // SharedPreferences'dan tema yükle
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'light'; // Varsayılan 'light'

    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    }

    notifyListeners(); // UI'ı güncelle
  }

  // Tema tercihini SharedPreferences'a kaydet
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode == ThemeMode.light ? 'light' : 'dark');
  }
}
