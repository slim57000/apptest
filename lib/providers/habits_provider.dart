import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class HabitsProvider extends ChangeNotifier {
  /// Nombre d'habitudes actives autorisées en version gratuite.
  static const freeHabitLimit = 3;

  final StorageService _storage;
  final NotificationService _notifications;

  List<Habit> _habits = [];
  bool _loading = true;

  HabitsProvider(this._storage, this._notifications) {
    _load();
  }

  bool get loading => _loading;
  List<Habit> get habits => List.unmodifiable(_habits);

  Future<void> _load() async {
    _habits = await _storage.loadHabits();
    _loading = false;
    notifyListeners();
    // Reprogramme les rappels à chaque ouverture de l'app : les alarmes
    // planifiées ne survivent pas forcément à un redémarrage de l'appareil,
    // ceci les "répare" sans nécessiter de receiver Android natif au boot.
    for (final habit in _habits) {
      if (habit.reminderMinutes != null) {
        await _notifications.scheduleReminders(habit);
      }
    }
  }

  bool canAddHabit(bool isPremium) => isPremium || _habits.length < freeHabitLimit;

  Future<void> addHabit({
    required String name,
    required String emoji,
    required int colorValue,
    Set<int> activeWeekdays = const {},
    int? reminderMinutes,
  }) async {
    final habit = Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      activeWeekdays: activeWeekdays,
      reminderMinutes: reminderMinutes,
    );
    _habits = [..._habits, habit];
    notifyListeners();
    await _storage.saveHabits(_habits);
    await _notifications.scheduleReminders(habit);
  }

  Future<void> deleteHabit(String id) async {
    _habits = _habits.where((h) => h.id != id).toList();
    notifyListeners();
    await _storage.saveHabits(_habits);
    await _notifications.cancelReminders(id);
  }

  Future<void> toggleToday(String id) async {
    _habits = _habits.map((h) => h.id == id ? h.toggled(DateTime.now()) : h).toList();
    notifyListeners();
    await _storage.saveHabits(_habits);
  }

  Future<void> freezeYesterday(String id) async {
    _habits = _habits.map((h) => h.id == id ? h.freezeYesterday() : h).toList();
    notifyListeners();
    await _storage.saveHabits(_habits);
  }

  Future<void> setReminder(String id, int? reminderMinutes) async {
    Habit? updated;
    _habits = _habits.map((h) {
      if (h.id != id) return h;
      updated = h.withReminder(reminderMinutes);
      return updated!;
    }).toList();
    notifyListeners();
    await _storage.saveHabits(_habits);
    if (updated != null) await _notifications.scheduleReminders(updated!);
  }

  Future<void> setNote(String id, DateTime day, String? note) async {
    _habits = _habits.map((h) => h.id == id ? h.withNote(day, note) : h).toList();
    notifyListeners();
    await _storage.saveHabits(_habits);
  }
}
