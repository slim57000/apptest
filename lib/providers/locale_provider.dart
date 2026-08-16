import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférence de langue explicite de l'utilisateur (Réglages), en plus de
/// la détection automatique de `app.dart`. `null` = suit la langue du
/// système (comportement par défaut, avec repli sur le français géré par
/// `localeResolutionCallback`).
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'locale_override_v1';

  Locale? _locale;
  bool _loading = true;

  LocaleProvider() {
    _load();
  }

  Locale? get locale => _locale;
  bool get loading => _loading;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    _locale = code == null ? null : Locale(code);
    _loading = false;
    notifyListeners();
  }

  /// [languageCode] `null` pour revenir au comportement "système".
  Future<void> setLanguageCode(String? languageCode) async {
    _locale = languageCode == null ? null : Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, languageCode);
    }
  }
}
