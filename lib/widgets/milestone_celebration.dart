import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Dialogue de célébration affiché quand une série atteint un palier
/// (7/30/100/365 jours, ou 4/12/26/52 semaines pour les objectifs
/// hebdomadaires). Confettis plein écran + libellé de série atteinte.
class MilestoneCelebration extends StatefulWidget {
  final String streakLabel;

  const MilestoneCelebration({super.key, required this.streakLabel});

  static Future<void> show(BuildContext context, {required String streakLabel}) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: MilestoneCelebration(streakLabel: streakLabel),
      ),
    );
  }

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 60,
          maxBlastForce: 24,
          minBlastForce: 8,
          gravity: 0.25,
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(
                  l10n.milestoneTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(widget.streakLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.milestoneCta),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
