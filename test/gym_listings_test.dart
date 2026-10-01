import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymz_user/features/home/domain/gym_model.dart';
import 'package:gymz_user/features/home/application/gym_filter_provider.dart';
import 'package:gymz_user/features/home/presentation/screens/home_screen.dart';
import 'package:gymz_user/features/explore/presentation/screens/explore_screen.dart';
import 'package:gymz_user/features/home/presentation/widgets/gym_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  List<GymModel> createMockGyms(int count) {
    return List.generate(
      count,
      (index) => GymModel(
        id: 'gym_$index',
        name: 'Fitness Gym #$index',
        category: 'Gym',
        tier: 'Gold',
        distanceKm: 2.0 * (index + 1), // includes distances > 10 km (e.g. 12, 14, 16...)
        openingTime: '6:00 AM',
        closingTime: '10:00 PM',
        pricePerSession: 200,
        rating: 4.5,
        imageUrl: '',
        facilities: ['Cardio'],
        latitude: 19.0760,
        longitude: 72.8777,
      ),
    );
  }

  test('filteredGymsProvider includes all gyms without any default distance filter applied', () async {
    final mockGyms = createMockGyms(8);
    final container = ProviderContainer(
      overrides: [
        gymsListProvider.overrideWith((ref) => Future.value(mockGyms)),
      ],
    );

    // Initial state: maxDistanceProvider is null by default
    expect(container.read(maxDistanceProvider), isNull);

    // Await FutureProvider completion
    await container.read(gymsListProvider.future);

    final filtered = container.read(filteredGymsProvider);
    expect(filtered.value?.length, equals(8));
  });

  testWidgets('HomeScreen displays at most 5 gyms and triggers onSeeAllNearby', (WidgetTester tester) async {
    final mockGyms = createMockGyms(8);
    bool seeAllCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gymsListProvider.overrideWith((ref) => Future.value(mockGyms)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              ownerFirstName: 'Aasif',
              onSeeAllNearby: () {
                seeAllCalled = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify exactly 5 GymCards are rendered on the Home screen
    expect(find.byType(GymCard), findsNWidgets(5));

    // Verify "See all" button for Nearby Gyms exists and triggers callback
    final nearbyGymsSeeAll = find.widgetWithText(GestureDetector, 'See all').at(1);
    await tester.ensureVisible(nearbyGymsSeeAll);
    await tester.tap(nearbyGymsSeeAll);
    await tester.pumpAndSettle();

    expect(seeAllCalled, isTrue);
  });

  testWidgets('ExploreScreen displays all listed gyms without default filters applied', (WidgetTester tester) async {
    final mockGyms = createMockGyms(8);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gymsListProvider.overrideWith((ref) => Future.value(mockGyms)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ExploreScreen(
              onGymTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 8 gyms are rendered on the Explore screen
    expect(find.byType(GymCard), findsNWidgets(8));
  });
}
