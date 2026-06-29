import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_detector/app/app.dart';

void main() {
  testWidgets('signs in and shows the home screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PriceDetectorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\u0643\u0627\u0634\u0641 \u0627\u0644\u0623\u0633\u0639\u0627\u0631',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(EditableText).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(EditableText).last, 'password');
    await tester.tap(
      find.text('\u062f\u062e\u0648\u0644'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\u0627\u0644\u0635\u0641\u062d\u0629 '
        '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
  });
}
