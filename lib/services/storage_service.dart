import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// Persistance locale des habitudes. Pas de backend pour la v1 : tout vit
/// dans les préférences partagées de l'appareil, sous forme de JSON.
class StorageService {
  static const _habitsKey = 'habits_v1';

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_habitsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_habitsKey, raw);
  }
}
