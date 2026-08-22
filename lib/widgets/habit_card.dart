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
}
