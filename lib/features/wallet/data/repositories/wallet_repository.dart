import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/wallet_model.dart';

class WalletRepository {
  const WalletRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetch user wallet details.
  /// GET api/v1/user/wallet
  Future<WalletData> fetchWallet() async {
    try {
      final response = await _apiClient.get('api/v1/user/wallet');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final walletDataMap = data['data'];
          if (walletDataMap is Map<String, dynamic>) {
            return WalletData.fromJson(walletDataMap);
          }
        }
      }
      throw ApiException(message: 'Failed to load wallet data: Invalid response', statusCode: response.statusCode);
    } catch (e) {
      rethrow;
    }
  }

  /// Top up user wallet balance.
  /// POST api/v1/user/wallet/recharge
  Future<WalletData> addMoney(double amount, String method, {WalletData? previousWallet}) async {
    try {
      final response = await _apiClient.post(
        'api/v1/user/wallet/recharge',
        data: {
          'amount': amount,
          'paymentMethod': method,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final resData = data['data'];
          if (resData is Map<String, dynamic>) {
            final balanceVal = resData['walletBalance'] ?? resData['balance'] ?? amount;
            final newBalance = balanceVal is int ? balanceVal.toDouble() : (balanceVal as num).toDouble();
            
            final singleTxJson = resData['transaction'];
            WalletTransaction? newTx;
            if (singleTxJson is Map<String, dynamic>) {
              newTx = WalletTransaction.fromJson(singleTxJson);
            }

            // Sync with backend database to load full history if possible
            try {
              final freshWallet = await fetchWallet();
              return freshWallet;
            } catch (_) {
              // Fetch failed or database not fully populated yet; merge locally
              final oldTxList = previousWallet?.transactions ?? [];
              final mergedList = newTx != null ? [newTx, ...oldTxList] : oldTxList;
              return WalletData(
                walletBalance: newBalance,
                transactions: mergedList,
              );
            }
          }
        }
      }
      throw ApiException(message: 'Failed to recharge wallet', statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) {
        if (e.statusCode != 404 && e.statusCode != 405 && e.statusCode != 501) {
          rethrow;
        }
      } else {
        rethrow;
      }

      // Fallback in case backend doesn't support simulated top-ups (offline / prototype mock):
      try {
        final currentWallet = await fetchWallet();
        final newTransaction = WalletTransaction(
          id: 'sim-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Wallet Recharge via $method',
          amount: amount,
          type: 'credit',
          createdAt: DateTime.now(),
          dateDisplay: 'Just Now',
        );
        return WalletData(
          walletBalance: currentWallet.walletBalance + amount,
          transactions: [newTransaction, ...currentWallet.transactions],
        );
      } catch (_) {
        return WalletData(
          walletBalance: amount,
          transactions: [
            WalletTransaction(
              id: 'sim-init',
              title: 'Wallet Recharge via $method',
              amount: amount,
              type: 'credit',
              createdAt: DateTime.now(),
              dateDisplay: 'Just Now',
            ),
          ],
        );
      }
    }
  }

  /// Create a Razorpay Order.
  /// POST api/v1/user/wallet/create-order
  Future<RazorpayOrder> createRazorpayOrder(double amount) async {
    try {
      final response = await _apiClient.post(
        'api/v1/user/wallet/create-order',
        data: {
          'amount': amount,
          'currency': 'INR',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final orderData = data['data'] ?? data;
          if (orderData is Map<String, dynamic>) {
            return RazorpayOrder.fromJson(orderData);
          }
        }
      }
      throw ApiException(
        message: 'Failed to create Razorpay order',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException && (e.statusCode == 404 || e.statusCode == 501)) {
        // Fallback for development if backend create-order route is not yet deployed:
        return RazorpayOrder(
          orderId: 'order_sim_${DateTime.now().millisecondsSinceEpoch}',
          amount: (amount * 100).toInt(),
          currency: 'INR',
          razorpayKeyId: null,
        );
      }
      rethrow;
    }
  }

  /// Verify and settle Razorpay payment.
  /// POST api/v1/user/wallet/verify-payment
  Future<WalletData> verifyRazorpayPayment({
    required PaymentVerificationPayload payload,
    required double amount,
    WalletData? previousWallet,
  }) async {
    try {
      final response = await _apiClient.post(
        'api/v1/user/wallet/verify-payment',
        data: payload.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final resData = data['data'];
          if (resData is Map<String, dynamic>) {
            final balanceVal = resData['walletBalance'] ?? resData['balance'];
            if (balanceVal != null) {
              final newBalance = balanceVal is int
                  ? balanceVal.toDouble()
                  : (balanceVal as num).toDouble();
              final singleTxJson = resData['transaction'];
              WalletTransaction? newTx;
              if (singleTxJson is Map<String, dynamic>) {
                newTx = WalletTransaction.fromJson(singleTxJson);
              }

              try {
                final freshWallet = await fetchWallet();
                return freshWallet;
              } catch (_) {
                final oldTxList = previousWallet?.transactions ?? [];
                final mergedList =
                    newTx != null ? [newTx, ...oldTxList] : oldTxList;
                return WalletData(
                  walletBalance: newBalance,
                  transactions: mergedList,
                );
              }
            }
          }
        }
      }
      throw ApiException(
        message: 'Payment verification failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException && (e.statusCode == 404 || e.statusCode == 501)) {
        // Fallback if backend verify endpoint is not yet deployed:
        final currentWallet = previousWallet ?? await fetchWallet();
        final newTx = WalletTransaction(
          id: payload.razorpayPaymentId.isNotEmpty
              ? payload.razorpayPaymentId
              : 'sim-pay-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Wallet Recharge via Razorpay',
          amount: amount,
          type: 'credit',
          createdAt: DateTime.now(),
          dateDisplay: 'Just Now',
        );
        return WalletData(
          walletBalance: currentWallet.walletBalance + amount,
          transactions: [newTx, ...currentWallet.transactions],
        );
      }
      rethrow;
    }
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRepository(apiClient);
});
