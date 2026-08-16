import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/backup_provider.dart';
import '../providers/habits_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/premium_provider.dart';
import 'paywall_screen.dart';

/// `Navigator.pop` avec `null` est indiscernable entre "l'utilisateur a
/// choisi Système" et "fermeture du dialogue sans choix (tap en dehors)" :
/// cette valeur encode explicitement le premier cas.
const _systemLanguageChoice = '__system__';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    final backup = context.read<BackupProvider>();
    if (backup.configured) backup.refreshStatus();
  }

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
          if (premium.isPremium)
            const _CloudBackupSection()
          else
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(l10n.cloudBackupTitle),
              subtitle: Text(l10n.statusFree),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
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

class _CloudBackupSection extends StatelessWidget {
  const _CloudBackupSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final backup = context.watch<BackupProvider>();

    if (!backup.configured) {
      return ListTile(
        leading: const Icon(Icons.cloud_outlined),
        title: Text(l10n.cloudBackupTitle),
        subtitle: Text(l10n.cloudBackupNotConfigured),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.cloudBackupTitle, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.cloudBackupDescription, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            backup.lastBackupAt == null
                ? l10n.neverBackedUp
                : l10n.lastBackupAt(DateFormat.yMd(Localizations.localeOf(context).toString())
                    .add_Hm()
                    .format(backup.lastBackupAt!.toLocal())),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: backup.loading ? null : () => _restore(context),
                  child: Text(l10n.restoreBackup),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: backup.loading ? null : () => _backupNow(context),
                  child: backup.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.backupNow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _backupNow(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final habits = context.read<HabitsProvider>().habits;
    final ok = await context.read<BackupProvider>().backup(habits);
    if (!context.mounted) return;
    final backup = context.read<BackupProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.backupSuccess : (backup.error ?? ''))),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(l10n.restoreConfirmContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.restoreBackup)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final backupProvider = context.read<BackupProvider>();
    final habits = await backupProvider.restore();
    if (!context.mounted) return;

    if (habits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(backupProvider.error ?? l10n.noBackupFound)),
      );
      return;
    }

    await context.read<HabitsProvider>().replaceAll(habits);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoreSuccess)));
    }
  }
}
