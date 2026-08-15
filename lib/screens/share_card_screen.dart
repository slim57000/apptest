import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../services/share_service.dart';

/// Aperçu + partage d'une carte de série au format image (Instagram/Snap
/// Stories...). Le levier de croissance organique le plus simple à
/// implémenter : chaque partage est une pub gratuite pour l'app.
class ShareCardScreen extends StatefulWidget {
  final Habit habit;

  const ShareCardScreen({super.key, required this.habit});

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareStreakTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: _StreakCard(habit: widget.habit),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
                label: Text(l10n.shareAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await ShareService.shareBoundary(_boundaryKey, text: 'Habitude+');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _StreakCard extends StatelessWidget {
  final Habit habit;

  const _StreakCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Color(habit.colorValue);

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, Color.lerp(color, Colors.black, 0.35)!],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(habit.emoji, style: const TextStyle(fontSize: 28)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 64)),
                Text(
                  '${habit.currentStreak}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 88,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  l10n.shareCardDaysLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.shareCardBranding,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
