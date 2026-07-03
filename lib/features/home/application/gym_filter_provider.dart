import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../domain/gym_model.dart';

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

/// Computed provider that filters and sorts [kSampleGyms] based on active parameters.
final filteredGymsProvider = Provider<List<GymModel>>((ref) {
  final query = ref.watch(gymSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(selectedCategoryProvider);
  final tiers = ref.watch(selectedTiersProvider);
  final sortBy = ref.watch(sortByProvider);
  final maxDistance = ref.watch(maxDistanceProvider);

  List<GymModel> gyms = List.from(kSampleGyms);

  // 1. Filter by keyword query (checks name, category, facilities, or address).
  if (query.isNotEmpty) {
    gyms = gyms.where((gym) {
      final nameMatches = gym.name.toLowerCase().contains(query);
      final catMatches = gym.category.toLowerCase().contains(query);
      final addressMatches = gym.address.toLowerCase().contains(query);
      final facilityMatches = gym.facilities.any((f) => f.toLowerCase().contains(query));
      return nameMatches || catMatches || addressMatches || facilityMatches;
    }).toList();
  }

  // 2. Filter by category chip selection.
  if (category != null) {
    gyms = gyms.where((gym) => gym.category.toLowerCase() == category.toLowerCase()).toList();
  }

  // 3. Filter by membership tier.
  if (tiers.isNotEmpty) {
    gyms = gyms.where((gym) => tiers.contains(gym.tier)).toList();
  }

  // 4. Filter by distance range.
  gyms = gyms.where((gym) => gym.distanceKm <= maxDistance).toList();

  // 5. Sort listing.
  if (sortBy == 'price') {
    gyms.sort((a, b) => a.pricePerSession.compareTo(b.pricePerSession));
  } else if (sortBy == 'rating') {
    gyms.sort((a, b) => b.rating.compareTo(a.rating)); // highest rating first
  } else {
    gyms.sort((a, b) => a.distanceKm.compareTo(b.distanceKm)); // closest distance first
  }

  return gyms;
});
