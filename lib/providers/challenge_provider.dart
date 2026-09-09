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
  String? _lastErrorDetail;
  String? _displayName;

  ChallengeProvider(this._service);

  bool get configured => SupabaseConfig.isConfigured;
  bool get signedIn => configured && _service.isSignedIn;
  List<Challenge> get challenges => List.unmodifiable(_challenges);
  bool get loading => _loading;
  ChallengeErrorKind? get errorKind => _errorKind;
  /// Message d'exception brut de la dernière erreur -- diagnostic
  /// temporaire (voir problème de création de défi en cours
  /// d'investigation), pas destiné à rester affiché tel quel une fois le
  /// bug identifié.
  String? get lastErrorDetail => _lastErrorDetail;
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

  Future<bool> signIn(String displayName) => _guard(() async {
        await _service.ensureSignedInWithName(displayName);
        _displayName = displayName;
        await _refresh();
      });

  /// Change le pseudo affiché aux autres membres des défis, une fois déjà
  /// connecté.
  Future<bool> updateDisplayName(String displayName) => _guard(() async {
        await _service.ensureSignedInWithName(displayName);
        _displayName = displayName;
      });

  Future<void> _refresh() async {
    _challenges = await _service.myChallenges();
    _displayName ??= await _service.myDisplayName();
    notifyListeners();
  }

  Future<bool> createChallenge({required String name, required String emoji}) => _guard(() async {
        await _service.createChallenge(name: name, emoji: emoji);
        await _refresh();
      });

  /// Retourne `false` (avec [error] renseigné) si le code ne correspond à
  /// aucun défi.
  Future<bool> joinChallenge(String code) => _guard(() async {
        final challenge = await _service.joinChallenge(code);
        if (challenge == null) {
          throw StateError('not_found');
        }
        await _refresh();
      });

  Future<bool> checkInToday(String challengeId) => _guard(() async {
        await _service.checkInToday(challengeId);
      });

  Future<List<ChallengeMemberStatus>?> memberStatuses(String challengeId) async {
    try {
      return await _service.memberStatuses(challengeId);
    } catch (e) {
      _errorKind = _classify(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> _guard(Future<void> Function() action) async {
    _errorKind = null;
    _lastErrorDetail = null;
    _loading = true;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _errorKind = _classify(e);
      _lastErrorDetail = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
