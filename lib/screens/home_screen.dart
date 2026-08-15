import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/habits_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/habit_card.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';
import 'paywall_screen.dart';
import 'recap_screen.dart';
import 'settings_screen.dart';
import 'templates_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final habitsProvider = context.watch<HabitsProvider>();
    final premium = context.watch<PremiumProvider>();
    final habits = habitsProvider.habits;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: l10n.chooseTemplate,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TemplatesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: l10n.recapTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => premium.isPremium ? const RecapScreen() : const PaywallScreen(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.workspace_premium,
              color: premium.isPremium ? Colors.amber : null,
            ),
            tooltip: l10n.subscriptionTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: habitsProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : habits.isEmpty
              ? _EmptyState(onAdd: () => _addHabit(context))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: habits.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    return HabitCard(
                      habit: habit,
                      onToggle: () => habitsProvider.toggleToday(habit.id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id)),
                      ),
                    ).animate().fadeIn(delay: (40 * index).ms).slideY(begin: 0.08, end: 0);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addHabit(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newHabit),
      ),
    );
  }

  void _addHabit(BuildContext context) {
    final habitsProvider = context.read<HabitsProvider>();
    final premium = context.read<PremiumProvider>();
    if (!habitsProvider.canAddHabit(premium.isPremium)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddHabitScreen()));
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(l10n.emptyStateTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.emptyStateSubtitle, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.createHabit),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TemplatesScreen()),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.chooseTemplate),
            ),
          ],
        ),
      ),
    );
  }
}
