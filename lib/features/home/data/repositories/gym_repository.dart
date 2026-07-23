import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymz_user/features/pass/domain/review_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
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

  /// Get list of gyms pending reviews.
  /// GET api/v1/user/gyms/pending-reviews
  Future<List<GymModel>> fetchPendingReviews() async {
    try {
      final response = await _apiClient.get('api/v1/user/gyms/pending-reviews');

      if (response.statusCode == 200 || response.statusCode == 201) {
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
      throw ApiException(message: 'Failed to load gym details', statusCode: response.statusCode);
    } catch (e) {
      rethrow;
    }
  }

  /// Submit a review for a specific gym by ID.
  /// POST api/v1/user/gyms/{gymId}/reviews
  Future<void> submitReview({
    required String gymId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await _apiClient.post(
        'api/v1/user/gyms/$gymId/reviews',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(message: 'Failed to submit review', statusCode: response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's submitted reviews.
  /// GET api/v1/user/reviews/my-reviews
  Future<List<ReviewModel>> fetchMyReviews() async {
    try {
      final response = await _apiClient.get('api/v1/user/reviews/my-reviews');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final reviewList = data['data'] as List?;
          if (reviewList != null) {
            return reviewList
                .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GymRepository(apiClient);
});
