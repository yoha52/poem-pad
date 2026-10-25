import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:untitled3/services/syllable_counter_service.dart';
import 'package:untitled3/utils/units.dart';
import 'package:untitled3/widgets/custom_text_field.dart';

const double _lineBox = Units.fontSize * 1.5;

Future<TextEditingController> _pump(
  WidgetTester tester, {
  String text = '',
  Size size = const Size(500, 600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final title = TextEditingController();
  final body = TextEditingController(text: text);
  addTearDown(title.dispose);
  addTearDown(body.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomTextField(titleController: title, bodyController: body),
      ),
    ),
  );
  await tester.pump();
  return body;
}

dynamic _state(WidgetTester tester) => tester.state(find.byType(CustomTextField));
List<double> _tops(WidgetTester tester) => List<double>.from(_state(tester).debugPillTops as List);
List<int> _counts(WidgetTester tester) => List<int>.from(_state(tester).debugPillCounts as List);

void main() {
  testWidgets('1. empty text: one line at the top, no exceptions', (tester) async {
    await _pump(tester);
    expect(_tops(tester), <double>[0.0]);
    expect(_counts(tester), <int>[0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2. short lines sit exactly one line box apart', (tester) async {
    await _pump(tester, text: 'ሀ\nለ\n\nሐ');
    final tops = _tops(tester);
    expect(tops.length, 4);
    for (int i = 0; i < tops.length; i++) {
      expect(tops[i], closeTo(i * _lineBox, 0.01));
    }
    expect(_counts(tester)[2], 0); // the empty line has no count
    expect(tester.takeException(), isNull);
  });

  testWidgets('3. a long wrapped line pushes the next pill down by whole lines', (tester) async {
    final long = List.filled(200, 'ሀ').join();
    await _pump(tester, text: '$long\nሀ');
    final tops = _tops(tester);
    expect(tops.length, 2);
    expect(tops[0], 0.0);
    expect(tops[1], greaterThanOrEqualTo(2 * _lineBox)); // it really wrapped
    expect((tops[1] / _lineBox) % 1.0, closeTo(0.0, 1e-6)); // whole line boxes
    expect(_counts(tester)[0], SyllableCounterService.countLexicalVowels(long));
    expect(tester.takeException(), isNull);
  });

  testWidgets('4. resizing the window re-wraps and moves the pills', (tester) async {
    final long = List.filled(60, 'ሀ').join();
    final body = await _pump(tester, text: '$long\nሀ', size: const Size(900, 600));
    final wide = _tops(tester)[1];

    tester.view.physicalSize = const Size(320, 600);
    await tester.pump();
    await tester.pump();
    final narrow = _tops(tester)[1];

    expect(narrow, greaterThan(wide)); // narrower => more wraps => pill 2 lower
    expect(body.text, '$long\nሀ');
    expect(tester.takeException(), isNull);
  });

  testWidgets('5. 200-line paste, typing, and scrolling stay correct and cheap', (tester) async {
    final lines = List.generate(200, (i) => 'ሀለሐ$i');
    final body = await _pump(tester);

    body.text = lines.join('\n'); // simulates a paste
    await tester.pump();
    expect(_tops(tester).length, 200);
    expect(_tops(tester).last, closeTo(199 * _lineBox, 0.01));

    // Scrolling must NOT recompute the layout (same list instance reused).
    final before = _state(tester).debugPillTops;
    await tester.drag(find.byType(TextField).last, const Offset(0, -400));
    await tester.pump();
    final after = _state(tester).debugPillTops;
    expect(identical(before, after), isTrue);

    // Typing a new line updates counts.
    body.text = '${lines.join('\n')}\nሀ';
    await tester.pump();
    expect(_tops(tester).length, 201);
    expect(tester.takeException(), isNull);
  });
}
