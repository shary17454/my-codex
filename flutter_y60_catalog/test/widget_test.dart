import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:patrol_hub/main.dart';

void main() {
  testWidgets('shows official Patrol Hub landing page', (tester) async {
    await tester.pumpWidget(const PatrolHubApp());

    expect(find.text('Patrol Hub'), findsOneWidget);
    expect(find.text('نيسان باترول Y60'), findsOneWidget);
    expect(find.text('عربي و RTL'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('patrolsafariy60@gmail.com'),
      900,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('patrolsafariy60@gmail.com'), findsOneWidget);
  });

  test('includes the generated catalog index asset', () {
    final indexFile = File('assets/catalog/search/catalog_search_index.json');

    expect(indexFile.existsSync(), isTrue);
    expect(indexFile.lengthSync(), greaterThan(15000000));
  });

  testWidgets('searches the generated catalog index by chassis number',
      (tester) async {
    await tester.pumpWidget(const PatrolHubApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.scrollUntilVisible(
      find.byType(TextField),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(EditableText).first, 'WGY60-348567');
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('WGY60-348567'), findsWidgets);
  });
}
