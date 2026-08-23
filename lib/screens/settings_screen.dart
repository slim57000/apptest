import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/backup_provider.dart';
import '../providers/habits_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/app_logo.dart';
import 'archived_habits_screen.dart';
import 'challenges_screen.dart';
import 'legal_screen.dart';
import 'paywall_screen.dart';

/// Numéro de version affiché dans "À propos" : à garder synchronisé avec
/// le `version:` de `pubspec.yaml` (pas de dépendance package_info_plus
/// pour l'instant, voir README).
const _appVersion = '1.0.0';

/// Site de l'éditeur de l'application, affiché dans la fenêtre À propos.
const _publisherUrl = 'https://rampedigitale.fr';

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
    final habitsCount = context.watch<HabitsProvider>().activeHabits.length;
    final locale = context.watch<LocaleProvider>().locale;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SettingsOption(
            icon: Icons.workspace_premium,
            iconColor: premium.isPremium ? Colors.amber : null,
            title: l10n.premiumSubscriptionLabel,
            subtitle: premium.isPremium ? l10n.statusActive : l10n.statusFree,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
          const Divider(),
          _SettingsOption(
            icon: Icons.checklist,
            title: l10n.activeHabitsLabel,
            subtitle: premium.isPremium
                ? l10n.activeHabitsCountPremium(habitsCount)
                : l10n.activeHabitsCountFree(habitsCount, HabitsProvider.freeHabitLimit),
          ),
          const Divider(),
          _SettingsOption(
            icon: Icons.language,
            title: l10n.languageLabel,
            subtitle: _languageLabel(l10n, locale),
            onTap: () => _pickLanguage(context, locale),
          ),
          const Divider(),
          if (premium.isPremium)
            const _CloudBackupSection()
          else
            _SettingsOption(
              icon: Icons.cloud_outlined,
              title: l10n.cloudBackupTitle,
              subtitle: l10n.statusFree,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
          const Divider(),
          _SettingsOption(
            icon: Icons.groups,
            title: l10n.challengesTitle,
            subtitle: l10n.challengesSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChallengesScreen()),
            ),
          ),
          const Divider(),
          // Écran interne à l'app (pas de navigateur externe) : contenu
          // complet dans LegalScreen, voir lib/screens/legal_screen.dart.
          _SettingsOption(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicyLabel,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LegalScreen(isPrivacyPolicy: true)),
            ),
          ),
          const Divider(),
          _SettingsOption(
            icon: Icons.archive_outlined,
            title: l10n.archivedHabitsTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ArchivedHabitsScreen()),
            ),
          ),
          const Divider(),
          _SettingsOption(
            icon: Icons.info_outline,
            title: l10n.aboutTitle,
            onTap: () => _showAboutDialog(context, l10n),
          ),
        ],
      ),
    );
  }

  // Dialogue personnalisé (au lieu du showAboutDialog standard, dont l'icône
  // + le nom de l'app en Row force un retour à la ligne mal centré) : tout
  // le contenu est dans une Column, donc réellement centré.
  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppLogo(size: 56, showText: false),
              const SizedBox(height: 12),
              Text(
                l10n.appTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                _appVersion,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 16),
              Text(l10n.aboutIntro, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                l10n.aboutFeatures,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.7),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.aboutPrivacyNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.aboutFeedbackNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const Divider(height: 32),
              Text(
                l10n.aboutPublisherNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(_publisherUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.aboutPublisherSiteLabel),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
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

/// Option du menu Réglages : icône au-dessus du libellé, sous-titre
/// dessous — le tout sur le même axe central, donc parfaitement aligné.
class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsOption({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Column(
          children: [
            Icon(icon, size: 24, color: iconColor ?? theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloudBackupSection extends StatefulWidget {
  const _CloudBackupSection();

  @override
  State<_CloudBackupSection> createState() => _CloudBackupSectionState();
}

class _CloudBackupSectionState extends State<_CloudBackupSection> {
  @override
  void initState() {
    super.initState();
    // Rafraîchit la date de dernière sauvegarde depuis le serveur à
    // l'ouverture des réglages, pour un statut toujours fiable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BackupProvider>().refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final backup = context.watch<BackupProvider>();

    if (!backup.configured) {
      return ListTile(
        leading: const Icon(Icons.cloud_outlined),
        title: Text(l10n.cloudBackupTitle),
        subtitle: Text(l10n.cloudBackupNotConfigured),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Même style que les autres options : icône au-dessus du titre.
          // Nuage vert coché = une sauvegarde existe sur le serveur.
          Icon(
            backup.lastBackupAt == null ? Icons.cloud_outlined : Icons.cloud_done,
            size: 24,
            color:
                backup.lastBackupAt == null ? theme.colorScheme.primary : Colors.green,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.cloudBackupTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.cloudBackupDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          if (backup.loading)
            const Padding(
              padding: EdgeInsets.all(4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Text(
              backup.lastBackupAt == null
                  ? l10n.neverBackedUp
                  : l10n.lastBackupAt(DateFormat.yMd(Localizations.localeOf(context).toString())
                      .add_Hm()
                      .format(backup.lastBackupAt!.toLocal())),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
                      : Text(l10n.backupNow, textAlign: TextAlign.center),
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
