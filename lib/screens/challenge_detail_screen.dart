import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  Future<List<ChallengeMemberStatus>?>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<ChallengeProvider>().memberStatuses(widget.challenge.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.challenge.emoji} ${widget.challenge.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: l10n.shareInvite,
            onPressed: () => _shareInvite(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _future;
        },
        child: FutureBuilder<List<ChallengeMemberStatus>?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final members = snapshot.data;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.inviteCodeLabel, style: Theme.of(context).textTheme.bodySmall),
                              SelectableText(
                                widget.challenge.inviteCode,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: l10n.copyCode,
                          onPressed: () => _copyCode(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await context.read<ChallengeProvider>().checkInToday(widget.challenge.id);
                    setState(_reload);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.checkInToday),
                ),
                const SizedBox(height: 24),
                if (members != null)
                  ...members.map((m) => _MemberTile(member: m))
                else
                  const SizedBox.shrink(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: widget.challenge.inviteCode));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
    }
  }

  Future<void> _shareInvite(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${widget.challenge.emoji} ${widget.challenge.name} — '
            'rejoins mon défi sur Habitudes+ avec le code ${widget.challenge.inviteCode} !',
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ChallengeMemberStatus member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          member.doneToday ? Icons.check_circle : Icons.radio_button_unchecked,
          color: member.doneToday ? Colors.green : null,
        ),
        title: Text(member.displayName),
        trailing: Text('🔥 ${l10n.memberStreak(member.streak)}'),
      ),
    );
  }
}
