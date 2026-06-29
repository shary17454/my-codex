import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:know_before_you_buy/app/app.dart';
import 'package:know_before_you_buy/features/welcome/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('app renders welcome screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KnowBeforeYouBuyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
