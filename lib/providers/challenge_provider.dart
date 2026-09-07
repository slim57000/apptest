import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/challenge.dart';
import '../services/challenge_service.dart';

/// Catégorie d'erreur affichable, plutôt que le texte brut de l'exception :
/// une `SocketException`/`ClientException` réseau (nom d'hôte interne inclus)
/// ne doit jamais atteindre l'écran telle quelle. L'UI choisit le message
/// localisé selon cette catégorie.
enum ChallengeErrorKind { network, generic }

class ChallengeProvider extends ChangeNotifier {
  final ChallengeService _service;

  List<Challenge> _challenges = [];
  bool _loading = false;
  ChallengeErrorKind? _errorKind;
  String? _displayName;

  ChallengeProvider(this._service);

  bool get configured => SupabaseConfig.isConfigured;
  bool get signedIn => configured && _service.isSignedIn;
  List<Challenge> get challenges => List.unmodifiable(_challenges);
  bool get loading => _loading;
  ChallengeErrorKind? get errorKind => _errorKind;
  String? get displayName => _displayName;

  static ChallengeErrorKind _classify(Object e) {
    final text = e.toString();
    return text.contains('SocketException') ||
            text.contains('ClientException') ||
            text.contains('TimeoutException') ||
            text.contains('Failed host lookup')
        ? ChallengeErrorKind.network
        : ChallengeErrorKind.generic;
  }

  /// Un raté DNS/réseau ponctuel (perte Wi-Fi une fraction de seconde,
  /// bascule vers la 4G, résolveur pas encore prêt juste après le lancement
  /// de l'app...) ne doit pas se transformer en message d'erreur si une
  /// nouvelle tentative quelques instants plus tard passe : ces délais sont
  /// courts pour rester imperceptibles sur un vrai raté réseau, mais
  /// suffisent à absorber un blip transitoire avant d'afficher quoi que ce
  /// soit à l'utilisateur.
  static const _retryDelays = [Duration(milliseconds: 400), Duration(seconds: 2)];

  static Future<T> _withRetry<T>(Future<T> Function() action) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await action();
      } catch (e) {
        if (attempt >= _retryDelays.length || _classify(e) != ChallengeErrorKind.network) {
          rethrow;
        }
        await Future.delayed(_retryDelays[attempt]);
      }
    }
  }

  // Chaque appel réseau est retenté individuellement (plutôt que le bloc
  // entier via `_guard`) : `createChallenge` insère une ligne non
  // ré-appliquable sans risque -- si on retentait toute l'action composite
  // après un insert déjà réussi mais un `_refresh()` qui rate juste après,
  // on créerait un doublon. Chaque étape est donc protégée à sa propre
  // frontière réseau, avec juste ce qu'il faut d'idempotence (upsert, ou le
  // "on conflict do nothing" de `join_challenge` côté serveur).

  Future<bool> signIn(String displayName) => _guard(() async {
        await _withRetry(() => _service.ensureSignedInWithName(displayName));
        _displayName = displayName;
        await _refresh();
      });

  /// Change le pseudo affiché aux autres membres des défis, une fois déjà
  /// connecté.
  Future<bool> updateDisplayName(String displayName) => _guard(() async {
        await _withRetry(() => _service.ensureSignedInWithName(displayName));
        _displayName = displayName;
      });

  Future<void> _refresh() async {
    _challenges = await _withRetry(() => _service.myChallenges());
    _displayName ??= await _withRetry(() => _service.myDisplayName());
    notifyListeners();
  }

  Future<bool> createChallenge({required String name, required String emoji}) => _guard(() async {
        await _withRetry(() => _service.createChallenge(name: name, emoji: emoji));
        await _refresh();
      });

  /// Retourne `false` (avec [error] renseigné) si le code ne correspond à
  /// aucun défi.
  Future<bool> joinChallenge(String code) => _guard(() async {
        final challenge = await _withRetry(() => _service.joinChallenge(code));
        if (challenge == null) {
          throw StateError('not_found');
        }
        await _refresh();
      });

  Future<bool> checkInToday(String challengeId) => _guard(() async {
        await _withRetry(() => _service.checkInToday(challengeId));
      });

  Future<List<ChallengeMemberStatus>?> memberStatuses(String challengeId) async {
    try {
      return await _withRetry(() => _service.memberStatuses(challengeId));
    } catch (e) {
      _errorKind = _classify(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> _guard(Future<void> Function() action) async {
    _errorKind = null;
    _loading = true;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _errorKind = _classify(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
