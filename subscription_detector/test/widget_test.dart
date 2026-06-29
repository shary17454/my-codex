import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_detector/app/app.dart';

void main() {
  testWidgets('signs in and renders dashboard shell', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SubscriptionDetectorApp()),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('ادخل لاكتشاف الاشتراكات المتكررة وتحليل مصروفاتك.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(EditableText).first, 'user@example.com');
    await tester.enterText(find.byType(EditableText).last, 'password');
    await tester.tap(find.text('تسجيل الدخول').last);
    await tester.pumpAndSettle();

    expect(find.text('كاشف الاشتراكات'), findsOneWidget);
    expect(find.text('لوحة التحكم'), findsOneWidget);
  });
}
