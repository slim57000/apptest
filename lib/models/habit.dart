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

  /// Nombre de fois par jour où l'habitude doit être faite pour compter
  /// comme complétée (ex. "boire de l'eau" x8). 1 = comportement classique
  /// (une case à cocher par jour).
  final int dailyTarget;

  /// Nombre de fois faite, par jour (`yyyy-MM-dd` -> compteur). Un jour est
  /// considéré complété quand son compteur atteint [dailyTarget].
  final Map<String, int> completionCounts;

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

  /// Complétion automatique (Premium) via Health Connect / Apple Health :
  /// si le nombre de pas du jour dépasse [stepsGoalForAutoComplete],
  /// l'habitude est cochée automatiquement.
  final bool autoTrackSteps;

  /// Habitude archivée : sortie de la liste principale et du décompte du
  /// quota gratuit, mais historique et séries conservés (contrairement à
  /// une suppression).
  final bool archived;

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.createdAt,
    this.activeWeekdays = const {},
    this.dailyTarget = 1,
    this.completionCounts = const {},
    this.frozenDates = const {},
    this.reminderMinutes,
    this.autoTrackSteps = false,
    this.notes = const {},
    this.archived = false,
  });

  static String dateKey(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool isActiveOn(DateTime day) =>
      activeWeekdays.isEmpty || activeWeekdays.contains(day.weekday);

  /// Nombre de fois faite le jour [day] (0 si jamais touché).
  int countOn(DateTime day) => completionCounts[dateKey(day)] ?? 0;

  bool isCompletedOn(DateTime day) => countOn(day) >= dailyTarget;

  bool isFrozenOn(DateTime day) => frozenDates.contains(dateKey(day));

  String? noteOn(DateTime day) => notes[dateKey(day)];

  /// Un jour "protège" la série s'il a été fait ou geler.
  bool _isStreakSafeOn(DateTime day) => isCompletedOn(day) || isFrozenOn(day);

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  int get countToday => countOn(DateTime.now());

  /// Nombre de jours où l'habitude a été entièrement complétée (compteur
  /// >= [dailyTarget]), tous historiques confondus. Utilisé par le jardin
  /// virtuel : chaque jour pleinement réussi compte pour une "graine",
  /// jamais les passages intermédiaires d'une habitude x plusieurs fois/jour.
  int get completedDayCount =>
      completionCounts.values.where((count) => count >= dailyTarget).length;

  /// Fait avancer le compteur du jour d'un cran, en bouclant à 0 une fois
  /// [dailyTarget] atteint (ex. 0/1 -> 1/1 -> 0/1 pour une habitude simple ;
  /// 0/3 -> 1/3 -> 2/3 -> 3/3 -> 0/3 pour une habitude x3/jour).
  Habit toggled(DateTime day) {
    final key = dateKey(day);
    final current = completionCounts[key] ?? 0;
    final next = current >= dailyTarget ? 0 : current + 1;
    final updated = Map<String, int>.from(completionCounts);
    if (next == 0) {
      updated.remove(key);
    } else {
      updated[key] = next;
    }
    return copyWith(completionCounts: updated);
  }

  /// Retire un cran au compteur du jour, sans jamais descendre sous 0.
  /// Permet de corriger un tap de trop sur une habitude x plusieurs fois/jour.
  Habit decremented(DateTime day) {
    final key = dateKey(day);
    final current = completionCounts[key] ?? 0;
    if (current <= 0) return this;
    final updated = Map<String, int>.from(completionCounts);
    if (current - 1 <= 0) {
      updated.remove(key);
    } else {
      updated[key] = current - 1;
    }
    return copyWith(completionCounts: updated);
  }

  /// Marque [day] comme entièrement fait si ce n'est pas déjà le cas ; ne le
  /// décoche jamais (contrairement à [toggled]). Utilisé par la complétion
  /// automatique via Health Connect / Apple Health, où appeler la
  /// synchronisation plusieurs fois ne doit jamais annuler une complétion.
  Habit completeOn(DateTime day) {
    if (isCompletedOn(day)) return this;
    final updated = Map<String, int>.from(completionCounts)
      ..[dateKey(day)] = dailyTarget;
    return copyWith(completionCounts: updated);
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
      dailyTarget: dailyTarget,
      completionCounts: completionCounts,
      frozenDates: frozenDates,
      reminderMinutes: reminderMinutes,
      autoTrackSteps: autoTrackSteps,
      notes: notes,
      archived: archived,
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
      dailyTarget: dailyTarget,
      completionCounts: completionCounts,
      frozenDates: frozenDates,
      reminderMinutes: reminderMinutes,
      autoTrackSteps: autoTrackSteps,
      notes: updated,
      archived: archived,
    );
  }

  /// Active/désactive la complétion automatique via les pas de santé.
  Habit withAutoTrackSteps(bool value) {
    return Habit(
      id: id,
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: createdAt,
      activeWeekdays: activeWeekdays,
      dailyTarget: dailyTarget,
      completionCounts: completionCounts,
      frozenDates: frozenDates,
      reminderMinutes: reminderMinutes,
      autoTrackSteps: value,
      notes: notes,
      archived: archived,
    );
  }

  /// Archive ou désarchive l'habitude : sortie/retour de la liste
  /// principale, sans jamais toucher à l'historique ni aux séries.
  Habit withArchived(bool value) {
    return Habit(
      id: id,
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: createdAt,
      activeWeekdays: activeWeekdays,
      dailyTarget: dailyTarget,
      completionCounts: completionCounts,
      frozenDates: frozenDates,
      reminderMinutes: reminderMinutes,
      autoTrackSteps: autoTrackSteps,
      notes: notes,
      archived: value,
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
    int? dailyTarget,
    Map<String, int>? completionCounts,
    Set<String>? frozenDates,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      completionCounts: completionCounts ?? this.completionCounts,
      frozenDates: frozenDates ?? this.frozenDates,
      reminderMinutes: reminderMinutes,
      autoTrackSteps: autoTrackSteps,
      notes: notes,
      archived: archived,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    // Compatibilité ascendante : les sauvegardes créées avant l'ajout des
    // habitudes "plusieurs fois par jour" stockent `completedDates` (une
    // liste de jours faits une fois). On les relit comme un compteur à 1.
    final Map<String, int> completionCounts;
    if (json['completionCounts'] != null) {
      completionCounts = (json['completionCounts'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toInt()));
    } else {
      completionCounts = {
        for (final date in (json['completedDates'] as List<dynamic>? ?? []))
          date as String: 1,
      };
    }

    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      colorValue: json['colorValue'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      activeWeekdays: (json['activeWeekdays'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toSet(),
      dailyTarget: (json['dailyTarget'] as num?)?.toInt() ?? 1,
      completionCounts: completionCounts,
      frozenDates: (json['frozenDates'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toSet(),
      reminderMinutes: json['reminderMinutes'] as int?,
      autoTrackSteps: json['autoTrackSteps'] as bool? ?? false,
      notes: (json['notes'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as String)),
      archived: json['archived'] as bool? ?? false,
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
      'dailyTarget': dailyTarget,
      'completionCounts': completionCounts,
      'frozenDates': frozenDates.toList(),
      'reminderMinutes': reminderMinutes,
      'autoTrackSteps': autoTrackSteps,
      'notes': notes,
      'archived': archived,
    };
  }
}
