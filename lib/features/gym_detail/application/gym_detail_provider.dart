import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/gym_model.dart';
import '../../home/data/repositories/gym_repository.dart';

/// Provider that fetches gym details by gymId.
final gymDetailsProvider = FutureProvider.family<GymModel, String>((ref, gymId) async {
  final repository = ref.watch(gymRepositoryProvider);
  return await repository.fetchGymDetails(gymId);
});
