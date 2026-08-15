import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';

/// Met à jour le widget écran d'accueil Android avec les habitudes du
/// jour (lecture seule pour la v1 : un tap ouvre l'app). Communique via
/// un `MethodChannel` maison (voir `MainActivity.kt` /
/// `HabitWidgetProvider.kt`) plutôt qu'un package tiers, pour ne dépendre
/// que d'APIs Android standard faciles à vérifier.
class WidgetService {
  static const _channel = MethodChannel('com.habitudeplus.habit_tracker/widget');

  Future<void> updateHabits(List<Habit> habits) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final today = DateTime.now();
    final activeToday = habits.where((h) => h.isActiveOn(today)).toList();
    final rows = activeToday
        .take(4)
        .map((h) => {'name': h.name, 'emoji': h.emoji, 'done': h.isCompletedToday})
        .toList();
    final doneCount = activeToday.where((h) => h.isCompletedToday).length;

    try {
      await _channel.invokeMethod('updateHabits', jsonEncode({
        'rows': rows,
        'doneCount': doneCount,
        'activeCount': activeToday.length,
      }));
    } catch (_) {
      // Pas de récepteur natif (ex. widget jamais ajouté à l'écran
      // d'accueil, ou plateforme sans channel enregistré) : sans effet.
    }
  }
}
