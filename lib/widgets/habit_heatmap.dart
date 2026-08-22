import 'package:flutter/material.dart';

import '../models/habit.dart';

/// Grille de complétion façon "GitHub contributions" : une colonne par
/// semaine, un carré par jour, sur les [weeks] dernières semaines. Lecture
/// rapide de la régularité récente d'une habitude.
class HabitHeatmap extends StatelessWidget {
  final Habit habit;
  final int weeks;

  const HabitHeatmap({super.key, required this.habit, this.weeks = 12});

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    // Aligne la fin de grille sur le dimanche de la semaine en cours pour
    // avoir des colonnes complètes (lundi -> dimanche).
    final endOfWeek = todayDay.add(Duration(days: DateTime.sunday - todayDay.weekday));
    final start = endOfWeek.subtract(Duration(days: weeks * 7 - 1));

    final columns = <List<DateTime>>[];
    for (var w = 0; w < weeks; w++) {
      final weekStart = start.add(Duration(days: w * 7));
      columns.add(List.generate(7, (i) => weekStart.add(Duration(days: i))));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Center(
        child: Row(
          children: columns
              .map(
                (week) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: week.map((day) => _cell(context, day, color, todayDay)).toList(),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, DateTime day, Color color, DateTime today) {
    Color cellColor;
    if (day.isAfter(today)) {
      cellColor = Colors.transparent;
    } else if (habit.isCompletedOn(day)) {
      cellColor = color;
    } else if (habit.isFrozenOn(day)) {
      cellColor = Colors.lightBlue;
    } else if (!habit.isActiveOn(day)) {
      cellColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    } else {
      cellColor = color.withValues(alpha: 0.12);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
