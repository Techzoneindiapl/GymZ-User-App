import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gym_detail/data/repositories/booking_repository.dart';
import '../../gym_detail/domain/booking_model.dart';

class BookingHistoryNotifier extends AsyncNotifier<List<BookingModel>> {
  @override
  FutureOr<List<BookingModel>> build() async {
    final repository = ref.watch(bookingRepositoryProvider);
    return await repository.getBookingHistory();
  }

  Future<void> refreshHistory() async {
    state = const AsyncValue.loading();
    final repository = ref.read(bookingRepositoryProvider);
    try {
      final history = await repository.getBookingHistory();
      state = AsyncValue.data(history);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void addBooking(BookingModel newBooking) {
    final current = state.value ?? [];
    state = AsyncValue.data([newBooking, ...current]);
  }
}

final bookingHistoryProvider = AsyncNotifierProvider<BookingHistoryNotifier, List<BookingModel>>(
  BookingHistoryNotifier.new,
);
