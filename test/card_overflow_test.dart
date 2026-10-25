import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:untitled3/models/poem.dart';
import 'package:untitled3/pages/home_page.dart';
import 'package:untitled3/repositories/poem_repository.dart';
import 'package:untitled3/services/settings_service.dart';
import 'package:untitled3/widgets/poem_card.dart';

class FakePoemRepository extends PoemRepository {
  final List<Poem> poems;

  FakePoemRepository(this.poems);

  @override
  Future<void> migrateFromSharedPreferencesIfNeeded({Database? overrideDb}) async {}

  @override
  Future<List<Poem>> getActivePoems({
    String? query,
    String? selectedTag,
    PoemSortOption sortOption = PoemSortOption.lastEdited,
    Database? overrideDb,
  }) async {
    return Future.value(poems);
  }

  @override
  Future<List<String>> getAllTags({Database? overrideDb}) async {
    return Future.value([]);
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets(
    '1. PoemCard never overflows at widths [100, 140, 180, 260, 400] x textScale [1.0, 1.5], light & dark',
    (tester) async {
      final poem = Poem(
        id: 'p1',
        title: 'የማለዳ ግጥም ረጅም ርዕስ',
        content: 'ፀሐይ ከተራራው ጀርባ ወጣች፣\nወፎች ዘመሩ።',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final widths = [100.0, 140.0, 180.0, 260.0, 400.0];
      final scales = [1.0, 1.5];
      final modes = [ThemeMode.light, ThemeMode.dark];

      for (var w in widths) {
        for (var s in scales) {
          for (var m in modes) {
            tester.view.physicalSize = Size(w, 600);
            tester.view.devicePixelRatio = 1.0;

            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(s)),
                child: MaterialApp(
                  themeMode: m,
                  home: Scaffold(
                    body: SizedBox(
                      width: w,
                      child: PoemCard(
                        poem: poem,
                        onTap: () {},
                        onDelete: () {},
                        onDuplicate: () {},
                        onTogglePin: () {},
                        onShare: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );

            expect(tester.takeException(), isNull);
          }
        }
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    '2. Home grid at window width 490 builds exactly 2 columns',
    (tester) async {
      tester.view.physicalSize = const Size(490, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final fakeRepo = FakePoemRepository([
        Poem(id: '1', title: 'ሀ', content: 'ሀ', createdAt: now, updatedAt: now),
        Poem(id: '2', title: 'ለ', content: 'ለ', createdAt: now, updatedAt: now),
      ]);
      final settings = SettingsService();

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            repository: fakeRepo,
            settingsService: settings,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify 2 columns rendered side-by-side
      final cards = find.byType(PoemCard);
      expect(cards, findsNWidgets(2));

      final pos1 = tester.getTopLeft(cards.at(0));
      final pos2 = tester.getTopLeft(cards.at(1));

      expect(pos1.dy, equals(pos2.dy)); // Both in top row => 2 columns
      expect(pos2.dx, greaterThan(pos1.dx));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
