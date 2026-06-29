import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_detector/features/ocr/domain/entities/ocr_result.dart';
import 'package:price_detector/features/ocr/presentation/screens/ocr_result_screen.dart';

void main() {
  testWidgets('shows the price analysis result', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OcrResultScreen(
            result: OcrResult(
              rawText: 'Coffee Beans\nPrice 32.00',
              productName: 'Coffee Beans',
              price: 32,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        '\u0627\u0644\u062a\u0648\u0635\u064a\u0629 '
        '\u0627\u0644\u0646\u0647\u0627\u0626\u064a\u0629',
      ),
      findsOneWidget,
    );
    expect(find.text('Coffee Beans'), findsWidgets);
    expect(find.text('32.00'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('\u0645\u0645\u062a\u0627\u0632'), findsOneWidget);
  });
}
