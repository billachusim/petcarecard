import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_care_card/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: PetCareCardApp(),
      ),
    );

    // Verify that onboarding is shown.
    expect(find.text('Leaving your pet with someone?'), findsOneWidget);
  });
}
