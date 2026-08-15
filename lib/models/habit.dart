/// Une habitude suivie par l'utilisateur : nom, jours actifs dans la
/// semaine (vide = tous les jours) et historique des jours complétés.
/// Sérialisée en JSON brut (pas de backend, stockage local uniquement).
class Habit {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final DateTime createdAt;

  /// Jours de la semaine où l'habitude est active (1 = lundi … 7 =
  /// dimanche). Vide = active tous les jours.
  final Set<int> activeWeekdays;

  /// Dates complétées, au format `yyyy-MM-dd`.
  final Set<String> completedDates;

  /// Dates "gelées" (fonctionnalité Premium) : un jour manqué qui ne casse
  /// pas la série, sans compter comme réellement fait dans le taux de
  /// complétion.
  final Set<String> frozenDates;

  /// Heure de rappel quotidien, en minutes depuis minuit (ex. 510 = 8h30).
  /// `null` = pas de rappel programmé.
  final int? reminderMinutes;

  /// Notes de journal par jour (`yyyy-MM-dd` -> texte), optionnelles :
  /// réflexion libre sur pourquoi un jour a été réussi/manqué.
  final Map<String, String> notes;

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.createdAt,
    this.activeWeekdays = const {},
    this.completedDates = const {},
    this.frozenDates = const {},
    this.reminderMinutes,
    this.notes = const {},
  });

  static String dateKey(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool isActiveOn(DateTime day) =>
      activeWeekdays.isEmpty || activeWeekdays.contains(day.weekday);

  bool isCompletedOn(DateTime day) => completedDates.contains(dateKey(day));

  bool isFrozenOn(DateTime day) => frozenDates.contains(dateKey(day));

  String? noteOn(DateTime day) => notes[dateKey(day)];

  /// Un jour "protège" la série s'il a été fait ou geler.
  bool _isStreakSafeOn(DateTime day) => isCompletedOn(day) || isFrozenOn(day);

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  Habit toggled(DateTime day) {
    final key = dateKey(day);
    final updated = Set<String>.from(completedDates);
    if (!updated.remove(key)) {
      updated.add(key);
    }
    return copyWith(completedDates: updated);
  }

  DateTime get _createdDay => DateTime(createdAt.year, createdAt.month, createdAt.day);

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Le jour manqué le plus récent pouvant être gelé (hier, s'il était actif
  /// et non complété). Fonctionnalité Premium avec un délai de recharge de
  /// 7 jours entre deux gels pour rester une exception, pas un contournement.
  bool get canFreezeYesterday {
    final yesterday = _today().subtract(const Duration(days: 1));
    if (yesterday.isBefore(_createdDay)) return false;
    if (!isActiveOn(yesterday)) return false;
    if (isCompletedOn(yesterday) || isFrozenOn(yesterday)) return false;

    final cooldownStart = yesterday.subtract(const Duration(days: 6));
    for (final key in frozenDates) {
      final frozenDay = DateTime.parse(key);
      if (!frozenDay.isBefore(cooldownStart) && !frozenDay.isAfter(yesterday)) {
        return false;
      }
    }
    return true;
  }

  Habit freezeYesterday() {
    final yesterday = _today().subtract(const Duration(days: 1));
    final updated = Set<String>.from(frozenDates)..add(dateKey(yesterday));
    return copyWith(frozenDates: updated);
  }

  /// Fixe (ou retire, avec `null`) l'heure de rappel quotidien. Méthode
  /// dédiée plutôt que `copyWith` car ce champ doit pouvoir repasser à
  /// `null` explicitement.
  Habit withReminder(int? reminderMinutes) {
    return Habit(
      id: id,
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: createdAt,
      activeWeekdays: activeWeekdays,
      completedDates: completedDates,
      frozenDates: frozenDates,
      reminderMinutes: reminderMinutes,
      notes: notes,
    );
  }

  /// Fixe (ou retire, avec `null`/vide) la note de journal d'un jour donné.
  Habit withNote(DateTime day, String? note) {
    final updated = Map<String, String>.from(notes);
    final key = dateKey(day);
    if (note == null || note.trim().isEmpty) {
      updated.remove(key);
    } else {
      updated[key] = note.trim();
    }
    return Habit(
      id: id,
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: createdAt,
      activeWeekdays: activeWeekdays,
      completedDates: completedDates,
      frozenDates: frozenDates,
      reminderMinutes: reminderMinutes,
      notes: updated,
    );
  }

  /// Nombre de jours actifs consécutifs complétés (ou gelés), en remontant
  /// depuis aujourd'hui. Aujourd'hui non complété ne casse pas la série
  /// (l'utilisateur a jusqu'à la fin de la journée), mais ne compte pas non
  /// plus tant qu'il n'est pas coché.
  int get currentStreak {
    int streak = 0;
    DateTime cursor = _today();
    bool isFirstDay = true;
    while (!cursor.isBefore(_createdDay)) {
      if (isActiveOn(cursor)) {
        if (_isStreakSafeOn(cursor)) {
          streak++;
        } else if (!isFirstDay) {
          break;
        }
      }
      isFirstDay = false;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Plus longue série de jours actifs complétés (ou gelés) depuis la
  /// création.
  int get longestStreak {
    int longest = 0;
    int running = 0;
    DateTime cursor = _createdDay;
    final endDay = _today();
    while (!cursor.isAfter(endDay)) {
      if (isActiveOn(cursor)) {
        if (_isStreakSafeOn(cursor)) {
          running++;
          if (running > longest) longest = running;
        } else {
          running = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return longest;
  }

  /// Taux de complétion sur les [days] derniers jours (parmi les jours
  /// actifs uniquement). Les jours gelés ne comptent pas comme faits : ce
  /// taux reflète l'adhésion réelle, pas la série protégée.
  double completionRate(int days) {
    final todayDay = _today();
    int activeCount = 0;
    int doneCount = 0;
    for (int i = 0; i < days; i++) {
      final day = todayDay.subtract(Duration(days: i));
      if (day.isBefore(_createdDay)) continue;
      if (isActiveOn(day)) {
        activeCount++;
        if (isCompletedOn(day)) doneCount++;
      }
    }
    if (activeCount == 0) return 0;
    return doneCount / activeCount;
  }

  Habit copyWith({
    String? name,
    String? emoji,
    int? colorValue,
    Set<int>? activeWeekdays,
    Set<String>? completedDates,
    Set<String>? frozenDates,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      completedDates: completedDates ?? this.completedDates,
      frozenDates: frozenDates ?? this.frozenDates,
      reminderMinutes: reminderMinutes,
      notes: notes,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      colorValue: json['colorValue'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      activeWeekdays: (json['activeWeekdays'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toSet(),
      completedDates: (json['completedDates'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toSet(),
      frozenDates: (json['frozenDates'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toSet(),
      reminderMinutes: json['reminderMinutes'] as int?,
      notes: (json['notes'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'activeWeekdays': activeWeekdays.toList(),
      'completedDates': completedDates.toList(),
      'frozenDates': frozenDates.toList(),
      'reminderMinutes': reminderMinutes,
      'notes': notes,
    };
  }
}
