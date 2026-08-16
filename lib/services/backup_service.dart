import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/habit.dart';

/// Sauvegarde/restauration cloud des habitudes (Premium), sur le même
/// projet Supabase que les défis entre amis mais indépendante de son
/// système de profils : une simple sauvegarde n'a pas besoin de pseudo.
class BackupService {
  SupabaseClient get _client => Supabase.instance.client;

  bool get isSignedIn => _client.auth.currentUser != null;

  Future<void> ensureSignedIn() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }

  Future<DateTime?> lastBackupAt() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await _client
        .from('habit_backups')
        .select('updated_at')
        .eq('user_id', uid)
        .limit(1);
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.first['updated_at'] as String);
  }

  Future<void> backup(List<Habit> habits) async {
    await ensureSignedIn();
    final uid = _client.auth.currentUser!.id;
    await _client.from('habit_backups').upsert({
      'user_id': uid,
      'habits_json': habits.map((h) => h.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Retourne `null` si aucune sauvegarde n'existe encore.
  Future<List<Habit>?> restore() async {
    await ensureSignedIn();
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('habit_backups')
        .select('habits_json')
        .eq('user_id', uid)
        .limit(1);
    if (rows.isEmpty) return null;
    final list = rows.first['habits_json'] as List<dynamic>;
    return list.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }
}
