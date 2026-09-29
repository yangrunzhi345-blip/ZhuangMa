import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../main.dart';

class ScenarioRepositoryException implements Exception {
  final String message;
  const ScenarioRepositoryException(this.message);
  @override
  String toString() => 'ScenarioRepositoryException: $message';
}

class SqliteScenarioRepository {
  final Database database;
  SqliteScenarioRepository(this.database);

  static Future<SqliteScenarioRepository> open(String path) async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute(
      'CREATE TABLE IF NOT EXISTS attack_scenarios (id TEXT PRIMARY KEY, payload TEXT NOT NULL, created_at INTEGER NOT NULL)',
    );
    return SqliteScenarioRepository(db);
  }

  Future<void> save(AttackScenario scenario) =>
      database.insert('attack_scenarios', {
        'id': scenario.id,
        'payload': jsonEncode(scenario.toJson()),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<AttackScenario>> all() async {
    final rows = await database.query(
      'attack_scenarios',
      orderBy: 'created_at DESC',
    );
    final result = <AttackScenario>[];
    for (final row in rows) {
      try {
        result.add(
          AttackScenario.fromJson(
            jsonDecode(row['payload']! as String) as Map<String, dynamic>,
          ),
        );
      } on Object catch (error) {
        throw ScenarioRepositoryException(
          'Invalid scenario record ${row['id']}: $error',
        );
      }
    }
    return result;
  }

  Future<void> delete(String id) =>
      database.delete('attack_scenarios', where: 'id = ?', whereArgs: [id]);
  Future<void> close() => database.close();
}
