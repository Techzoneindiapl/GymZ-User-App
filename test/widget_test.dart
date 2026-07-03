import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymz_user/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: GymzUserApp()));

    // Verify onboarding screen title is shown.
    expect(find.text('Discover Gyms Around You'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
  });
}
