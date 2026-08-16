import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/habits_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/premium_provider.dart';
import 'paywall_screen.dart';

/// `Navigator.pop` avec `null` est indiscernable entre "l'utilisateur a
/// choisi Système" et "fermeture du dialogue sans choix (tap en dehors)" :
/// cette valeur encode explicitement le premier cas.
const _systemLanguageChoice = '__system__';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final premium = context.watch<PremiumProvider>();
    final habitsCount = context.watch<HabitsProvider>().habits.length;
    final locale = context.watch<LocaleProvider>().locale;

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
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.languageLabel),
            subtitle: Text(_languageLabel(l10n, locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, locale),
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

  String _languageLabel(AppLocalizations l10n, Locale? locale) {
    switch (locale?.languageCode) {
      case 'fr':
        return l10n.languageFrench;
      case 'en':
        return l10n.languageEnglish;
      default:
        return l10n.languageSystem;
    }
  }

  Future<void> _pickLanguage(BuildContext context, Locale? current) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.languageLabel),
        children: [
          _LanguageOption(
            label: l10n.languageSystem,
            code: _systemLanguageChoice,
            selected: current == null,
          ),
          _LanguageOption(label: l10n.languageFrench, code: 'fr', selected: current?.languageCode == 'fr'),
          _LanguageOption(label: l10n.languageEnglish, code: 'en', selected: current?.languageCode == 'en'),
        ],
      ),
    );
    if (choice != null && context.mounted) {
      await context.read<LocaleProvider>().setLanguageCode(
            choice == _systemLanguageChoice ? null : choice,
          );
    }
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;

  const _LanguageOption({required this.label, required this.code, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, code),
      child: Row(
        children: [
          if (selected) const Icon(Icons.check, size: 18) else const SizedBox(width: 18),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
