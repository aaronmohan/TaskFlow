import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService? _storageService;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider([this._storageService]) {
    if (_storageService != null && _storageService.isDarkMode()) {
      _themeMode = ThemeMode.dark;
    }
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _storageService?.setDarkMode(_themeMode == ThemeMode.dark);
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _storageService?.setDarkMode(isDark);
    notifyListeners();
  }
}
