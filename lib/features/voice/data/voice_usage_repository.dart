import 'package:sqflite/sqflite.dart';

import '../../../data/local/database_service.dart';

/// Counts voice fills so free users get [freeVoiceFills] before Premium,
/// matching the web app (src/features/voice/voice-usage.ts).
class VoiceUsageRepository {
  static const int freeVoiceFills = 2;
  static const String _key = 'voice_fills_used';

  final DatabaseService _dbService;

  VoiceUsageRepository(this._dbService);

  Future<Database> _db() async {
    final db = await _dbService.database;
    await db.execute(
      'CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)',
    );
    return db;
  }

  Future<int> used() async {
    final db = await _db();
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [_key]);
    if (rows.isEmpty) return 0;
    return int.tryParse('${rows.first['value']}') ?? 0;
  }

  Future<int> left() async {
    final remaining = freeVoiceFills - await used();
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> recordFill() async {
    final next = await used() + 1;
    final db = await _db();
    await db.insert(
      'app_settings',
      {'key': _key, 'value': '$next'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
