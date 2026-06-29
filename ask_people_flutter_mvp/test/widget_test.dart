import 'package:ask_people/app/ask_people_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the start page', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AskPeopleApp()),
    );

    expect(find.text('اسأل الناس'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
  });
}
