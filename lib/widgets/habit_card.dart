import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDecrement;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onTap,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Color(habit.colorValue);
    final done = habit.isCompletedToday;
    final active = habit.isActiveOn(DateTime.now());

    return Card(
      color: color.withValues(alpha: done ? 0.16 : 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Text(habit.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
<<<<<<< Updated upstream
                    if (habit.dailyTarget > 1)
                      Text(
                        l10n.timesProgress(habit.countToday, habit.dailyTarget),
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else if (habit.currentStreak > 0)
                      Text(
                        l10n.streakDays(habit.currentStreak),
                        style: Theme.of(context).textTheme.bodySmall,
                      )
=======
                    const SizedBox(height: 4),
                    if (habit.isFlexible) ...[
                      // Objectif hebdo : anneau linéaire de progression
                      // vers le nombre de jours visés cette semaine.
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value:
                                    (habit.weekProgressDone / habit.weeklyGoal)
                                        .clamp(0.0, 1.0),
                                minHeight: 5,
                                backgroundColor: color.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.weekProgress(habit.weekProgressDone, habit.weeklyGoal),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black87
                                      : color,
                                ),
                          ),
                        ],
                      ),
                      if (habit.currentStreakCount > 1) ...[
                        const SizedBox(height: 6),
                        _streakPill(context, l10n.streakWeeks(habit.currentStreakCount)),
                      ],
                    ] else if (habit.currentStreak > 0)
                      _streakPill(context, l10n.streakDays(habit.currentStreak))
>>>>>>> Stashed changes
                    else
                      Text(
                        active ? l10n.notStartedYet : l10n.notScheduledToday,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onLongPress: (active && onDecrement != null && habit.countToday > 0)
                    ? onDecrement
                    : null,
                child: IconButton(
                  iconSize: 32,
                  onPressed: active ? onToggle : null,
                  icon: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? color : Theme.of(context).disabledColor,
                  ),
                ),
              ).animate(target: done ? 1 : 0).scaleXY(begin: 1, end: 1.15, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  /// Pastille flamme « série en cours » (jours ou semaines selon le mode).
  Widget _streakPill(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEF6C00).withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFEF6C00).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 15, color: Color(0xFFE65100)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFE65100)),
          ),
        ],
      ),
    );
  }
}
