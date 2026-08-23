import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/habit_template.dart';
import '../providers/habits_provider.dart';
import '../providers/premium_provider.dart';
import 'paywall_screen.dart';

/// Liste de modèles d'habitudes prêts à l'emploi, groupés par thème.
/// Ajout en un tap : évite la page blanche du premier lancement.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final packs = buildTemplatePacks(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.templatesTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          final pack = packs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    pack.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                ...pack.templates.map((template) => _TemplateTile(template: template)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final HabitTemplate template;

  const _TemplateTile({required this.template});

  @override
  Widget build(BuildContext context) {
    final color = Color(template.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(template.emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(template.name, textAlign: TextAlign.center),
        // Deux actions visibles côte à côte, plutôt qu'un comportement
        // caché derrière le tap de la ligne : on voit tout de suite qu'on
        // peut soit ajouter direct, soit personnaliser les jours d'abord.
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              tooltip: AppLocalizations.of(context)!.activeDaysLabel,
              onPressed: () => _customize(context),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: AppLocalizations.of(context)!.habitAdded,
              onPressed: () => _add(context, template.activeWeekdays),
            ),
          ],
        ),
        onTap: () => _add(context, template.activeWeekdays),
      ),
    );
  }

  Future<void> _customize(BuildContext context) async {
    final chosen = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ScheduleSheet(
        template: template,
        initialWeekdays: template.activeWeekdays,
      ),
    );
    if (chosen != null && context.mounted) {
      await _add(context, chosen);
    }
  }

  Future<void> _add(BuildContext context, Set<int> activeWeekdays) async {
    final l10n = AppLocalizations.of(context)!;
    final habitsProvider = context.read<HabitsProvider>();
    final premium = context.read<PremiumProvider>();

    if (!habitsProvider.canAddHabit(premium.isPremium)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }

    await habitsProvider.addHabit(
      name: template.name,
      emoji: template.emoji,
      colorValue: template.colorValue,
      activeWeekdays: activeWeekdays,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.habitAdded)),
      );
    }
  }
}

/// Feuille modale pour choisir les jours actifs avant d'ajouter une
/// habitude depuis un modèle, au lieu de prendre la planification par
/// défaut du modèle sans pouvoir la changer.
class _ScheduleSheet extends StatefulWidget {
  final HabitTemplate template;
  final Set<int> initialWeekdays;

  const _ScheduleSheet({required this.template, required this.initialWeekdays});

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late final Set<int> _weekdays = Set<int>.from(widget.initialWeekdays);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekdayLabels = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.template.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(l10n.activeDaysLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.activeDaysHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final selected = _weekdays.contains(weekday);
                return FilterChip(
                  label: Text(weekdayLabels[index]),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _weekdays.add(weekday);
                    } else {
                      _weekdays.remove(weekday);
                    }
                  }),
                );
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_weekdays),
                child: Text(l10n.createButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
