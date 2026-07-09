import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/booking_model.dart';

class BookingResponse {
  final BookingModel booking;
  final double walletBalance;

  const BookingResponse({
    required this.booking,
    required this.walletBalance,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    final balanceVal = json['walletBalance'] ?? json['balance'] ?? 0.0;
    final balance = balanceVal is int ? balanceVal.toDouble() : (balanceVal as num).toDouble();

    return BookingResponse(
      booking: BookingModel.fromJson(json['booking'] as Map<String, dynamic>),
      walletBalance: balance,
    );
  }
}

class BookingRepository {
  const BookingRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Generate a gym booking.
  /// POST api/v1/user/bookings
  Future<BookingResponse> generateBooking({
    required String gymId,
    required String bookingDate,
    required String timeSlot,
  }) async {
    try {
      final response = await _apiClient.post(
        'api/v1/user/bookings',
        data: {
          'gymId': gymId,
          'bookingDate': bookingDate,
          'timeSlot': timeSlot,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final resData = data['data'];
          if (resData is Map<String, dynamic>) {
            return BookingResponse.fromJson(resData);
          }
        }
      }
      throw Exception('Failed to generate booking: Invalid response from server');
    } catch (e) {
      rethrow;
    }
  }

  /// Get booking history.
  /// GET api/v1/user/bookings
  Future<List<BookingModel>> getBookingHistory() async {
    try {
      final response = await _apiClient.get('api/v1/user/bookings');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final listData = data['data'];
          if (listData is List) {
            return listData
                .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
      throw Exception('Failed to load booking history');
    } catch (e) {
      rethrow;
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingRepository(apiClient);
});
