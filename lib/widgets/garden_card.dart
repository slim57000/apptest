import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/habit.dart';

class _GardenLevel {
  final int threshold;
  final String emoji;
  final String Function(AppLocalizations l10n) name;

  const _GardenLevel(this.threshold, this.emoji, this.name);
}

const _levels = [
  _GardenLevel(0, '🌱', _seed),
  _GardenLevel(5, '🌿', _sprout),
  _GardenLevel(20, '🪴', _plant),
  _GardenLevel(50, '🌳', _tree),
  _GardenLevel(100, '🌸', _bloom),
];

String _seed(AppLocalizations l10n) => l10n.gardenLevelSeed;
String _sprout(AppLocalizations l10n) => l10n.gardenLevelSprout;
String _plant(AppLocalizations l10n) => l10n.gardenLevelPlant;
String _tree(AppLocalizations l10n) => l10n.gardenLevelTree;
String _bloom(AppLocalizations l10n) => l10n.gardenLevelBloom;

/// Jardin virtuel qui grandit avec la régularité globale (toutes habitudes
/// confondues) : transforme le suivi en investissement émotionnel plutôt
/// qu'une simple liste de cases à cocher (façon Finch/Forest). Purement
/// dérivé des habitudes existantes -- aucun état séparé à persister.
class GardenCard extends StatelessWidget {
  final List<Habit> habits;

  const GardenCard({super.key, required this.habits});

  int get _totalCompletions =>
      habits.fold(0, (sum, h) => sum + h.completedDates.length);

  bool get _needsWater {
    if (habits.isEmpty) return false;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    return !habits.any((h) => h.isCompletedOn(today) || h.isCompletedOn(yesterday));
  }

  _GardenLevel get _currentLevel {
    var current = _levels.first;
    for (final level in _levels) {
      if (_totalCompletions >= level.threshold) current = level;
    }
    return current;
  }

  _GardenLevel? get _nextLevel {
    final index = _levels.indexOf(_currentLevel);
    return index + 1 < _levels.length ? _levels[index + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final level = _currentLevel;
    final next = _nextLevel;
    final total = _totalCompletions;
    final needsWater = _needsWater;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(needsWater ? '🥀' : level.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.name(l10n),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    needsWater
                        ? l10n.gardenNeedsWater
                        : next == null
                            ? l10n.gardenCompletionsCount(total)
                            : l10n.gardenProgressToNext(next.threshold - total),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
