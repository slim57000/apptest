import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/habit.dart';
import '../services/backup_service.dart';

class BackupProvider extends ChangeNotifier {
  final BackupService _service;

  bool _loading = false;
  String? _error;
  DateTime? _lastBackupAt;

  BackupProvider(this._service);

  bool get configured => SupabaseConfig.isConfigured;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastBackupAt => _lastBackupAt;

  Future<void> refreshStatus() async {
    if (!configured) return;
    try {
      _lastBackupAt = await _service.lastBackupAt();
      notifyListeners();
    } catch (_) {
      // Pas grave si ça échoue : l'utilisateur verra juste "jamais
      // sauvegardé" et pourra réessayer via le bouton.
    }
  }

  Future<bool> backup(List<Habit> habits) => _guard(() async {
        await _service.backup(habits);
        _lastBackupAt = DateTime.now();
      });

  /// Retourne les habitudes restaurées, ou `null` en cas d'échec/absence
  /// de sauvegarde (voir [error] pour le détail).
  Future<List<Habit>?> restore() async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      return await _service.restore();
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> _guard(Future<void> Function() action) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
