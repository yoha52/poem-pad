import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  static void initFfi({TargetPlatform? overridePlatform}) {
    if (kIsWeb) return;
    final platform = overridePlatform ?? defaultTargetPlatform;
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    initFfi();
    String dbPath;
    if (kIsWeb) {
      dbPath = 'poem_pad.db';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, 'poem_pad.db');
    }

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE poems (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        tags TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_poems_search ON poems(title, content, tags);',
    );
    await db.execute('CREATE INDEX IF NOT EXISTS idx_poems_updated_at ON poems(updated_at);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_poems_is_pinned ON poems(is_pinned);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_poems_deleted_at ON poems(deleted_at);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_poems_tags ON poems(tags);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_poems_updated_at ON poems(updated_at);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_poems_is_pinned ON poems(is_pinned);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_poems_deleted_at ON poems(deleted_at);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_poems_tags ON poems(tags);');
    }
  }
}
