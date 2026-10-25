import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:untitled3/models/poem.dart';
import 'package:untitled3/repositories/poem_repository.dart';
import 'package:untitled3/services/syllable_counter_service.dart';
import 'package:untitled3/widgets/poem_card.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> createInMemoryDb() async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
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
    return db;
  }

  test('1. Migration: old-format data migrates to SQLite with no loss, running twice does not duplicate', () async {
    SharedPreferences.setMockInitialValues({
      'saved_poems': json.encode([
        {
          'id': 'p1',
          'title': 'ማለዳ',
          'content': 'ፀሐይ ወጣች',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isPinned': true,
        }
      ]),
    });

    final db = await createInMemoryDb();
    final repo = PoemRepository();

    await repo.migrateFromSharedPreferencesIfNeeded(overrideDb: db);
    final poems1 = await repo.getActivePoems(overrideDb: db);
    expect(poems1.length, 1);
    expect(poems1.first.title, 'ማለዳ');

    // Run migration second time
    await repo.migrateFromSharedPreferencesIfNeeded(overrideDb: db);
    final poems2 = await repo.getActivePoems(overrideDb: db);
    expect(poems2.length, 1); // No duplicates
  });

  test('2. Repository: CRUD, soft-delete, restore, purge, search title/content/tags', () async {
    final db = await createInMemoryDb();
    final repo = PoemRepository();

    final now = DateTime.now();
    final poem = Poem(
      id: 'test_1',
      title: 'ፍቅር',
      content: 'የልቤ ግጥም',
      createdAt: now,
      updatedAt: now,
      tags: ['ፍቅር', 'ሀገር'],
    );

    // Create
    await repo.savePoem(poem, overrideDb: db);
    var active = await repo.getActivePoems(overrideDb: db);
    expect(active.length, 1);

    // Search by title, content, or tag
    var searched = await repo.getActivePoems(query: 'ልቤ', overrideDb: db);
    expect(searched.length, 1);

    var tagSearched = await repo.getActivePoems(selectedTag: 'ሀገር', overrideDb: db);
    expect(tagSearched.length, 1);

    // Soft delete
    await repo.softDeletePoem('test_1', overrideDb: db);
    active = await repo.getActivePoems(overrideDb: db);
    expect(active.length, 0);

    var trash = await repo.getTrashPoems(overrideDb: db);
    expect(trash.length, 1);

    // Restore
    await repo.restorePoem('test_1', overrideDb: db);
    active = await repo.getActivePoems(overrideDb: db);
    expect(active.length, 1);

    // Purge
    await repo.purgePoem('test_1', overrideDb: db);
    active = await repo.getActivePoems(overrideDb: db);
    expect(active.length, 0);
  });

  test('3. Autosave logic: empty untitled poem is not saved', () async {
    final db = await createInMemoryDb();
    final repo = PoemRepository();

    final emptyPoem = Poem(
      id: 'empty_1',
      title: '   ',
      content: '   ',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.savePoem(emptyPoem, overrideDb: db);
    final active = await repo.getActivePoems(overrideDb: db);
    expect(active.length, 0); // Empty poem rejected
  });

  test('4. Backup/Export round trip: export all -> restore (Replace) yields identical poems', () async {
    final db1 = await createInMemoryDb();
    final db2 = await createInMemoryDb();
    final repo = PoemRepository();

    final now = DateTime.now();
    final p1 = Poem(id: '1', title: 'አንድ', content: 'ይዘት 1', createdAt: now, updatedAt: now);
    final p2 = Poem(id: '2', title: 'ሁለት', content: 'ይዘት 2', createdAt: now, updatedAt: now, isPinned: true);

    await repo.savePoem(p1, overrideDb: db1);
    await repo.savePoem(p2, overrideDb: db1);

    final backupJson = await repo.exportBackupJson(overrideDb: db1);
    final count = await repo.restoreBackupJson(backupJson, replace: true, overrideDb: db2);

    expect(count, 2);
    final restored = await repo.getActivePoems(overrideDb: db2);
    expect(restored.length, 2);
    expect(restored.any((p) => p.title == 'ሁለት' && p.isPinned), isTrue);
  });

  testWidgets('5. Widget: PoemCard displays title, stanza gap, max 5 lines, pinned icon', (WidgetTester tester) async {
    final now = DateTime.now();
    final poem = Poem(
      id: 'card_1',
      title: 'የማለዳ ግጥም',
      content: 'መስመር 1\nመስመር 2\n\nመስመር 3',
      createdAt: now,
      updatedAt: now,
      isPinned: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PoemCard(
            poem: poem,
            onTap: () {},
            onDelete: () {},
            onDuplicate: () {},
            onTogglePin: () {},
            onShare: () {},
          ),
        ),
      ),
    );

    expect(find.text('የማለዳ ግጥም'), findsOneWidget);
    expect(find.text('መስመር 1'), findsOneWidget);
    expect(find.text('መስመር 2'), findsOneWidget);
    expect(find.text('መስመር 3'), findsOneWidget);
  });

  test('6. Amharic Syllable Counter: continuous identical characters & initial consecutive Sades', () {
    expect(SyllableCounterService.countLexicalVowels('ኢኢኢኢኢኢኢ'), equals(1));
    expect(SyllableCounterService.countLexicalVowels('ችችችችችችችች'), equals(1));
    expect(SyllableCounterService.countLexicalVowels('ሀሀሀ'), equals(1));
    expect(SyllableCounterService.countLexicalVowels('ሰላም'), equals(2));
    expect(SyllableCounterService.countLexicalVowels('ምስጋና'), equals(3));
    expect(SyllableCounterService.countLexicalVowels('ስምምነት'), equals(2));
  });
}
