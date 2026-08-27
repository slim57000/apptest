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
      await ShareService.shareBoundary(_boundaryKey, text: 'Habitudes+');
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, Color.lerp(color, Colors.black, 0.35)!],
          ),
        ),
        child: Stack(
          children: [
            // Illustration décorative (formes douces + emoji géant en
            // filigrane) : évite un simple aplat de couleur derrière le
            // texte, tout en restant sobre pour rester lisible.
            Positioned(
              top: -40,
              right: -50,
              child: _softCircle(150, Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -70,
              left: -60,
              child: _softCircle(200, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              top: 70,
              left: -35,
              child: _softCircle(90, Colors.white.withValues(alpha: 0.07)),
            ),
            Center(
              child: Opacity(
                opacity: 0.14,
                child: Text(habit.emoji, style: const TextStyle(fontSize: 230)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(habit.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(
                        habit.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 64)),
                      Text(
                        '${habit.currentStreakCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 88,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      Text(
                        habit.streakUnitIsWeeks
                            ? l10n.shareCardWeeksLabel
                            : l10n.shareCardDaysLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
          ],
        ),
      ),
    );
  }

  Widget _softCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
