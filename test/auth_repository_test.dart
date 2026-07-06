import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymz_user/core/network/api_client.dart';
import 'package:gymz_user/core/storage/storage_service.dart';
import 'package:gymz_user/core/services/notification_service.dart';
import 'package:gymz_user/features/auth/data/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late ApiClient apiClient;
  late AuthRepository authRepository;

  setUp(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });

    final storageService = StorageService();
    apiClient = ApiClient(storageService);
    dio = apiClient.dio;
    authRepository = AuthRepository(apiClient);
  });

  group('AuthRepository Tests', () {
    test('sendOtp returns true on success', () async {
      // Setup mock interceptor
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/send-otp' && options.data['phone'] == '7400105833') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'message': 'OTP sent successfully'},
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final result = await authRepository.sendOtp('7400105833');
      expect(result, isTrue);
    });

    test('verifyOtp returns VerifyOtpResponse with user details if registered', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/login-otp') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'registered': true,
                    'token': 'mock_jwt_token',
                    'user': {
                      'name': 'Muzammil Qureshi',
                      'gender': 'Male',
                      'phone': '7400105833',
                      'email': '147muzammil@gmail.com',
                      'pincode': '400709',
                      'selfie': 'https://gymz.com/selfie.jpg',
                      'location': '19.0760,72.8777, Mumbai, Maharashtra',
                      'member_id': 'GZ-2026-99999',
                    }
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final response = await authRepository.verifyOtp('7400105833', '8451');
      expect(response.isRegistered, isTrue);
      expect(response.token, equals('mock_jwt_token'));
      expect(response.user, isNotNull);
      expect(response.user!.name, equals('Muzammil Qureshi'));
      expect(response.user!.memberId, equals('GZ-2026-99999'));
    });

    test('verifyOtp returns VerifyOtpResponse with isRegistered = false if unregistered', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/login-otp') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'registered': false,
                    'token': null,
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final response = await authRepository.verifyOtp('7400105833', '8451');
      expect(response.isRegistered, isFalse);
      expect(response.token, isNull);
      expect(response.user, isNull);
    });

    test('register uploads multipart details and returns UserModel', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/register') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'token': 'new_user_token',
                    'user': {
                      'name': 'Muzammil Qureshi',
                      'gender': 'Male',
                      'phone': '7400105833',
                      'email': '147muzammil@gmail.com',
                      'pincode': '400709',
                      'selfie': 'https://gymz.com/new_selfie.jpg',
                      'location': '19.0760,72.8777, Mumbai, Maharashtra',
                      'member_id': 'GZ-2026-88888',
                    }
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      // Create a temporary file to use as selfiePath for the test
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_selfie.jpg');
      await tempFile.writeAsString('dummy image data');

      final user = await authRepository.register(
        name: 'Muzammil Qureshi',
        gender: 'Male',
        phone: '7400105833',
        email: '147muzammil@gmail.com',
        pincode: '400709',
        selfiePath: tempFile.path,
        location: '19.0760,72.8777, Mumbai, Maharashtra',
      );

      expect(user.name, equals('Muzammil Qureshi'));
      expect(user.token, equals('new_user_token'));
      expect(user.memberId, equals('GZ-2026-88888'));
      expect(user.selfieUrl, equals('https://gymz.com/new_selfie.jpg'));

      // Cleanup
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('sendOtp triggers local notification when response contains otp', () async {
      final mockNotificationService = MockNotificationService();
      final testRepository = AuthRepository(apiClient, mockNotificationService);

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == 'api/v1/user/send-otp') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'OTP sent successfully',
                    'otp': '4321'
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final result = await testRepository.sendOtp('7400105833');
      expect(result, isTrue);
      expect(mockNotificationService.lastShownTitle, equals('GymZ Verification Code'));
      expect(mockNotificationService.lastShownBody, contains('4321'));
    });
  });
}

class MockNotificationService extends NotificationService {
  String? lastShownTitle;
  String? lastShownBody;
  int? lastShownId;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    lastShownId = id;
    lastShownTitle = title;
    lastShownBody = body;
  }
}
