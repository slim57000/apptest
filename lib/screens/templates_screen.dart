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
                Text(pack.title, style: Theme.of(context).textTheme.titleMedium),
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
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _add(context),
        ),
        onTap: () => _add(context),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
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
      activeWeekdays: template.activeWeekdays,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.habitAdded)),
      );
    }
  }
}
