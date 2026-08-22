import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../services/health_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';

class HabitsProvider extends ChangeNotifier {
  /// Nombre d'habitudes actives autorisées en version gratuite.
  static const freeHabitLimit = 7;

  final StorageService _storage;
  final NotificationService _notifications;
  final HealthService _health;
  final WidgetService _widget;

  List<Habit> _habits = [];
  bool _loading = true;

  HabitsProvider(this._storage, this._notifications, this._health, this._widget) {
    _load();
  }

  bool get loading => _loading;

  /// Toutes les habitudes, y compris archivées (sauvegarde cloud, écran de
  /// détail, jardin virtuel : l'historique d'une habitude archivée continue
  /// de compter).
  List<Habit> get habits => List.unmodifiable(_habits);

  /// Habitudes non archivées uniquement : liste du quotidien, récap, et
  /// décompte du quota gratuit.
  List<Habit> get activeHabits => List.unmodifiable(_habits.where((h) => !h.archived));

  /// Habitudes archivées uniquement, pour l'écran d'archive.
  List<Habit> get archivedHabits => List.unmodifiable(_habits.where((h) => h.archived));

  /// Habitudes à envoyer au widget d'écran d'accueil : jamais les
  /// archivées, qui n'ont rien à faire dans un résumé du quotidien.
  List<Habit> get _widgetHabits => _habits.where((h) => !h.archived).toList();

  Future<void> _persist() async {
    await _storage.saveHabits(_habits);
    await _widget.updateHabits(_widgetHabits);
  }

  Future<void> _load() async {
    _habits = await _storage.loadHabits();
    _loading = false;
    notifyListeners();
    // Reprogramme les rappels à chaque ouverture de l'app : les alarmes
    // planifiées ne survivent pas forcément à un redémarrage de l'appareil,
    // ceci les "répare" sans nécessiter de receiver Android natif au boot.
    // Rappel intelligent : une habitude déjà cochée aujourd'hui saute le
    // jour en cours (skipToday).
    for (final habit in _habits) {
      if (habit.reminderMinutes != null) {
        await _notifications.scheduleNextReminder(habit, skipToday: habit.isCompletedToday);
        await _notifications.scheduleFollowUp(habit, skipToday: habit.isCompletedToday);
      }
    }
    await _widget.updateHabits(_widgetHabits);
    await syncHealthSteps();
  }

  /// Recharge les habitudes depuis le stockage local. À appeler quand l'app
  /// revient au premier plan : une bascule faite depuis le widget écran
  /// d'accueil pendant que l'app était en arrière-plan écrit directement
  /// dans le même stockage (voir `HabitWidgetProvider.kt`), donc l'état en
  /// mémoire doit être resynchronisé pour ne pas l'écraser au prochain
  /// enregistrement.
  Future<void> reload() async {
    _habits = await _storage.loadHabits();
    notifyListeners();
    await _widget.updateHabits(_widgetHabits);
    for (final habit in _habits) {
      if (habit.reminderMinutes != null) {
        // La bascule widget peut avoir changé l'état du jour : replanifie
        // rappel ET relance en fonction.
        await _notifications.scheduleNextReminder(habit, skipToday: habit.isCompletedToday);
        await _notifications.scheduleFollowUp(habit, skipToday: habit.isCompletedToday);
      }
    }
  }

  bool canAddHabit(bool isPremium) => isPremium || activeHabits.length < freeHabitLimit;

  Future<void> addHabit({
    required String name,
    required String emoji,
    required int colorValue,
    Set<int> activeWeekdays = const {},
    int dailyTarget = 1,
    int weeklyGoal = 0,
    int? reminderMinutes,
  }) async {
    final habit = Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      activeWeekdays: activeWeekdays,
      dailyTarget: dailyTarget,
      weeklyGoal: weeklyGoal,
      reminderMinutes: reminderMinutes,
    );
    // L'état est mis à jour et notifié immédiatement (retour visuel
    // instantané) ; l'écriture disque, la mise à jour du widget et la
    // planification des rappels — des opérations lentes — s'exécutent en
    // arrière-plan pour ne pas bloquer l'interface.
    _habits = [..._habits, habit];
    notifyListeners();
    unawaited(_finalizeAdd(habit));
  }

  Future<void> _finalizeAdd(Habit habit) async {
    await _persist();
    await _notifications.scheduleNextReminder(habit);
    await _notifications.scheduleFollowUp(habit, skipToday: habit.isCompletedToday);
  }

  /// Réinsère une habitude supprimée (action « Annuler » du glisser pour
  /// supprimer). Sans effet si une habitude du même id existe déjà.
  Future<void> restoreHabit(Habit habit) async {
    if (_habits.any((h) => h.id == habit.id)) return;
    _habits = [..._habits, habit];
    notifyListeners();
    unawaited(_finalizeAdd(habit));
  }

  Future<void> deleteHabit(String id) async {
    _habits = _habits.where((h) => h.id != id).toList();
    notifyListeners();
    await _persist();
    await _notifications.cancelReminders(id);
    await _notifications.cancelFollowUps(id);
  }

  Future<void> toggleToday(String id) async {
    Habit? updated;
    _habits = _habits.map((h) {
      if (h.id != id) return h;
      updated = h.toggled(DateTime.now());
      return updated!;
    }).toList();
    notifyListeners();
    await _persist();
    // Cœur du rappel intelligent : cocher supprime le rappel/relance du
    // jour (replanifiés à la prochaine occurrence), décocher les restaure.
    if (updated != null) {
      await _notifications.scheduleNextReminder(updated!, skipToday: updated!.isCompletedToday);
      await _notifications.scheduleFollowUp(updated!, skipToday: updated!.isCompletedToday);
    }
  }

  /// Retire un cran au compteur du jour (corrige un tap de trop sur une
  /// habitude à faire plusieurs fois par jour).
  Future<void> decrementToday(String id) async {
    _habits = _habits.map((h) => h.id == id ? h.decremented(DateTime.now()) : h).toList();
    notifyListeners();
    await _persist();
  }

  /// Archive ou désarchive une habitude : elle sort (ou revient) de la liste
  /// du quotidien sans perdre son historique ni ses séries. Les rappels sont
  /// suspendus pendant qu'elle est archivée.
  Future<void> setArchived(String id, bool archived) async {
    Habit? updated;
    _habits = _habits.map((h) {
      if (h.id != id) return h;
      updated = h.withArchived(archived);
      return updated!;
    }).toList();
    notifyListeners();
    await _persist();
    if (updated == null) return;
    if (archived) {
      await _notifications.cancelReminders(id);
      await _notifications.cancelFollowUps(id);
    } else if (updated!.reminderMinutes != null) {
      await _notifications.scheduleNextReminder(updated!, skipToday: updated!.isCompletedToday);
      await _notifications.scheduleFollowUp(updated!, skipToday: updated!.isCompletedToday);
    }
  }

  Future<void> freezeYesterday(String id) async {
    _habits = _habits.map((h) => h.id == id ? h.freezeYesterday() : h).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> setReminder(String id, int? reminderMinutes) async {
    Habit? updated;
    _habits = _habits.map((h) {
      if (h.id != id) return h;
      updated = h.withReminder(reminderMinutes);
      return updated!;
    }).toList();
    notifyListeners();
    await _persist();
    if (updated != null) {
      await _notifications.scheduleNextReminder(updated!, skipToday: updated!.isCompletedToday);
      await _notifications.scheduleFollowUp(updated!, skipToday: updated!.isCompletedToday);
    }
  }

  Future<void> setNote(String id, DateTime day, String? note) async {
    _habits = _habits.map((h) => h.id == id ? h.withNote(day, note) : h).toList();
    notifyListeners();
    await _persist();
  }

  /// Remplace toutes les habitudes locales (restauration depuis une
  /// sauvegarde cloud). Reprogramme les rappels comme au chargement initial.
  Future<void> replaceAll(List<Habit> habits) async {
    _habits = habits;
    notifyListeners();
    await _persist();
    for (final habit in _habits) {
      if (habit.reminderMinutes != null) {
        await _notifications.scheduleNextReminder(habit, skipToday: habit.isCompletedToday);
        await _notifications.scheduleFollowUp(habit, skipToday: habit.isCompletedToday);
      }
    }
  }

  /// Active/désactive la complétion automatique via les pas de santé pour
  /// une habitude. À l'activation, demande l'autorisation Health Connect /
  /// Apple Health puis tente une synchronisation immédiate.
  Future<bool> setAutoTrackSteps(String id, bool value) async {
    if (value) {
      final granted = await _health.requestStepsAuthorization();
      if (!granted) return false;
    }
    _habits = _habits.map((h) => h.id == id ? h.withAutoTrackSteps(value) : h).toList();
    notifyListeners();
    await _persist();
    if (value) await syncHealthSteps();
    return true;
  }

  /// Coche automatiquement les habitudes suivies via la santé si l'objectif
  /// de pas du jour est atteint. Idempotent (n'annule jamais une
  /// complétion) et sans effet pour les habitudes sans suivi automatique.
  Future<void> syncHealthSteps() async {
    final tracked = _habits.where(
      (h) => h.autoTrackSteps && h.isActiveOn(DateTime.now()) && !h.isCompletedToday,
    );
    if (tracked.isEmpty) return;

    final steps = await _health.stepsToday();
    if (steps < stepsGoalForAutoComplete) return;

    _habits = _habits
        .map((h) => h.autoTrackSteps ? h.completeOn(DateTime.now()) : h)
        .toList();
    notifyListeners();
    await _persist();

    for (final habit in _habits) {
      if (habit.autoTrackSteps && habit.reminderMinutes != null) {
        // Complétion automatique = même effet qu'un coche manuel : le
        // rappel et la relance du jour sautent au jour suivant.
        await _notifications.scheduleNextReminder(habit, skipToday: true);
        await _notifications.scheduleFollowUp(habit, skipToday: true);
      }
    }
  }
}
