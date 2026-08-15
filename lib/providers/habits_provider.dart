import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';

class HabitsProvider extends ChangeNotifier {
  /// Nombre d'habitudes actives autorisées en version gratuite.
  static const freeHabitLimit = 3;

  final StorageService _storage;

  List<Habit> _habits = [];
  bool _loading = true;

  HabitsProvider(this._storage) {
    _load();
  }

  bool get loading => _loading;
  List<Habit> get habits => List.unmodifiable(_habits);

  Future<void> _load() async {
    _habits = await _storage.loadHabits();
    _loading = false;
    notifyListeners();
  }

  bool canAddHabit(bool isPremium) => isPremium || _habits.length < freeHabitLimit;

  Future<void> addHabit({
    required String name,
    required String emoji,
    required int colorValue,
    Set<int> activeWeekdays = const {},
  }) async {
    final habit = Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      activeWeekdays: activeWeekdays,
    );
    _habits = [..._habits, habit];
    notifyListeners();
    await _storage.saveHabits(_habits);
  }

  Future<void> deleteHabit(String id) async {
    _habits = _habits.where((h) => h.id != id).toList();
    notifyListeners();
    await _storage.saveHabits(_habits);
  }

  Future<void> toggleToday(String id) async {
    _habits = _habits.map((h) => h.id == id ? h.toggled(DateTime.now()) : h).toList();
    notifyListeners();
    await _storage.saveHabits(_habits);
  }
}
