import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/challenge.dart';

/// Défis entre amis : la seule fonctionnalité de l'app avec un backend
/// (Supabase). Auth anonyme + pseudo affiché, un défi = un code
/// d'invitation à 6 caractères, un check-in "j'ai réussi aujourd'hui" par
/// membre et par jour. Voir `supabase/schema.sql` pour le schéma complet.
class ChallengeService {
  SupabaseClient get _client => Supabase.instance.client;

  bool get isSignedIn => _client.auth.currentUser != null;

  Future<void> ensureSignedInWithName(String displayName) async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
    final uid = _client.auth.currentUser!.id;
    await _client.from('profiles').upsert({'id': uid, 'display_name': displayName});
  }

  Future<List<Challenge>> myChallenges() async {
    final uid = _client.auth.currentUser!.id;
    final memberRows = await _client
        .from('challenge_members')
        .select('challenge_id')
        .eq('user_id', uid);
    final ids = memberRows.map((r) => r['challenge_id'] as String).toList();
    if (ids.isEmpty) return [];

    final rows = await _client.from('challenges').select().inFilter('id', ids);
    return rows.map((r) => Challenge.fromRow(r)).toList();
  }

  Future<Challenge> createChallenge({required String name, required String emoji}) async {
    final uid = _client.auth.currentUser!.id;
    final code = _generateInviteCode();
    final row = await _client
        .from('challenges')
        .insert({'name': name, 'emoji': emoji, 'invite_code': code, 'created_by': uid})
        .select()
        .single();
    final challenge = Challenge.fromRow(row);
    await _client.from('challenge_members').insert({
      'challenge_id': challenge.id,
      'user_id': uid,
    });
    return challenge;
  }

  /// Retourne `null` si aucun défi ne correspond à ce code.
  Future<Challenge?> joinChallenge(String inviteCode) async {
    final rows = await _client
        .from('challenges')
        .select()
        .eq('invite_code', inviteCode.trim().toUpperCase())
        .limit(1);
    if (rows.isEmpty) return null;

    final challenge = Challenge.fromRow(rows.first);
    final uid = _client.auth.currentUser!.id;
    await _client.from('challenge_members').upsert({
      'challenge_id': challenge.id,
      'user_id': uid,
    });
    return challenge;
  }

  Future<void> checkInToday(String challengeId) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('challenge_checkins').upsert({
      'challenge_id': challengeId,
      'user_id': uid,
      'day': _dayKey(DateTime.now()),
    });
  }

  Future<List<ChallengeMemberStatus>> memberStatuses(String challengeId) async {
    final memberRows = await _client
        .from('challenge_members')
        .select('user_id, profiles(display_name)')
        .eq('challenge_id', challengeId);
    final checkinRows = await _client
        .from('challenge_checkins')
        .select('user_id, day')
        .eq('challenge_id', challengeId);

    final checkinsByUser = <String, Set<String>>{};
    for (final row in checkinRows) {
      final uid = row['user_id'] as String;
      final day = row['day'] as String;
      checkinsByUser.putIfAbsent(uid, () => {}).add(day);
    }

    final today = DateTime.now();
    return memberRows.map((row) {
      final uid = row['user_id'] as String;
      final profile = row['profiles'] as Map<String, dynamic>?;
      final displayName = profile?['display_name'] as String? ?? '?';
      final days = checkinsByUser[uid] ?? <String>{};
      return ChallengeMemberStatus(
        userId: uid,
        displayName: displayName,
        doneToday: days.contains(_dayKey(today)),
        streak: _streakFrom(days, today),
      );
    }).toList();
  }

  int _streakFrom(Set<String> days, DateTime today) {
    if (days.isEmpty) return 0;
    var streak = 0;
    var cursor = today;
    var isFirstDay = true;
    // Bornée à 365 jours de recul : largement suffisant pour l'affichage
    // d'un streak, et évite toute boucle non bornée.
    for (var i = 0; i < 365; i++) {
      final has = days.contains(_dayKey(cursor));
      if (has) {
        streak++;
      } else if (!isFirstDay) {
        break;
      }
      isFirstDay = false;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dayKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
