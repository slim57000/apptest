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

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.createdAt,
    this.activeWeekdays = const {},
    this.completedDates = const {},
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

  /// Nombre de jours actifs consécutifs complétés, en remontant depuis
  /// aujourd'hui. Aujourd'hui non complété ne casse pas la série (l'
  /// utilisateur a jusqu'à la fin de la journée), mais ne compte pas non
  /// plus tant qu'il n'est pas coché.
  int get currentStreak {
    int streak = 0;
    DateTime cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    bool isFirstDay = true;
    while (!cursor.isBefore(_createdDay)) {
      if (isActiveOn(cursor)) {
        if (isCompletedOn(cursor)) {
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

  /// Plus longue série de jours actifs complétés depuis la création.
  int get longestStreak {
    int longest = 0;
    int running = 0;
    DateTime cursor = _createdDay;
    final today = DateTime.now();
    final endDay = DateTime(today.year, today.month, today.day);
    while (!cursor.isAfter(endDay)) {
      if (isActiveOn(cursor)) {
        if (isCompletedOn(cursor)) {
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
  /// actifs uniquement).
  double completionRate(int days) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
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
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      completedDates: completedDates ?? this.completedDates,
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
    };
  }
}
