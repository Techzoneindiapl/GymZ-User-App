import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/razorpay_service.dart';
import '../../auth/application/auth_provider.dart';
import '../data/repositories/wallet_repository.dart';
import '../domain/wallet_model.dart';

class WalletTopUpResult {
  final bool success;
  final bool isCancelled;
  final String? message;

  const WalletTopUpResult({
    required this.success,
    this.isCancelled = false,
    this.message,
  });
}

class WalletNotifier extends AsyncNotifier<WalletData> {
  @override
  FutureOr<WalletData> build() async {
    final repository = ref.watch(walletRepositoryProvider);
    return await repository.fetchWallet();
  }

  Future<bool> addMoney(double amount, String method) async {
    final previousWallet = state.value;
    state = const AsyncValue.loading();
    final repository = ref.read(walletRepositoryProvider);
    
    try {
      final updatedWallet = await repository.addMoney(amount, method, previousWallet: previousWallet);
      state = AsyncValue.data(updatedWallet);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Top up wallet using Razorpay checkout.
  /// 1. Create order on backend (receives orderId and keyId).
  /// 2. Open Razorpay checkout sheet with prefilled user phone/email.
  /// 3. Verify payment signature on backend.
  /// 4. Update wallet state with credited funds.
  /// 5. On failure or cancellation, records the failed attempt in transaction history
  ///    and preserves the existing wallet balance display without crashing the screen.
  Future<WalletTopUpResult> rechargeWithRazorpay({
    required double amount,
    String? contactPhone,
    String? contactEmail,
    String fallbackKeyId = 'rzp_test_1DP5mmOlF5G5ag',
  }) async {
    final previousWallet = state.value;
    final repository = ref.read(walletRepositoryProvider);
    final razorpayService = ref.read(razorpayServiceProvider);

    // Auto-detect user details if not explicitly passed
    final user = ref.read(authProvider).user;
    final phone = contactPhone ?? user?.phone;
    final email = contactEmail ?? user?.email;

    try {
      // Step 1: Create Order on backend
      final order = await repository.createRazorpayOrder(amount);
      final keyId = (order.razorpayKeyId != null && order.razorpayKeyId!.isNotEmpty)
          ? order.razorpayKeyId!
          : fallbackKeyId;

      // Step 2: Open Razorpay checkout sheet
      final checkoutResult = await razorpayService.openCheckout(
        keyId: keyId,
        orderId: order.orderId,
        amountInPaise: order.amount > 0 ? order.amount : (amount * 100).toInt(),
        description: 'GymZ Wallet Top-up',
        contactPhone: phone,
        contactEmail: email,
      );

      // Step 3: Handle checkout response
      switch (checkoutResult) {
        case RazorpaySuccessResult success:
          state = const AsyncValue.loading();
          final verificationPayload = PaymentVerificationPayload(
            razorpayOrderId: success.orderId ?? order.orderId,
            razorpayPaymentId: success.paymentId,
            razorpaySignature: success.signature ?? '',
          );

          // Step 4: Verify cryptographic signature on backend
          final updatedWallet = await repository.verifyRazorpayPayment(
            payload: verificationPayload,
            amount: amount,
            previousWallet: previousWallet,
          );

          state = AsyncValue.data(updatedWallet);
          return const WalletTopUpResult(success: true);

        case RazorpayFailureResult failure:
          _recordFailedTransaction(
            amount: amount,
            isCancelled: failure.isCancelled,
            fallbackWallet: previousWallet,
          );
          return WalletTopUpResult(
            success: false,
            isCancelled: failure.isCancelled,
            message: failure.message,
          );

        case RazorpayExternalWalletResult externalWallet:
          return WalletTopUpResult(
            success: false,
            message: 'External wallet (${externalWallet.walletName}) selected. Please complete payment inside the wallet app.',
          );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _recordFailedTransaction(
        amount: amount,
        isCancelled: false,
        fallbackWallet: previousWallet,
      );
      return WalletTopUpResult(
        success: false,
        message: errorMsg,
      );
    }
  }

  void _recordFailedTransaction({
    required double amount,
    required bool isCancelled,
    WalletData? fallbackWallet,
  }) {
    final currentWallet = state.value ?? fallbackWallet;
    if (currentWallet == null) return;

    final failedTx = WalletTransaction(
      id: 'tx-${isCancelled ? "can" : "fail"}-${DateTime.now().millisecondsSinceEpoch}',
      title: isCancelled ? 'Wallet Top-up (Cancelled)' : 'Wallet Top-up (Failed)',
      amount: amount,
      type: 'failed',
      status: isCancelled ? 'cancelled' : 'failed',
      createdAt: DateTime.now(),
      dateDisplay: 'Just Now',
    );

    final updatedWallet = WalletData(
      walletBalance: currentWallet.walletBalance,
      transactions: [failedTx, ...currentWallet.transactions],
    );

    state = AsyncValue.data(updatedWallet);
  }

  Future<void> refreshWallet() async {
    state = const AsyncValue.loading();
    final repository = ref.read(walletRepositoryProvider);
    
    try {
      final updatedWallet = await repository.fetchWallet();
      state = AsyncValue.data(updatedWallet);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void updateWallet(WalletData newWallet) {
    state = AsyncValue.data(newWallet);
  }
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletData>(WalletNotifier.new);
