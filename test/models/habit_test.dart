import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';

/// Aujourd'hui à minuit, pour construire des dates relatives fiables sans
/// dépendre de l'heure à laquelle les tests tournent.
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _daysAgo(int n) => _today().subtract(Duration(days: n));

Habit _habit({
  Set<int> activeWeekdays = const {},
  Set<String> completedDates = const {},
  int dailyTarget = 1,
  Set<String> frozenDates = const {},
  DateTime? createdAt,
  int? reminderMinutes,
  bool autoTrackSteps = false,
  bool archived = false,
  Map<String, String> notes = const {},
}) {
  return Habit(
    id: 'h1',
    name: 'Test',
    emoji: '🔥',
    colorValue: 0xFF000000,
    createdAt: createdAt ?? _daysAgo(365),
    activeWeekdays: activeWeekdays,
    dailyTarget: dailyTarget,
    completionCounts: {for (final d in completedDates) d: dailyTarget},
    frozenDates: frozenDates,
    reminderMinutes: reminderMinutes,
    autoTrackSteps: autoTrackSteps,
    archived: archived,
    notes: notes,
  );
}

void main() {
  group('dateKey', () {
    test('formate en yyyy-MM-dd avec zero-padding', () {
      expect(Habit.dateKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(Habit.dateKey(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('isActiveOn', () {
    test('jours actifs vides = actif tous les jours', () {
      final habit = _habit();
      for (var i = 0; i < 7; i++) {
        expect(habit.isActiveOn(_daysAgo(i)), isTrue);
      }
    });

    test('respecte les jours actifs choisis', () {
      final monday = DateTime(2026, 8, 17); // lundi
      final tuesday = DateTime(2026, 8, 18);
      final habit = _habit(activeWeekdays: {DateTime.monday});
      expect(habit.isActiveOn(monday), isTrue);
      expect(habit.isActiveOn(tuesday), isFalse);
    });
  });

  group('toggled / completeOn', () {
    test('toggled ajoute puis retire le jour (habitude simple)', () {
      final habit = _habit();
      final toggled = habit.toggled(_today());
      expect(toggled.isCompletedOn(_today()), isTrue);
      final untoggled = toggled.toggled(_today());
      expect(untoggled.isCompletedOn(_today()), isFalse);
    });

    test('completeOn est idempotent et ne décoche jamais', () {
      final habit = _habit();
      final completed = habit.completeOn(_today());
      expect(completed.isCompletedOn(_today()), isTrue);
      final completedAgain = completed.completeOn(_today());
      expect(completedAgain.isCompletedOn(_today()), isTrue);
      expect(completedAgain.completionCounts, completed.completionCounts);
    });
  });

  group('habitudes plusieurs fois par jour', () {
    test('toggled boucle 0 -> 1 -> 2 -> ... -> target -> 0', () {
      var habit = _habit(dailyTarget: 3);
      expect(habit.countToday, 0);
      expect(habit.isCompletedOn(_today()), isFalse);

      habit = habit.toggled(_today());
      expect(habit.countToday, 1);
      expect(habit.isCompletedOn(_today()), isFalse);

      habit = habit.toggled(_today());
      expect(habit.countToday, 2);

      habit = habit.toggled(_today());
      expect(habit.countToday, 3);
      expect(habit.isCompletedOn(_today()), isTrue);

      habit = habit.toggled(_today());
      expect(habit.countToday, 0);
      expect(habit.isCompletedOn(_today()), isFalse);
    });

    test('decremented retire un cran sans descendre sous 0', () {
      var habit = _habit(dailyTarget: 3).toggled(_today()).toggled(_today());
      expect(habit.countToday, 2);
      habit = habit.decremented(_today());
      expect(habit.countToday, 1);
      habit = habit.decremented(_today()).decremented(_today());
      expect(habit.countToday, 0);
    });

    test('completeOn marque directement le compteur au niveau de la cible', () {
      final habit = _habit(dailyTarget: 5).completeOn(_today());
      expect(habit.countToday, 5);
      expect(habit.isCompletedOn(_today()), isTrue);
    });

    test('completedDayCount ne compte que les jours pleinement atteints', () {
      var habit = _habit(dailyTarget: 3);
      habit = habit.toggled(_today()); // 1/3, pas complet
      expect(habit.completedDayCount, 0);
      habit = habit.toggled(_daysAgo(1)).toggled(_daysAgo(1)).toggled(_daysAgo(1)); // 3/3
      expect(habit.completedDayCount, 1);
    });
  });

  group('currentStreak', () {
    test('0 si rien n\'est complété', () {
      expect(_habit().currentStreak, 0);
    });

    test('aujourd\'hui non complété ne casse pas la série d\'hier', () {
      final habit = _habit(completedDates: {
        Habit.dateKey(_daysAgo(1)),
        Habit.dateKey(_daysAgo(2)),
        Habit.dateKey(_daysAgo(3)),
      });
      expect(habit.currentStreak, 3);
    });

    test('un jour manqué avant hier casse la série', () {
      final habit = _habit(completedDates: {
        Habit.dateKey(_daysAgo(1)),
        // _daysAgo(2) manquant
        Habit.dateKey(_daysAgo(3)),
      });
      expect(habit.currentStreak, 1);
    });

    test('aujourd\'hui complété compte dans la série', () {
      final habit = _habit(completedDates: {
        Habit.dateKey(_today()),
        Habit.dateKey(_daysAgo(1)),
      });
      expect(habit.currentStreak, 2);
    });

    test('un jour gelé compte comme protégé', () {
      final habit = _habit(
        completedDates: {Habit.dateKey(_daysAgo(2))},
        frozenDates: {Habit.dateKey(_daysAgo(1))},
      );
      expect(habit.currentStreak, 2);
    });

    test('ignore les jours inactifs de la semaine (compte en occurrences, pas en jours)', () {
      // Habitude active un seul jour de la semaine (celui d'aujourd'hui) :
      // les 6 autres jours de chaque semaine ne doivent pas casser la série
      // même si non complétés, puisqu'ils ne sont pas actifs.
      final weekday = _today().weekday;
      final habit = _habit(
        activeWeekdays: {weekday},
        completedDates: {
          Habit.dateKey(_today()),
          Habit.dateKey(_today().subtract(const Duration(days: 7))),
          Habit.dateKey(_today().subtract(const Duration(days: 14))),
        },
      );
      expect(habit.currentStreak, 3);
    });
  });

  group('longestStreak', () {
    test('trouve la plus longue série même si elle n\'est pas la dernière', () {
      final habit = _habit(completedDates: {
        Habit.dateKey(_daysAgo(10)),
        Habit.dateKey(_daysAgo(9)),
        Habit.dateKey(_daysAgo(8)),
        Habit.dateKey(_daysAgo(7)),
        // trou
        Habit.dateKey(_daysAgo(2)),
        Habit.dateKey(_daysAgo(1)),
      });
      expect(habit.longestStreak, 4);
    });
  });

  group('canFreezeYesterday / freezeYesterday', () {
    test('vrai si hier était actif et manqué', () {
      final habit = _habit();
      expect(habit.canFreezeYesterday, isTrue);
    });

    test('faux si hier a déjà été complété', () {
      final habit = _habit(completedDates: {Habit.dateKey(_daysAgo(1))});
      expect(habit.canFreezeYesterday, isFalse);
    });

    test('faux si hier est avant la création de l\'habitude', () {
      final habit = _habit(createdAt: _today());
      expect(habit.canFreezeYesterday, isFalse);
    });

    test('faux en période de recharge après un gel récent', () {
      final habit = _habit(frozenDates: {Habit.dateKey(_daysAgo(3))});
      expect(habit.canFreezeYesterday, isFalse);
    });

    test('freezeYesterday marque bien hier comme gelé', () {
      final habit = _habit();
      final frozen = habit.freezeYesterday();
      expect(frozen.isFrozenOn(_daysAgo(1)), isTrue);
    });
  });

  group('completionRate', () {
    test('0 sans jours actifs', () {
      final habit = _habit(createdAt: _today());
      expect(habit.completionRate(30), 0);
    });

    test('calcule le ratio sur les jours actifs uniquement', () {
      final habit = _habit(completedDates: {
        Habit.dateKey(_today()),
        Habit.dateKey(_daysAgo(1)),
      });
      expect(habit.completionRate(4), 0.5);
    });
  });

  group('copyWith', () {
    test('préserve les champs non explicitement copiés (regression)', () {
      // Ce test aurait échoué avant la correction du bug où copyWith()
      // oubliait reminderMinutes/notes/autoTrackSteps, les réinitialisant
      // silencieusement à chaque toggled()/freezeYesterday().
      final habit = _habit(
        reminderMinutes: 480,
        autoTrackSteps: true,
        notes: {Habit.dateKey(_today()): 'une note'},
      );
      final copy = habit.copyWith(name: 'Nouveau nom');
      expect(copy.reminderMinutes, 480);
      expect(copy.autoTrackSteps, isTrue);
      expect(copy.notes, {Habit.dateKey(_today()): 'une note'});
      expect(copy.name, 'Nouveau nom');
    });

    test('toggled/freezeYesterday préservent reminderMinutes/notes/autoTrackSteps', () {
      final habit = _habit(reminderMinutes: 600, autoTrackSteps: true);
      expect(habit.toggled(_today()).reminderMinutes, 600);
      expect(habit.toggled(_today()).autoTrackSteps, isTrue);
      expect(habit.freezeYesterday().reminderMinutes, 600);
    });
  });

  group('withReminder / withNote / withAutoTrackSteps / withArchived', () {
    test('withReminder peut repasser à null explicitement', () {
      final habit = _habit(reminderMinutes: 480);
      expect(habit.withReminder(null).reminderMinutes, isNull);
      expect(habit.withReminder(600).reminderMinutes, 600);
    });

    test('withNote ajoute, met à jour, et retire (texte vide ou null)', () {
      final habit = _habit();
      final withNote = habit.withNote(_today(), '  belle journée  ');
      expect(withNote.noteOn(_today()), 'belle journée');
      final cleared = withNote.withNote(_today(), '');
      expect(cleared.noteOn(_today()), isNull);
      final noted = habit.withNote(_today(), 'x').withNote(_today(), null);
      expect(noted.noteOn(_today()), isNull);
    });

    test('withAutoTrackSteps bascule le suivi automatique', () {
      final habit = _habit();
      expect(habit.withAutoTrackSteps(true).autoTrackSteps, isTrue);
    });

    test('withArchived bascule le statut archivé sans toucher à l\'historique', () {
      final habit = _habit(completedDates: {Habit.dateKey(_today())});
      final archived = habit.withArchived(true);
      expect(archived.archived, isTrue);
      expect(archived.isCompletedOn(_today()), isTrue);
      expect(archived.withArchived(false).archived, isFalse);
    });
  });

  group('toJson / fromJson', () {
    test('round-trip préserve toutes les données', () {
      final habit = _habit(
        activeWeekdays: {1, 3, 5},
        dailyTarget: 3,
        completedDates: {Habit.dateKey(_today())},
        frozenDates: {Habit.dateKey(_daysAgo(5))},
        reminderMinutes: 510,
        autoTrackSteps: true,
        archived: true,
        notes: {Habit.dateKey(_today()): 'journal'},
      );
      final restored = Habit.fromJson(habit.toJson());

      expect(restored.id, habit.id);
      expect(restored.name, habit.name);
      expect(restored.emoji, habit.emoji);
      expect(restored.colorValue, habit.colorValue);
      expect(restored.createdAt, habit.createdAt);
      expect(restored.activeWeekdays, habit.activeWeekdays);
      expect(restored.dailyTarget, habit.dailyTarget);
      expect(restored.completionCounts, habit.completionCounts);
      expect(restored.frozenDates, habit.frozenDates);
      expect(restored.reminderMinutes, habit.reminderMinutes);
      expect(restored.autoTrackSteps, habit.autoTrackSteps);
      expect(restored.archived, habit.archived);
      expect(restored.notes, habit.notes);
    });

    test('fromJson applique les valeurs par défaut sur les champs absents', () {
      final restored = Habit.fromJson({
        'id': 'h1',
        'name': 'Minimal',
        'emoji': '🔥',
        'colorValue': 0xFF000000,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(restored.activeWeekdays, isEmpty);
      expect(restored.dailyTarget, 1);
      expect(restored.completionCounts, isEmpty);
      expect(restored.frozenDates, isEmpty);
      expect(restored.reminderMinutes, isNull);
      expect(restored.autoTrackSteps, isFalse);
      expect(restored.archived, isFalse);
      expect(restored.notes, isEmpty);
    });

    test('fromJson relit une ancienne sauvegarde `completedDates` comme un compteur à 1', () {
      final restored = Habit.fromJson({
        'id': 'h1',
        'name': 'Ancienne sauvegarde',
        'emoji': '🔥',
        'colorValue': 0xFF000000,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'completedDates': [Habit.dateKey(_today())],
      });
      expect(restored.dailyTarget, 1);
      expect(restored.isCompletedOn(_today()), isTrue);
      expect(restored.completionCounts[Habit.dateKey(_today())], 1);
    });
  });
}
