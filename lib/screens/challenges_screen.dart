import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/challenge_provider.dart';
import '../theme.dart';
import 'challenge_detail_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ChallengeProvider>();

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.challengesTitle)),
      body: !provider.configured
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.challengesNotConfigured, textAlign: TextAlign.center),
              ),
            )
          : !provider.signedIn
              ? _DisplayNamePrompt(nameController: _nameController)
              : const _ChallengesList(),
    );
  }
}

class _DisplayNamePrompt extends StatelessWidget {
  final TextEditingController nameController;

  const _DisplayNamePrompt({required this.nameController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ChallengeProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 56, color: Colors.deepPurple),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: l10n.displayNameLabel,
                hintText: l10n.displayNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: provider.loading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      await context.read<ChallengeProvider>().signIn(name);
                    },
              child: provider.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.startAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengesList extends StatelessWidget {
  const _ChallengesList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ChallengeProvider>();

    return Column(
      children: [
        Expanded(
          child: provider.challenges.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noChallenges, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: provider.challenges
                      .map(
                        (challenge) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Text(challenge.emoji, style: const TextStyle(fontSize: 22)),
                            title: Text(challenge.name),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChallengeDetailScreen(challenge: challenge),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        // Boutons empilés pleine largeur : « Rejoindre avec un code »
        // tient toujours sur une seule ligne, même en français.
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showJoinDialog(context),
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: Text(l10n.joinChallenge),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createChallenge),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    var emoji = habitEmojiChoices.first;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.createChallenge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: l10n.challengeNameLabel,
                    hintText: l10n.challengeNameHint,
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.iconLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: habitEmojiChoices.take(8).map((e) {
                    final selected = e == emoji;
                    final scheme = Theme.of(context).colorScheme;
                    return GestureDetector(
                      onTap: () => setState(() => emoji = e),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                          border: Border.all(
                            color: selected ? scheme.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(e, style: TextStyle(fontSize: selected ? 22 : 18)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      final provider = context.read<ChallengeProvider>();
      final ok = await provider.createChallenge(name: name.trim(), emoji: emoji);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? l10n.createChallengeFailed)),
        );
      } else if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.challengeCreated)),
        );
      }
    }
  }

  Future<void> _showJoinDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.joinChallenge),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: l10n.inviteCodeInputHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.join),
          ),
        ],
      ),
    );
    if (code != null && code.trim().isNotEmpty && context.mounted) {
      final provider = context.read<ChallengeProvider>();
      final ok = await provider.joinChallenge(code.trim());
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.challengeNotFound)),
        );
      }
    }
  }
}
