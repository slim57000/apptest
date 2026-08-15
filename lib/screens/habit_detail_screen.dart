import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';
import '../providers/premium_provider.dart';
import 'paywall_screen.dart';

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
    final habit = habitsProvider.habits.where((h) => h.id == widget.habitId).firstOrNull;

    if (habit == null) {
      return Scaffold(body: Center(child: Text(l10n.habitNotFound)));
    }

    if (habit.currentStreak > _lastSeenStreak && habit.currentStreak > 0 && habit.currentStreak % 7 == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
    _lastSeenStreak = habit.currentStreak;

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
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
                      l10n.streakDays(habit.currentStreak),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: habit.isActiveOn(DateTime.now())
                    ? () => context.read<HabitsProvider>().toggleToday(habit.id)
                    : null,
                icon: Icon(habit.isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked),
                label: Text(habit.isCompletedToday ? l10n.doneToday : l10n.markDone),
              ),
              if (premium.isPremium && habit.canFreezeYesterday) ...[
                const SizedBox(height: 12),
                _StreakFreezeBanner(habit: habit),
              ],
              const SizedBox(height: 32),
              if (premium.isPremium)
                _PremiumStats(habit: habit)
              else
                _StatsUpsell(onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    )),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
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
              child: _StatTile(label: l10n.bestStreak, value: '${habit.longestStreak} j'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(label: l10n.completionRate30, value: '${(rate30 * 100).round()}%'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.weeklyCompletionTitle, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SizedBox(height: 160, child: _WeekChart(habit: habit)),
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
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i));
      final done = habit.isCompletedOn(day);
      final frozen = !done && habit.isFrozenOn(day);
      final barColor = done ? color : (frozen ? Colors.lightBlue : color.withValues(alpha: 0.15));
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
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            Text(l10n.premiumStatsTitle, style: Theme.of(context).textTheme.titleMedium),
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
