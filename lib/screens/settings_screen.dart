import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habits_provider.dart';
import '../providers/premium_provider.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    final habitsCount = context.watch<HabitsProvider>().habits.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              Icons.workspace_premium,
              color: premium.isPremium ? Colors.amber : null,
            ),
            title: const Text('Abonnement Premium'),
            subtitle: Text(premium.isPremium ? 'Actif' : 'Version gratuite'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Habitudes actives'),
            subtitle: Text(
              premium.isPremium
                  ? '$habitsCount habitude(s)'
                  : '$habitsCount / ${HabitsProvider.freeHabitLimit} habitude(s) (version gratuite)',
            ),
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Habitude+',
            applicationVersion: '1.0.0',
            child: Text('À propos'),
          ),
        ],
      ),
    );
  }
}
