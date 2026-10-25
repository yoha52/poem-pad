import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';
import '../models/poem.dart';

enum PoemSortOption { lastEdited, created, title }

class PoemRepository {
  final DatabaseHelper _dbHelper;

  PoemRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Idempotent migration from legacy SharedPreferences JSON storage to SQLite.
  Future<void> migrateFromSharedPreferencesIfNeeded({Database? overrideDb}) async {
    final prefs = await SharedPreferences.getInstance();
    final isMigrated = prefs.getBool('sqlite_migration_done') ?? false;
    if (isMigrated) return;

    final legacyJson = prefs.getString('saved_poems');
    if (legacyJson != null && legacyJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(legacyJson);
        final legacyPoems = decoded.map((item) => Poem.fromMap(item as Map<String, dynamic>)).toList();

        final db = overrideDb ?? await _dbHelper.database;
        final batch = db.batch();
        for (var poem in legacyPoems) {
          batch.insert(
            'poems',
            poem.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      } catch (_) {
        // Ignore malformed legacy data gracefully
      }
    }
    await prefs.setBool('sqlite_migration_done', true);
  }

  Future<List<Poem>> getActivePoems({
    String? query,
    String? selectedTag,
    PoemSortOption sortOption = PoemSortOption.lastEdited,
    Database? overrideDb,
  }) async {
    final db = overrideDb ?? await _dbHelper.database;
    await purgeOldDeletedPoems(30, overrideDb: db);

    String orderBy;
    switch (sortOption) {
      case PoemSortOption.created:
        orderBy = 'created_at DESC';
        break;
      case PoemSortOption.title:
        orderBy = 'title ASC';
        break;
      case PoemSortOption.lastEdited:
        orderBy = 'updated_at DESC';
        break;
    }

    String where = 'deleted_at IS NULL';
    List<dynamic> whereArgs = [];

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim().toLowerCase()}%';
      where += ' AND (LOWER(title) LIKE ? OR LOWER(content) LIKE ? OR LOWER(tags) LIKE ?)';
      whereArgs.addAll([q, q, q]);
    }

    if (selectedTag != null && selectedTag.trim().isNotEmpty) {
      where += ' AND LOWER(tags) LIKE ?';
      whereArgs.add('%${selectedTag.trim().toLowerCase()}%');
    }

    final maps = await db.query(
      'poems',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return maps.map((m) => Poem.fromMap(m)).toList();
  }

  Future<List<Poem>> getTrashPoems({Database? overrideDb}) async {
    final db = overrideDb ?? await _dbHelper.database;
    final maps = await db.query(
      'poems',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return maps.map((m) => Poem.fromMap(m)).toList();
  }

  Future<void> savePoem(Poem poem, {Database? overrideDb}) async {
    // Never save empty untitled poems
    if (poem.title.trim().isEmpty && poem.content.trim().isEmpty) return;

    final db = overrideDb ?? await _dbHelper.database;
    await db.insert(
      'poems',
      poem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDeletePoem(String id, {Database? overrideDb}) async {
    final db = overrideDb ?? await _dbHelper.database;
    await db.update(
      'poems',
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restorePoem(String id, {Database? overrideDb}) async {
    final db = overrideDb ?? await _dbHelper.database;
    await db.update(
      'poems',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> purgePoem(String id, {Database? overrideDb}) async {
    final db = overrideDb ?? await _dbHelper.database;
    await db.delete(
      'poems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> purgeOldDeletedPoems(int days, {Database? overrideDb}) async {
    final db = overrideDb ?? await _dbHelper.database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    await db.delete(
      'poems',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff],
    );
  }

  Future<List<String>> getAllTags({Database? overrideDb}) async {
    final poems = await getActivePoems(overrideDb: overrideDb);
    final Set<String> allTags = {};
    for (var p in poems) {
      allTags.addAll(p.tags);
    }
    return allTags.toList()..sort();
  }

  Future<String> exportBackupJson({Database? overrideDb}) async {
    final db = overrideDb ?? await _dbHelper.database;
    final maps = await db.query('poems');
    final poems = maps.map((m) => Poem.fromMap(m)).toList();
    return json.encode(poems.map((p) => p.toMap()).toList());
  }

  Future<int> restoreBackupJson(String jsonStr, {bool replace = false, Database? overrideDb}) async {
    final db = overrideDb ?? await _dbHelper.database;
    final List<dynamic> decoded = json.decode(jsonStr);
    final poems = decoded.map((item) => Poem.fromMap(item as Map<String, dynamic>)).toList();

    if (replace) {
      await db.delete('poems');
    }

    final batch = db.batch();
    for (var p in poems) {
      batch.insert(
        'poems',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    return poems.length;
  }
}
