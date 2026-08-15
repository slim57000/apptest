import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/habits_provider.dart';
import '../providers/premium_provider.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final premium = context.watch<PremiumProvider>();
    final habitsCount = context.watch<HabitsProvider>().habits.length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              Icons.workspace_premium,
              color: premium.isPremium ? Colors.amber : null,
            ),
            title: Text(l10n.premiumSubscriptionLabel),
            subtitle: Text(premium.isPremium ? l10n.statusActive : l10n.statusFree),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: Text(l10n.activeHabitsLabel),
            subtitle: Text(
              premium.isPremium
                  ? l10n.activeHabitsCountPremium(habitsCount)
                  : l10n.activeHabitsCountFree(habitsCount, HabitsProvider.freeHabitLimit),
            ),
          ),
          const Divider(),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: l10n.appTitle,
            applicationVersion: '1.0.0',
            child: Text(l10n.aboutTitle),
          ),
        ],
      ),
    );
  }
}
