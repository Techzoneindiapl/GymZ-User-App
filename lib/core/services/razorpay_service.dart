import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

sealed class RazorpayCheckoutResult {}

class RazorpaySuccessResult extends RazorpayCheckoutResult {
  final String paymentId;
  final String? orderId;
  final String? signature;

  RazorpaySuccessResult({
    required this.paymentId,
    this.orderId,
    this.signature,
  });
}

class RazorpayFailureResult extends RazorpayCheckoutResult {
  final int? code;
  final String message;
  final bool isCancelled;

  RazorpayFailureResult({
    this.code,
    required this.message,
    this.isCancelled = false,
  });
}

class RazorpayExternalWalletResult extends RazorpayCheckoutResult {
  final String walletName;

  RazorpayExternalWalletResult({required this.walletName});
}

class RazorpayService {
  RazorpayService() {
    _init();
  }

  late final Razorpay _razorpay;
  Completer<RazorpayCheckoutResult>? _checkoutCompleter;

  void _init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_checkoutCompleter != null && !_checkoutCompleter!.isCompleted) {
      _checkoutCompleter!.complete(
        RazorpaySuccessResult(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId,
          signature: response.signature,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_checkoutCompleter != null && !_checkoutCompleter!.isCompleted) {
      final code = response.code;
      final rawMsg = response.message?.trim() ?? '';

      final bool isCancelled = code == Razorpay.PAYMENT_CANCELLED ||
          code == 0 ||
          rawMsg.toLowerCase().contains('cancel') ||
          rawMsg.toLowerCase().contains('dismiss');

      final String msg = isCancelled
          ? 'Payment cancelled by user'
          : (rawMsg.isNotEmpty
              ? rawMsg
              : (code == Razorpay.NETWORK_ERROR
                  ? 'Network error. Please check your connection and try again.'
                  : 'Payment failed (Error code: $code). Please try again.'));

      _checkoutCompleter!.complete(
        RazorpayFailureResult(
          code: code,
          message: msg,
          isCancelled: isCancelled,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_checkoutCompleter != null && !_checkoutCompleter!.isCompleted) {
      _checkoutCompleter!.complete(
        RazorpayExternalWalletResult(walletName: response.walletName ?? 'External Wallet'),
      );
    }
  }

  Future<RazorpayCheckoutResult> openCheckout({
    required String keyId,
    required String orderId,
    required int amountInPaise,
    required String description,
    String? contactPhone,
    String? contactEmail,
    String? businessName = 'GymZ',
    String? themeHexColor = '#C6FF00',
  }) async {
    if (_checkoutCompleter != null && !_checkoutCompleter!.isCompleted) {
      _checkoutCompleter!.complete(
        RazorpayFailureResult(message: 'Previous payment was cancelled'),
      );
    }

    _checkoutCompleter = Completer<RazorpayCheckoutResult>();

    final options = {
      'key': keyId,
      'amount': amountInPaise,
      'name': businessName,
      'order_id': orderId,
      'description': description,
      'timeout': 300, // 5 minutes
      'prefill': {
        if (contactPhone != null && contactPhone.isNotEmpty) 'contact': contactPhone,
        if (contactEmail != null && contactEmail.isNotEmpty) 'email': contactEmail,
      },
      'theme': {
        'color': themeHexColor,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
      return RazorpayFailureResult(message: 'Could not open payment window: $e');
    }

    return _checkoutCompleter!.future;
  }

  void dispose() {
    _razorpay.clear();
  }
}

final razorpayServiceProvider = Provider<RazorpayService>((ref) {
  final service = RazorpayService();
  ref.onDispose(service.dispose);
  return service;
});
