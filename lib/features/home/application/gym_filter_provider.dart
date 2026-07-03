import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../domain/gym_model.dart';
import '../data/repositories/gym_repository.dart';

/// Provider holding the current search query string.
final gymSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider holding the selected category name (e.g. Gym, Yoga, etc.), or null if none.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider holding the list of selected membership tiers (e.g. Platinum, Diamond).
final selectedTiersProvider = StateProvider<List<String>>((ref) => const []);

/// Provider holding the sort criteria ('distance', 'price', 'rating').
final sortByProvider = StateProvider<String>((ref) => 'distance');

/// Provider holding the maximum distance range in km.
final maxDistanceProvider = StateProvider<double>((ref) => 10.0);

/// FutureProvider that fetches the list of gyms from the backend API.
/// It re-runs whenever search query or category filter changes.
final gymsListProvider = FutureProvider<List<GymModel>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(gymSearchQueryProvider);
  final repository = ref.watch(gymRepositoryProvider);

  return await repository.fetchGyms(
    category: category,
    search: search,
  );
});

/// Computed provider that filters and sorts backend gyms list based on active parameters.
final filteredGymsProvider = Provider<AsyncValue<List<GymModel>>>((ref) {
  final gymsAsync = ref.watch(gymsListProvider);
  final tiers = ref.watch(selectedTiersProvider);
  final sortBy = ref.watch(sortByProvider);
  final maxDistance = ref.watch(maxDistanceProvider);

  return gymsAsync.whenData((gymList) {
    List<GymModel> gyms = List.from(gymList);

    // 1. Filter by membership tier.
    if (tiers.isNotEmpty) {
      gyms = gyms.where((gym) => tiers.contains(gym.tier)).toList();
    }

    // 2. Filter by distance range.
    gyms = gyms.where((gym) => gym.distanceKm <= maxDistance).toList();

    // 3. Sort listing.
    if (sortBy == 'price') {
      gyms.sort((a, b) => a.pricePerSession.compareTo(b.pricePerSession));
    } else if (sortBy == 'rating') {
      gyms.sort((a, b) => b.rating.compareTo(a.rating)); // highest rating first
    } else {
      gyms.sort((a, b) => a.distanceKm.compareTo(b.distanceKm)); // closest distance first
    }

    return gyms;
  });
});
