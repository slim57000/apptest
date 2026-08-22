import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/garden_card.dart';
import '../widgets/habit_card.dart';
import '../widgets/milestone_celebration.dart';
import 'add_habit_screen.dart';
import 'archived_habits_screen.dart';
import 'challenges_screen.dart';
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
    // Le jardin grandit avec l'historique complet (habitudes archivées
    // comprises), la liste du quotidien n'affiche que les actives.
    final allHabits = habitsProvider.habits;
    final habits = habitsProvider.activeHabits;

    return Scaffold(
      // En-tête personnalisé : logo au-dessus de la rangée d'icônes
      // centrée (un AppBar classique avec 5 actions tronquait le titre).
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 128,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 26),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      builder: (_) =>
                          premium.isPremium ? const RecapScreen() : const PaywallScreen(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.groups),
                  tooltip: l10n.challengesTitle,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChallengesScreen()),
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
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: l10n.archivedHabitsTitle,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ArchivedHabitsScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: l10n.settingsTitle,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: habitsProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : habits.isEmpty
              ? _EmptyState(onAdd: () => _addHabit(context))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: habits.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                   itemBuilder: (context, index) {
                     if (index == 0) return GardenCard(habits: allHabits);
                     final habit = habits[index - 1];
                     // Glisser vers la gauche = suppression immédiate,
                     // annulable quelques secondes via le snackbar.
                     return Dismissible(
                       key: ValueKey('habit-${habit.id}'),
                       direction: DismissDirection.endToStart,
                       background: Container(
                         alignment: Alignment.centerRight,
                         padding: const EdgeInsets.only(right: 24),
                         decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.error,
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: const Icon(Icons.delete_outline, color: Colors.white),
                       ),
                       onDismissed: (_) {
                         habitsProvider.deleteHabit(habit.id);
                         ScaffoldMessenger.of(context).hideCurrentSnackBar();
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text(l10n.deleteHabitTitle),
                             action: SnackBarAction(
                               label: l10n.cancel,
                               onPressed: () => habitsProvider.restoreHabit(habit),
                             ),
                           ),
                         );
                       },
                        child: HabitCard(
                          habit: habit,
                          onToggle: () => _toggleWithCelebration(context, habitsProvider, habit),
                          onDecrement: () => habitsProvider.decrementToday(habit.id),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id)),
                          ),
                        ),
                     ).animate().fadeIn(delay: (40 * (index - 1)).ms).slideY(begin: 0.08, end: 0);
                   },
                ),
      // Le bouton "Nouvelle habitude" est intégré à l'état vide centré ;
      // le FAB n'a de sens que lorsqu'il existe déjà des habitudes.
      floatingActionButton: habits.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addHabit(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.newHabit),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // Bannière discrète, uniquement pour la version gratuite -- jamais
      // affichée aux utilisateurs Premium.
      bottomNavigationBar: (!kIsWeb && !premium.isPremium) ? const BannerAdWidget() : null,
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

  /// Coche/décoche la journée puis, si la série vient d'atteindre un palier
  /// célébré (7/30/100/365 jours ou 4/12/26/52 semaines), affiche le
  /// dialogue de félicitations avec confettis.
  Future<void> _toggleWithCelebration(
    BuildContext context,
    HabitsProvider habitsProvider,
    Habit habit,
  ) async {
    final before = habit.currentStreakCount;
    await habitsProvider.toggleToday(habit.id);
    if (!context.mounted) return;

    Habit? updated;
    for (final h in habitsProvider.habits) {
      if (h.id == habit.id) {
        updated = h;
        break;
      }
    }
    if (updated == null) return;

    final after = updated.currentStreakCount;
    if (after > before && after > 0 && updated.reachedMilestone(after)) {
      final l10n = AppLocalizations.of(context)!;
      await MilestoneCelebration.show(
        context,
        streakLabel: updated.streakUnitIsWeeks
            ? l10n.streakWeeks(after)
            : l10n.streakDays(after),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Pattern « empty state scrollable centré » : la hauteur minimale
    // garantit un centrage vertical parfait, et la colonne en
    // mainAxisSize.min + crossAxisAlignment.center reste centrée
    // horizontalement quelle que soit la largeur des boutons.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLogo(size: 72, showText: false),
                const SizedBox(height: 20),
                Text(l10n.emptyStateTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(l10n.emptyStateSubtitle,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newHabit),
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
        ),
      ),
    );
  }
}
