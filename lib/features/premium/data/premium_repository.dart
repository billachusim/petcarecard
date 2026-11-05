import 'package:sqflite/sqflite.dart';
import '../../../data/local/database_service.dart';

class PremiumRepository {
  final DatabaseService _dbService;

  PremiumRepository(this._dbService);

  static const String _keyPremium = 'is_premium_unlocked';

  Future<bool> isPremiumUnlocked() async {
    final db = await _dbService.database;
    await db.execute(
      'CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)',
    );
    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [_keyPremium],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] == 'true';
    }
    return false;
  }

  Future<void> setPremiumUnlocked(bool unlocked) async {
    final db = await _dbService.database;
    await db.execute(
      'CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)',
    );
    await db.insert(
      'app_settings',
      {'key': _keyPremium, 'value': unlocked ? 'true' : 'false'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
