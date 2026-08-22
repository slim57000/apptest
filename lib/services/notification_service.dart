import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Rappels locaux « intelligents » pour les habitudes (aucune donnée envoyée
/// à un serveur).
///
/// Au lieu de répéter une alarme hebdomadaire aveugle, chaque habitude n'a
/// qu'UN rappel programmé à la fois : sa prochaine occurrence à une date où
/// elle est active ET pas encore cochée. À chaque changement d'état — ouverture
/// de l'app, complétion via l'app ou le widget, changement de rappel —
/// `HabitsProvider` annule et replanifie ce rendez-vous :
///   - habit cochée aujourd'hui → le rappel du jour est supprimé ;
///   - habit décochée avant l'heure → le rappel du jour est restauré.
/// C'est le même mécanisme que les relances (« Toujours pas fait ? »),
/// [followUpDelayMinutes] après le rappel, lui aussi one-shot.
///
/// Les notifications locales ne peuvent pas vérifier l'état au moment de se
/// déclencher : cette replanification systématique est la façon fiable
/// d'obtenir un comportement « seulement si pas encore fait » sans tâche de
/// fond ni WorkManager.
class NotificationService {
  static const followUpDelayMinutes = 120;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    // Indispensable : sans `setLocalLocation`, `tz.local` vaut UTC et les
    // rappels partiraient décalés du décalage horaire de l'appareil
    // (1-2 h en France). En cas d'échec, on reste sur UTC (dégradé mais
    // fonctionnel) plutôt que de planter l'init.
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Id unique du prochain rappel d'une habitude.
  int _reminderId(String habitId) => '$habitId#next'.hashCode & 0x7fffffff;

  /// Id unique de la prochaine relance d'une habitude.
  int _followUpId(String habitId) => '$habitId#follow-next'.hashCode & 0x7fffffff;

  /// Planifie le prochain rappel de [habit] : premier jour actif (tous si
  /// `activeWeekdays` est vide) où l'heure de rappel est à venir.
  ///
  /// [skipToday] cale la recherche à partir de demain : utilisé quand
  /// l'habitude est déjà cochée aujourd'hui, pour ne jamais sonner sur un
  /// jour déjà fait.
  Future<void> scheduleNextReminder(Habit habit, {bool skipToday = false}) async {
    await cancelReminders(habit.id);
    final minutes = habit.reminderMinutes;
    if (minutes == null) return;

    final when = _nextOccurrence(habit, minutes, skipToday: skipToday);
    if (when == null) return;

    await init();
    await _plugin.zonedSchedule(
      _reminderId(habit.id),
      habit.name,
      habit.emoji,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Rappels d\'habitudes',
          channelDescription: 'Rappels quotidiens pour vos habitudes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // Pas de matchDateTimeComponents : volontairement ONE-SHOT, le
      // suivant sera replanifié par l'app au bon moment.
    );
  }

  /// Planifie la prochaine relance ([followUpDelayMinutes] après l'heure de
  /// rappel). Rien à faire si l'habitude n'a pas de rappel ou si le créneau
  /// déborderait sur le lendemain.
  ///
  /// [skipToday] fonctionne comme dans [scheduleNextReminder].
  Future<void> scheduleFollowUp(Habit habit, {bool skipToday = false}) async {
    await cancelFollowUps(habit.id);
    final reminderMinutes = habit.reminderMinutes;
    if (reminderMinutes == null) return;
    final followUpMinutes = reminderMinutes + followUpDelayMinutes;
    if (followUpMinutes >= 24 * 60) return;

    final when = _nextOccurrence(habit, followUpMinutes, skipToday: skipToday);
    if (when == null) return;

    await init();
    await _plugin.zonedSchedule(
      _followUpId(habit.id),
      habit.name,
      _followUpBody,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_followups',
          'Relances d\'habitudes',
          channelDescription: 'Relance si une habitude n\'est pas encore faite',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Prochaine date/heure valide pour [habit] : premier jour où l'habitude
  /// est « à faire » et dont l'horaire [minutesSinceMidnight] est encore à
  /// venir (retourne `null` après avoir balayé 7 jours).
  ///
  /// « À faire » selon le mode :
  ///   - objectif hebdo : tout jour de la semaine dont l'objectif n'est pas
  ///     déjà atteint (une semaine pleine ne génère plus de rappels) ;
  ///   - jours fixes : les jours cochés dans `activeWeekdays` (tous si vide).
  tz.TZDateTime? _nextOccurrence(
    Habit habit,
    int minutesSinceMidnight, {
    bool skipToday = false,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var day = skipToday ? now.add(const Duration(days: 1)) : now;
    for (var i = 0; i < 8; i++) {
      final isDue = habit.isFlexible
          ? !habit.weekGoalReached(day)
          : habit.isActiveOn(day);
      if (isDue) {
        final scheduled = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          minutesSinceMidnight ~/ 60,
          minutesSinceMidnight % 60,
        );
        if (scheduled.isAfter(now)) return scheduled;
      }
      day = day.add(const Duration(days: 1));
    }
    return null;
  }

  /// Annule le rappel programmé, ainsi que ceux des anciennes versions qui
  /// programmaient un id par jour de semaine (migration silencieuse).
  Future<void> cancelReminders(String habitId) async {
    await init();
    await _plugin.cancel(_reminderId(habitId));
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel('$habitId#$weekday'.hashCode & 0x7fffffff);
    }
  }

  /// Annule la relance programmée (+ ids hérités des anciennes versions).
  Future<void> cancelFollowUps(String habitId) async {
    await init();
    await _plugin.cancel(_followUpId(habitId));
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel('$habitId#follow#$weekday'.hashCode & 0x7fffffff);
    }
  }

  /// Texte de la relance selon la langue de l'appareil. Indépendant du
  /// [LocaleProvider] (sélecteur de langue in-app) car ce service n'a pas
  /// accès au `BuildContext` : léger décalage possible si l'utilisateur a
  /// forcé une langue différente de celle de son appareil.
  String get _followUpBody {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return code == 'fr' ? "Toujours pas fait aujourd'hui 👀" : 'Still not done today 👀';
  }
}
