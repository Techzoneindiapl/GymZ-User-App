import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymz_user/core/network/api_client.dart';
import 'package:gymz_user/core/storage/storage_service.dart';
import 'package:gymz_user/features/wallet/data/repositories/wallet_repository.dart';
import 'package:gymz_user/features/wallet/domain/wallet_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late ApiClient apiClient;
  late WalletRepository walletRepository;

  setUp(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });

    final storageService = StorageService();
    apiClient = ApiClient(storageService);
    dio = apiClient.dio;
    walletRepository = WalletRepository(apiClient);
  });

  group('Razorpay Wallet Domain Models', () {
    test('RazorpayOrder serializes and deserializes correctly', () {
      final json = {
        'orderId': 'order_123456789',
        'amount': 50000,
        'currency': 'INR',
        'razorpayKeyId': 'rzp_test_sampleKey',
      };

      final order = RazorpayOrder.fromJson(json);
      expect(order.orderId, equals('order_123456789'));
      expect(order.amount, equals(50000));
      expect(order.currency, equals('INR'));
      expect(order.razorpayKeyId, equals('rzp_test_sampleKey'));

      final mapped = order.toJson();
      expect(mapped['orderId'], equals('order_123456789'));
      expect(mapped['amount'], equals(50000));
      expect(mapped['currency'], equals('INR'));
      expect(mapped['razorpayKeyId'], equals('rzp_test_sampleKey'));
    });

    test('PaymentVerificationPayload serializes correctly', () {
      const payload = PaymentVerificationPayload(
        razorpayOrderId: 'order_123',
        razorpayPaymentId: 'pay_456',
        razorpaySignature: 'sig_789',
      );

      final json = payload.toJson();
      expect(json['razorpayOrderId'], equals('order_123'));
      expect(json['razorpayPaymentId'], equals('pay_456'));
      expect(json['razorpaySignature'], equals('sig_789'));
    });

    test('WalletTransaction parses failed and cancelled statuses correctly', () {
      final failedJson = {
        'id': 'tx_failed_1',
        'title': 'Wallet Top-up (Failed)',
        'amount': 250.0,
        'type': 'failed',
        'status': 'failed',
      };
      final failedTx = WalletTransaction.fromJson(failedJson);
      expect(failedTx.isFailedOrCancelled, isTrue);
      expect(failedTx.status, equals('failed'));

      final cancelledJson = {
        'id': 'tx_cancelled_1',
        'title': 'Wallet Top-up (Cancelled)',
        'amount': 100.0,
        'type': 'failed',
        'status': 'cancelled',
      };
      final cancelledTx = WalletTransaction.fromJson(cancelledJson);
      expect(cancelledTx.isFailedOrCancelled, isTrue);
      expect(cancelledTx.status, equals('cancelled'));

      final successJson = {
        'id': 'tx_success_1',
        'title': 'Wallet Recharge',
        'amount': 500.0,
        'type': 'credit',
        'status': 'success',
      };
      final successTx = WalletTransaction.fromJson(successJson);
      expect(successTx.isFailedOrCancelled, isFalse);
    });

    test('Custom amount boundaries validation (Min ₹1, Max ₹5000)', () {
      bool isValidAmount(double amount) => amount >= 1 && amount <= 5000;

      expect(isValidAmount(0), isFalse);
      expect(isValidAmount(0.5), isFalse);
      expect(isValidAmount(1), isTrue);
      expect(isValidAmount(250), isTrue);
      expect(isValidAmount(5000), isTrue);
      expect(isValidAmount(5001), isFalse);
      expect(isValidAmount(10000), isFalse);
    });

    test('Transaction history filter correctly separates Credits, Debits, and Failed', () {
      final txs = [
        const WalletTransaction(id: '1', title: 'Top-up Success', amount: 500, type: 'credit', status: 'success'),
        const WalletTransaction(id: '2', title: 'Gym Check-in', amount: 120, type: 'debit', status: 'success'),
        const WalletTransaction(id: '3', title: 'Top-up Failed', amount: 300, type: 'failed', status: 'failed'),
        const WalletTransaction(id: '4', title: 'Top-up Cancelled', amount: 100, type: 'failed', status: 'cancelled'),
      ];

      final credits = txs.where((tx) => !tx.isFailedOrCancelled && tx.type == 'credit').toList();
      expect(credits.length, equals(1));
      expect(credits.first.id, equals('1'));

      final debits = txs.where((tx) => !tx.isFailedOrCancelled && tx.type != 'credit').toList();
      expect(debits.length, equals(1));
      expect(debits.first.id, equals('2'));

      final failed = txs.where((tx) => tx.isFailedOrCancelled).toList();
      expect(failed.length, equals(2));
      expect(failed.map((t) => t.id), containsAll(['3', '4']));
    });

    test('Transaction history limits to latest 5 on main screen and retains full count for modal', () {
      final manyTxs = List.generate(
        12,
        (i) => WalletTransaction(
          id: 'tx_$i',
          title: 'Transaction $i',
          amount: (i + 1) * 50.0,
          type: i % 2 == 0 ? 'credit' : 'debit',
          status: 'success',
        ),
      );

      final latest5 = manyTxs.take(5).toList();
      expect(latest5.length, equals(5));
      expect(latest5.first.id, equals('tx_0'));
      expect(latest5.last.id, equals('tx_4'));
      expect(manyTxs.length, equals(12));
    });
  });

  group('WalletRepository Razorpay API Tests', () {
    test('createRazorpayOrder calls api/v1/user/wallet/create-order and parses order successfully', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/wallet/create-order') {
              expect(options.data['amount'], equals(500.0));
              expect(options.data['currency'], equals('INR'));

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'orderId': 'order_test_razorpay_999',
                      'amount': 50000,
                      'currency': 'INR',
                      'razorpayKeyId': 'rzp_test_mockKeyId',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final order = await walletRepository.createRazorpayOrder(500.0);
      expect(order.orderId, equals('order_test_razorpay_999'));
      expect(order.amount, equals(50000));
      expect(order.currency, equals('INR'));
      expect(order.razorpayKeyId, equals('rzp_test_mockKeyId'));
    });

    test('verifyRazorpayPayment calls api/v1/user/wallet/verify-payment and parses updated balance', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/wallet/verify-payment') {
              expect(options.data['razorpayOrderId'], equals('order_test_razorpay_999'));
              expect(options.data['razorpayPaymentId'], equals('pay_mock_111'));
              expect(options.data['razorpaySignature'], equals('sig_valid_222'));

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'walletBalance': 1500.0,
                      'transaction': {
                        'id': 'tx_razorpay_1',
                        'title': 'Wallet Recharge via Razorpay',
                        'amount': 500.0,
                        'type': 'credit',
                        'dateDisplay': 'Today, 5:30 PM',
                      },
                    },
                  },
                ),
              );
            }
            if (options.path == 'api/v1/user/wallet') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'walletBalance': 1500.0,
                      'transactions': [
                        {
                          'id': 'tx_razorpay_1',
                          'title': 'Wallet Recharge via Razorpay',
                          'amount': 500.0,
                          'type': 'credit',
                          'dateDisplay': 'Today, 5:30 PM',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      const payload = PaymentVerificationPayload(
        razorpayOrderId: 'order_test_razorpay_999',
        razorpayPaymentId: 'pay_mock_111',
        razorpaySignature: 'sig_valid_222',
      );

      final wallet = await walletRepository.verifyRazorpayPayment(
        payload: payload,
        amount: 500.0,
      );

      expect(wallet.walletBalance, equals(1500.0));
      expect(wallet.transactions, isNotEmpty);
      expect(wallet.transactions.first.amount, equals(500.0));
      expect(wallet.transactions.first.type, equals('credit'));
    });
  });
}
