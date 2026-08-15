import 'package:health/health.dart';

/// Seuil de pas quotidiens pour valider automatiquement une habitude liée
/// à l'activité physique. Fixe pour la v1 (non configurable par
/// l'utilisateur) pour rester simple.
const int stepsGoalForAutoComplete = 5000;

/// Intégration Health Connect (Android) / Apple Health (iOS) via le
/// package `health`. Google Fit n'est plus supporté par la plateforme
/// depuis la dépréciation de son API par Google : Health Connect (app
/// séparée sur Android < 14) est désormais le seul chemin Android.
class HealthService {
  final Health _health = Health();
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> requestStepsAuthorization() async {
    await _ensureConfigured();
    try {
      return await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
    } catch (_) {
      return false;
    }
  }

  Future<int> stepsToday() async {
    await _ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _health.getTotalStepsInInterval(
        midnight,
        now,
        includeManualEntry: true,
      );
      return steps ?? 0;
    } catch (_) {
      // Health Connect non installé, permission refusée, ou plateforme non
      // supportée (web/desktop) : on traite comme "pas de données" plutôt
      // que de faire planter la synchronisation des autres habitudes.
      return 0;
    }
  }
}
