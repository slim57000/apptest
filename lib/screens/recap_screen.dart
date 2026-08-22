import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';

/// Vue d'ensemble cross-habitudes (Premium) : plus motivant et plus lisible
/// que de naviguer habitude par habitude pour se faire une idée de la
/// semaine.
class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final habits = context.watch<HabitsProvider>().activeHabits;

    if (habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.recapTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.recapNoHabits, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final overallRate = _overallCompletionRate(habits, 7);
    final bestHabit = habits.reduce(
      (a, b) => a.currentStreakCount >= b.currentStreakCount ? a : b,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recapTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _RecapStat(
                  label: l10n.recapOverallRate,
                  value: '${(overallRate * 100).round()}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RecapStat(
                  label: l10n.recapBestHabit,
                  value: bestHabit.streakUnitIsWeeks
                      ? '${bestHabit.emoji} ${l10n.shortWeeks(bestHabit.currentStreakCount)}'
                      : '${bestHabit.emoji} ${bestHabit.currentStreakCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.recapPerHabit, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          ...habits.map((habit) => _HabitRecapTile(habit: habit)),
        ],
      ),
    );
  }

  double _overallCompletionRate(List<Habit> habits, int days) {
    if (habits.isEmpty) return 0;
    final rates = habits.map((h) => h.completionRate(days));
    return rates.reduce((a, b) => a + b) / habits.length;
  }
}

class _RecapStat extends StatelessWidget {
  final String label;
  final String value;

  const _RecapStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _HabitRecapTile extends StatelessWidget {
  final Habit habit;

  const _HabitRecapTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final rate = habit.completionRate(7);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: Text(habit.name, overflow: TextOverflow.ellipsis)),
                Text(
                  habit.streakUnitIsWeeks
                      ? '🔥 ${l10n.shortWeeks(habit.currentStreakCount)}'
                      : '🔥 ${habit.currentStreakCount}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
