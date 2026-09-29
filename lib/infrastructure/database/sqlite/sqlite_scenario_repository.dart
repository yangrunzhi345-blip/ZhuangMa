import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/errors/repository_exception.dart';
import '../../../domain/attack/attack_category.dart';
import '../../../domain/attack/attack_scenario.dart';
import '../../../domain/repository/scenario_repository.dart';

export '../../../core/errors/repository_exception.dart';

class SqliteScenarioRepository implements ScenarioRepository {
  final Database database;
  final List<String> diagnostics = [];
  static const int currentSchemaVersion = 1;

  SqliteScenarioRepository(this.database);

  static Future<SqliteScenarioRepository> open(String path) async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: currentSchemaVersion,
        onCreate: (db, version) async {
          await _createSchemaV1(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _migrate(db, oldVersion, newVersion);
        },
      ),
    );
    // Ensure table exists even if file was created outside OpenDatabaseOptions
    await _createSchemaV1(db);
    return SqliteScenarioRepository(db);
  }

  static Future<void> _createSchemaV1(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS attack_scenarios ('
      'id TEXT PRIMARY KEY, '
      'payload TEXT NOT NULL, '
      'created_at INTEGER NOT NULL, '
      'schema_version INTEGER NOT NULL DEFAULT 1'
      ')',
    );
  }

  static Future<void> _migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      // Future migration hooks
    }
  }

  @override
  Future<void> save(AttackScenario scenario) async {
    if (!database.isOpen) {
      throw const ScenarioRepositoryException('Database is closed');
    }
    try {
      await database.insert('attack_scenarios', {
        'id': scenario.id,
        'payload': jsonEncode(scenario.toJson()),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'schema_version': currentSchemaVersion,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on Object catch (e) {
      throw ScenarioRepositoryException('Failed to save scenario: $e');
    }
  }

  @override
  Future<AttackScenario?> getById(String id) async {
    if (!database.isOpen) {
      throw const ScenarioRepositoryException('Database is closed');
    }
    final rows = await database.query(
      'attack_scenarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    try {
      return AttackScenario.fromJson(
        jsonDecode(rows.first['payload']! as String) as Map<String, dynamic>,
      );
    } on Object catch (e) {
      diagnostics.add('Corrupt record $id: $e');
      return null;
    }
  }

  @override
  Future<List<AttackScenario>> all() async {
    if (!database.isOpen) {
      throw const ScenarioRepositoryException('Database is closed');
    }
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
        diagnostics.add('Skipped invalid scenario ${row['id']}: $error');
      }
    }
    return result;
  }

  @override
  Future<List<AttackScenario>> search(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return all();
    final items = await all();
    return items.where((s) {
      final combined =
          '${s.name} ${s.objective} ${s.prompt} ${s.targetBoundary} ${s.tags.join(' ')}'
              .toLowerCase();
      return combined.contains(clean);
    }).toList();
  }

  @override
  Future<List<AttackScenario>> filter({
    AttackCategory? category,
    int? minSeverity,
    String? tag,
  }) async {
    final items = await all();
    return items.where((s) {
      if (category != null && s.category != category) return false;
      if (minSeverity != null && s.severity < minSeverity) return false;
      if (tag != null && !s.tags.contains(tag)) return false;
      return true;
    }).toList();
  }

  @override
  Future<int> count() async {
    if (!database.isOpen) {
      throw const ScenarioRepositoryException('Database is closed');
    }
    final rows = await database.rawQuery(
      'SELECT COUNT(*) as count FROM attack_scenarios',
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  @override
  Future<void> delete(String id) async {
    if (!database.isOpen) {
      throw const ScenarioRepositoryException('Database is closed');
    }
    await database.delete('attack_scenarios', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> close() => database.close();
}
