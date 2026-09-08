import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';
import '../providers/premium_provider.dart';
import '../services/health_service.dart';
import '../widgets/habit_heatmap.dart';
import 'add_habit_screen.dart';
import 'paywall_screen.dart';
import 'share_card_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late final ConfettiController _confetti;
  int _lastSeenStreak = 0;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final habitsProvider = context.watch<HabitsProvider>();
    final premium = context.watch<PremiumProvider>();
    final habit = habitsProvider.habits
        .where((h) => h.id == widget.habitId)
        .firstOrNull;

    if (habit == null) {
      return Scaffold(body: Center(child: Text(l10n.habitNotFound)));
    }

    final streak = habit.currentStreakCount;
    if (streak > _lastSeenStreak && streak > 0 && habit.reachedMilestone(streak)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
    _lastSeenStreak = streak;

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editHabit,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddHabitScreen(existing: habit)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.shareStreakTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ShareCardScreen(habit: habit)),
            ),
          ),
          IconButton(
            icon: Icon(habit.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
            tooltip: habit.archived ? l10n.unarchiveAction : l10n.archiveAction,
            onPressed: () => _toggleArchived(context, habit),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, habit),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    Text(habit.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      habit.streakUnitIsWeeks
                          ? l10n.streakWeeks(habit.currentStreakCount)
                          : l10n.streakDays(habit.currentStreakCount),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.bestStreak} · ${habit.streakUnitIsWeeks ? l10n.shortWeeks(habit.longestStreakCount) : l10n.shortDays(habit.longestStreakCount)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: habit.isActiveOn(DateTime.now())
                          ? () => context.read<HabitsProvider>().toggleToday(habit.id)
                          : null,
                      icon: Icon(
                        habit.isCompletedToday
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      label: Text(
                        habit.dailyTarget > 1
                            ? l10n.timesProgress(habit.countToday, habit.dailyTarget)
                            : habit.isCompletedToday
                                ? l10n.doneToday
                                : l10n.markDone,
                      ),
                    ),
                  ),
                  if (habit.dailyTarget > 1 && habit.countToday > 0) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      icon: const Icon(Icons.remove),
                      tooltip: l10n.undo,
                      onPressed: () => context.read<HabitsProvider>().decrementToday(habit.id),
                    ),
                  ],
                ],
              ),
              if (habit.canFreezeYesterday(isPremium: premium.isPremium)) ...[
                const SizedBox(height: 12),
                _StreakFreezeBanner(habit: habit),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ReminderTile(habit: habit)),
                  const SizedBox(width: 12),
                  Expanded(child: _JournalTile(habit: habit)),
                ],
              ),
              if (premium.isPremium) ...[
                const SizedBox(height: 16),
                _HealthTrackingTile(habit: habit),
              ],
              const SizedBox(height: 32),
              _StatsSection(habit: habit, isPremium: premium.isPremium),
            ],
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 24,
            shouldLoop: false,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Habit habit) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteHabitTitle),
        content: Text(l10n.deleteHabitContent(habit.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<HabitsProvider>().deleteHabit(habit.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _toggleArchived(BuildContext context, Habit habit) async {
    final l10n = AppLocalizations.of(context)!;
    final habitsProvider = context.read<HabitsProvider>();
    final newValue = !habit.archived;
    await habitsProvider.setArchived(habit.id, newValue);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newValue ? l10n.habitArchivedMessage : l10n.habitUnarchivedMessage),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => habitsProvider.setArchived(habit.id, !newValue),
        ),
      ),
    );
  }
}

class _StreakFreezeBanner extends StatelessWidget {
  final Habit habit;

  const _StreakFreezeBanner({required this.habit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Colors.lightBlue.withValues(alpha: 0.15),
      child: ListTile(
        leading: const Icon(Icons.ac_unit, color: Colors.lightBlue),
        title: Text(l10n.streakFreezeBannerTitle),
        trailing: FilledButton(
          onPressed: () async {
            await context.read<HabitsProvider>().freezeYesterday(habit.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.streakFreezeAppliedMessage)),
              );
            }
          },
          child: Text(l10n.streakFreezeBannerAction),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Habit habit;

  const _ReminderTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final times = habit.reminderTimes;

    return Card(
      child: InkWell(
        onTap: () => _openSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_outlined),
              const SizedBox(height: 6),
              Text(
                times.isEmpty
                    ? l10n.reminderNone
                    : times
                        .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context))
                        .join(', '),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _openSheet(context),
                child: Text(times.isEmpty ? l10n.addReminder : l10n.manageReminders),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RemindersSheet(habitId: habit.id, initialTimes: habit.reminderTimes),
    );
  }
}

/// Feuille de gestion des rappels d'une habitude : ajoute/retire des heures
/// (jusqu'à [Habit.maxReminders]), chaque changement est persisté et
/// replanifié immédiatement via [HabitsProvider.setReminderTimes].
class _RemindersSheet extends StatefulWidget {
  final String habitId;
  final List<int> initialTimes;

  const _RemindersSheet({required this.habitId, required this.initialTimes});

  @override
  State<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<_RemindersSheet> {
  late List<int> _times = List<int>.from(widget.initialTimes)..sort();

  Future<void> _save() =>
      context.read<HabitsProvider>().setReminderTimes(widget.habitId, _times);

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    if (_times.contains(minutes)) return;
    setState(() => _times = (List<int>.from(_times)..add(minutes))..sort());
    await _save();
  }

  Future<void> _removeTime(int minutes) async {
    setState(() => _times = List<int>.from(_times)..remove(minutes));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                l10n.manageReminders,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            if (_times.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.reminderNone,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ..._times.map((minutes) {
                final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
                return ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(time.format(context), textAlign: TextAlign.center),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.removeReminder,
                    onPressed: () => _removeTime(minutes),
                  ),
                );
              }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _times.length >= Habit.maxReminders ? null : _addTime,
                icon: const Icon(Icons.add),
                label: Text(l10n.addReminder),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalTile extends StatelessWidget {
  final Habit habit;

  const _JournalTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final note = habit.noteOn(DateTime.now());

    return Card(
      child: InkWell(
        onTap: () => _editNote(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note),
              const SizedBox(height: 6),
              Text(
                l10n.journalTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              note == null
                  ? TextButton(
                      onPressed: () => _editNote(context),
                      child: Text(l10n.journalEmpty),
                    )
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.read<HabitsProvider>().setNote(
                        habit.id,
                        DateTime.now(),
                        null,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editNote(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: habit.noteOn(DateTime.now()) ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.journalTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(hintText: l10n.journalHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await context.read<HabitsProvider>().setNote(
        habit.id,
        DateTime.now(),
        result,
      );
    }
  }
}

class _HealthTrackingTile extends StatelessWidget {
  final Habit habit;

  const _HealthTrackingTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.directions_walk),
        title: Text(l10n.autoTrackStepsLabel, textAlign: TextAlign.center),
        subtitle: Text(l10n.autoTrackStepsHint(stepsGoalForAutoComplete), textAlign: TextAlign.center),
        value: habit.autoTrackSteps,
        onChanged: (value) async {
          final ok = await context.read<HabitsProvider>().setAutoTrackSteps(habit.id, value);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.autoTrackStepsPermissionDenied)),
            );
          }
        },
      ),
    );
  }
}

/// La série (haut d'écran) et le graphique 7 jours restent gratuits — un
/// aperçu suffisant du payoff motivationnel de l'app pour donner envie de
/// passer Premium. Le taux de complétion 30 jours et l'historique
/// d'activité complet (heatmap) restent, eux, réservés au Premium.
class _StatsSection extends StatelessWidget {
  final Habit habit;
  final bool isPremium;

  const _StatsSection({required this.habit, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            l10n.weeklyCompletionTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(height: 160, child: _WeekChart(habit: habit)),
        const SizedBox(height: 24),
        if (isPremium)
          _PremiumStats(habit: habit)
        else
          _StatsUpsell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
      ],
    );
  }
}

class _PremiumStats extends StatelessWidget {
  final Habit habit;

  const _PremiumStats({required this.habit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rate30 = habit.completionRate(30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: l10n.bestStreak,
                value: habit.streakUnitIsWeeks
                    ? l10n.shortWeeks(habit.longestStreakCount)
                    : l10n.shortDays(habit.longestStreakCount),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: l10n.completionRate30,
                value: '${(rate30 * 100).round()}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Text(
            l10n.activityHeatmapTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 12),
        HabitHeatmap(habit: habit),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer
          .withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(value, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final Habit habit;

  const _WeekChart({required this.habit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];
    final today = DateTime.now();
    final color = Color(habit.colorValue);
    final bars = List.generate(7, (i) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - i));
      final done = habit.isCompletedOn(day);
      final frozen = !done && habit.isFrozenOn(day);
      final barColor = done
          ? color
          : (frozen ? Colors.lightBlue : color.withValues(alpha: 0.15));
      return BarChartGroupData(
        x: day.weekday,
        barRods: [
          BarChartRodData(
            toY: done || frozen ? 1 : 0.08,
            color: barColor,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        maxY: 1,
        barGroups: bars,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(labels[value.toInt() - 1]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsUpsell extends StatelessWidget {
  final VoidCallback onTap;

  const _StatsUpsell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.bar_chart, size: 36, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              l10n.premiumStatsTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.premiumStatsDesc, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onTap, child: Text(l10n.viewSubscription)),
          ],
        ),
      ),
    );
  }
}
