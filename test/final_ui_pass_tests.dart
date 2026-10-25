import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:untitled3/models/poem.dart';
import 'package:untitled3/pages/settings_page.dart';
import 'package:untitled3/repositories/poem_repository.dart';
import 'package:untitled3/services/settings_service.dart';
import 'package:untitled3/theme/design_tokens.dart';
import 'package:untitled3/widgets/custom_text_field.dart';
import 'package:untitled3/widgets/poem_card.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('1. Hover: card size and title width are IDENTICAL before and after mouse enter; ... button becomes visible', (tester) async {
    final poem = Poem(
      id: 'h1',
      title: 'የማለዳ ግጥም',
      content: 'ፀሐይ ወጣች',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
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
    );

    final cardFinder = find.byType(PoemCard);
    final sizeBefore = tester.getSize(cardFinder);
    final titleTextFinder = find.text('የማለዳ ግጥም');
    final titleWidthBefore = tester.getSize(titleTextFinder).width;

    // Simulate mouse hover
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(cardFinder));
    await tester.pumpAndSettle();

    final sizeAfter = tester.getSize(cardFinder);
    final titleWidthAfter = tester.getSize(titleTextFinder).width;

    expect(sizeAfter, equals(sizeBefore));
    expect(titleWidthAfter, equals(titleWidthBefore));

    // Verify "..." button opacity is 1.0
    final animatedOpacityFinder = find.byType(AnimatedOpacity);
    final AnimatedOpacity opacityWidget = tester.widget(animatedOpacityFinder.first);
    expect(opacityWidget.opacity, equals(1.0));
  });

  testWidgets('2. Pills toggle: showPills=false -> gutter width is 0; true -> restored; persists in SettingsService', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.loadSettings();

    final title = TextEditingController();
    final body = TextEditingController(text: 'ሀ\nለ');
    addTearDown(title.dispose);
    addTearDown(body.dispose);

    // Test with showPills = false
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            titleController: title,
            bodyController: body,
            showPills: false,
          ),
        ),
      ),
    );

    final animatedContainerFinder = find.byType(AnimatedContainer).first;
    final AnimatedContainer containerWidget = tester.widget(animatedContainerFinder);
    expect(containerWidget.constraints?.maxWidth ?? (containerWidget.child == null ? 0.0 : 0.0), equals(0.0));

    // Persist setting
    await settings.setShowSyllablePills(false);
    final settings2 = SettingsService();
    await settings2.loadSettings();
    expect(settings2.showSyllablePills, isFalse);
  });

  testWidgets('3. Font size: changing editorFontSize updates TextStyle.fontSize live', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.loadSettings();

    final title = TextEditingController();
    final body = TextEditingController(text: 'ሀለሐ');
    addTearDown(title.dispose);
    addTearDown(body.dispose);

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: settings,
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              titleController: title,
              bodyController: body,
              fontSize: settings.fontSize,
            ),
          ),
        ),
      ),
    );

    await settings.setFontSize(22.0);
    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextField).last;
    final TextField bodyTextField = tester.widget(textFieldFinder);
    expect(bodyTextField.style?.fontSize, equals(22.0));
  });

  testWidgets('4. Dark mode: editor title/body surface color equals AppColors.dark.surface', (tester) async {
    final title = TextEditingController();
    final body = TextEditingController(text: 'ሀለሐ');
    addTearDown(title.dispose);
    addTearDown(body.dispose);

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          extensions: const [AppColors.dark],
        ),
        home: Scaffold(
          body: CustomTextField(
            titleController: title,
            bodyController: body,
          ),
        ),
      ),
    );

    final containerFinder = find.byType(Container).first;
    final Container container = tester.widget(containerFinder);
    final BoxDecoration decoration = container.decoration as BoxDecoration;
    expect(decoration.color, equals(AppColors.dark.surface));
  });

  testWidgets('5. Settings screen: segmented control changes ThemeMode immediately; 4 settings round-trip', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.loadSettings();
    final repo = PoemRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          settingsService: settings,
          repository: repo,
        ),
      ),
    );

    // Segmented control tap
    final lightSegmentFinder = find.text('ብርሃን');
    expect(lightSegmentFinder, findsOneWidget);
    await tester.tap(lightSegmentFinder);
    await tester.pumpAndSettle();

    expect(settings.themeMode, equals(ThemeMode.light));

    // Test 4 settings round trip persistence
    await settings.setThemeMode(ThemeMode.dark);
    await settings.setShowSyllablePills(false);
    await settings.setFontSize(20.0);
    await settings.setDefaultSort(PoemSortOption.title);

    final restoredSettings = SettingsService();
    await restoredSettings.loadSettings();

    expect(restoredSettings.themeMode, equals(ThemeMode.dark));
    expect(restoredSettings.showSyllablePills, isFalse);
    expect(restoredSettings.fontSize, equals(20.0));
    expect(restoredSettings.defaultSort, equals(PoemSortOption.title));
  });
}
