import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:untitled3/main.dart';
import 'package:untitled3/repositories/poem_repository.dart';
import 'package:untitled3/services/settings_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    final settingsService = SettingsService();
    final repository = PoemRepository();

    await tester.pumpWidget(MyApp(
      settingsService: settingsService,
      repository: repository,
    ));

    expect(find.byType(MyApp), findsOneWidget);
  });
}
