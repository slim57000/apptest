import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/habits_provider.dart';
import 'habit_detail_screen.dart';

/// Liste des habitudes archivées : sorties du quotidien mais dont
/// l'historique et les séries restent consultables et comptent toujours
/// pour le jardin virtuel.
class ArchivedHabitsScreen extends StatelessWidget {
  const ArchivedHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final archived = context.watch<HabitsProvider>().archivedHabits;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.archivedHabitsTitle)),
      body: archived.isEmpty
          ? Center(child: Text(l10n.noArchivedHabits))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: archived.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final habit = archived[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(habit.colorValue).withValues(alpha: 0.2),
                      child: Text(habit.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(habit.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      tooltip: l10n.unarchiveAction,
                      onPressed: () async {
                        await context.read<HabitsProvider>().setArchived(habit.id, false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.habitUnarchivedMessage)),
                          );
                        }
                      },
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
