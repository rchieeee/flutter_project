import 'package:flutter/material.dart';

/// State management class to handle Theme context globally.
/// This fulfills the instructor's requirement for context/state management.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notifies the widget tree to rebuild with the new context
  }
}
