import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Planifie des rappels locaux quotidiens pour les habitudes (aucune donnée
/// envoyée à un serveur). Un rappel est reprogrammé chaque jour actif de
/// l'habitude à l'heure choisie.
class NotificationService {
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

  tz.TZDateTime _nextInstanceOfWeekdayAndTime(int weekday, int minutesSinceMidnight) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesSinceMidnight ~/ 60,
      minutesSinceMidnight % 60,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
