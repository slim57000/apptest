import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférence explicite de thème clair/sombre (Réglages), sur le même
/// modèle que [LocaleProvider] pour la langue. `ThemeMode.system` (valeur
/// par défaut) suit le thème de l'appareil.
class AppThemeModeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_mode_override_v1';

  ThemeMode _mode = ThemeMode.system;
  bool _loading = true;

  AppThemeModeProvider() {
    _load();
  }

  ThemeMode get mode => _mode;
  bool get loading => _loading;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_prefsKey)) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
    }
  }
}
