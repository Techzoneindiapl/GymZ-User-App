import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymz_user/features/gym_detail/presentation/screens/gym_detail_screen.dart';
import 'package:gymz_user/features/home/domain/gym_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  testWidgets('GymDetailScreen renders correctly without exception', (WidgetTester tester) async {
    const gym = GymModel(
      id: 'test_gym',
      name: 'Test Gym Name',
      category: 'Gym',
      tier: 'Platinum',
      distanceKm: 1.2,
      openingTime: '6:00 AM',
      closingTime: '10:00 PM',
      pricePerSession: 300,
      rating: 4.5,
      imageUrl: '',
      facilities: ['Cardio', 'Weight Training', 'Steam'],
      usageInstructions: ['Wear gym shoes', 'Bring water'],
      latitude: 19.0,
      longitude: 72.0,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GymDetailScreen(
            gym: gym,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify name is rendered
    expect(find.text('Test Gym Name'), findsOneWidget);
    // Verify facilities title is rendered
    expect(find.text('Facilities'), findsOneWidget);
  });
}
