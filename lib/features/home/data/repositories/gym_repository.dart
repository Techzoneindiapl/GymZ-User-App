import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/gym_model.dart';

class GymRepository {
  const GymRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetch list of gyms with optional filtering parameters.
  /// GET api/v1/user/gyms
  Future<List<GymModel>> fetchGyms({
    String? category,
    int? minPrice,
    int? maxPrice,
    String? gender,
    String? search,
  }) async {
    try {
      final queryParams = {
        'category': category ?? '',
        'minPrice': minPrice?.toString() ?? '',
        'maxPrice': maxPrice?.toString() ?? '',
        'gender': gender ?? '',
        'search': search ?? '',
      };

      final response = await _apiClient.get(
        'api/v1/user/gyms',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final gymList = data['data'] as List?;
          if (gymList != null) {
            return gymList
                .map((json) => GymModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch detailed information of a specific gym by ID.
  /// GET api/v1/user/gyms/{gymId}
  Future<GymModel> fetchGymDetails(String gymId) async {
    try {
      final response = await _apiClient.get('api/v1/user/gyms/$gymId');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final gymData = data['data'];
          if (gymData is Map<String, dynamic>) {
            return GymModel.fromJson(gymData);
          }
        }
      }
      throw Exception('Failed to load gym details');
    } catch (e) {
      rethrow;
    }
  }
}

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GymRepository(apiClient);
});
