import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Planifie des rappels locaux quotidiens pour les habitudes (aucune donnée
/// envoyée à un serveur). Un rappel est reprogrammé chaque jour actif de
/// l'habitude à l'heure choisie.
///
/// En plus du rappel initial, une "relance" est planifiée
/// [followUpDelayMinutes] plus tard le même jour, et annulée/reprogrammée
/// pour la semaine suivante dès que l'habitude est cochée (voir
/// `HabitsProvider`, qui appelle [scheduleFollowUp] avec `skipToday: true`
/// juste après une complétion). Comme les notifications locales ne peuvent
/// pas vérifier l'état de l'app au moment où elles se déclenchent, ce
/// mécanisme d'annulation-au-moment-de-la-complétion est la seule façon
/// fiable d'obtenir une relance "seulement si pas encore fait" sans
/// serveur ni tâche de fond.
class NotificationService {
  static const followUpDelayMinutes = 120;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

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

  /// Un id de notification stable par (habitude, jour de semaine), pour
  /// planifier/annuler indépendamment le rappel de chaque jour actif.
  int _notificationId(String habitId, int weekday) => '$habitId#$weekday'.hashCode & 0x7fffffff;

  Future<void> scheduleReminders(Habit habit) async {
    await cancelReminders(habit.id);
    final minutes = habit.reminderMinutes;
    if (minutes == null) return;

    await init();

    final weekdays = habit.activeWeekdays.isEmpty
        ? const [1, 2, 3, 4, 5, 6, 7]
        : habit.activeWeekdays;

    for (final weekday in weekdays) {
      await _plugin.zonedSchedule(
        _notificationId(habit.id, weekday),
        habit.name,
        habit.emoji,
        _nextInstanceOfWeekdayAndTime(weekday, minutes),
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
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelReminders(String habitId) async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_notificationId(habitId, weekday));
    }
  }

  /// Id de notification distinct de [_notificationId] pour que la relance
  /// puisse être annulée/reprogrammée indépendamment du rappel initial.
  int _followUpId(String habitId, int weekday) => '$habitId#follow#$weekday'.hashCode & 0x7fffffff;

  /// Planifie la relance d'une habitude, [followUpDelayMinutes] après son
  /// rappel. Pas de relance si l'habitude n'a pas de rappel, ou si le délai
  /// déborderait sur le lendemain (heure de rappel trop tardive).
  ///
  /// [skipToday] force le prochain déclenchement à partir de demain :
  /// utilisé quand on reprogramme juste après avoir coché l'habitude, pour
  /// ne pas relancer sur un jour déjà fait.
  Future<void> scheduleFollowUp(Habit habit, {bool skipToday = false}) async {
    await cancelFollowUps(habit.id);
    final reminderMinutes = habit.reminderMinutes;
    if (reminderMinutes == null) return;
    final followUpMinutes = reminderMinutes + followUpDelayMinutes;
    if (followUpMinutes >= 24 * 60) return;

    await init();

    final weekdays = habit.activeWeekdays.isEmpty
        ? const [1, 2, 3, 4, 5, 6, 7]
        : habit.activeWeekdays;

    for (final weekday in weekdays) {
      await _plugin.zonedSchedule(
        _followUpId(habit.id, weekday),
        habit.name,
        _followUpBody,
        _nextInstanceOfWeekdayAndTime(weekday, followUpMinutes, skipToday: skipToday),
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
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelFollowUps(String habitId) async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_followUpId(habitId, weekday));
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

  tz.TZDateTime _nextInstanceOfWeekdayAndTime(
    int weekday,
    int minutesSinceMidnight, {
    bool skipToday = false,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final earliest = skipToday ? now.add(const Duration(days: 1)) : now;
    var scheduled = tz.TZDateTime(
      tz.local,
      earliest.year,
      earliest.month,
      earliest.day,
      minutesSinceMidnight ~/ 60,
      minutesSinceMidnight % 60,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
