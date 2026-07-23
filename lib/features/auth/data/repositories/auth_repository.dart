import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_exceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/user_model.dart';

class VerifyOtpResponse {
  const VerifyOtpResponse({
    required this.isRegistered,
    this.token,
    this.user,
  });

  final bool isRegistered;
  final String? token;
  final UserModel? user;
}

class AuthRepository {
  const AuthRepository(this._apiClient, [this._notificationService]);

  final ApiClient _apiClient;
  final NotificationService? _notificationService;

  /// Send OTP to the user's phone number.
  /// POST api/v1/user/send-otp
  Future<bool> sendOtp(String phone) async {
    try {
      final response = await _apiClient.post(
        'api/v1/user/send-otp',
        data: {'phone': phone},
      );
      
      final isSuccess = response.statusCode == 200 || response.statusCode == 201;
      
      if (isSuccess && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final otp = data['otp'] ?? data['code'] ?? data['data']?['otp'] ?? data['data']?['code'];
          if (otp != null) {
            await _notificationService?.showNotification(
              id: 1,
              title: 'GymZ Verification Code',
              body: 'Your OTP is: $otp. Use this code to login.',
            );
          }
        }
      }
      
      return isSuccess;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify the OTP code sent to the user's phone.
  /// POST api/v1/user/login-otp
  Future<VerifyOtpResponse> verifyOtp(String phone, String otp) async {
    try {
      final response = await _apiClient.post(
        'api/v1/user/login-otp',
        data: {
          'phone': phone,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // If the backend returns a token or user details, the user is registered.
          // Adjust checks based on typical API structures:
          final token = data['token'] ?? data['accessToken'] ?? data['data']?['token'];
          final isRegisteredFlag = data['registered'] ?? data['is_registered'] ?? data['isRegistered'] ?? (token != null);
          
          if (isRegisteredFlag == true || token != null) {
            final userDataMap = data['user'] ?? data['data']?['user'] ?? data;
            final user = UserModel.fromJson(userDataMap).copyWith(token: token);
            return VerifyOtpResponse(
              isRegistered: true,
              token: token,
              user: user,
            );
          }
        }
      }
      return const VerifyOtpResponse(isRegistered: false);
    } on ApiException catch (e) {
      // If server returns 404 (user not found) or similar, it means the OTP is valid but the user is not registered.
      // Let's check if the OTP is invalid or if the user is just not registered.
      // Usually, if the API returns 404 for login-otp, it means user is not registered.
      if (e.statusCode == 404) {
        return const VerifyOtpResponse(isRegistered: false);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Register a new user.
  /// POST api/v1/user/register
  Future<UserModel> register({
    required String name,
    required String gender,
    required String phone,
    required String email,
    required String pincode,
    required String selfiePath,
    required String location,
  }) async {
    try {
      final fileName = selfiePath.split(Platform.pathSeparator).last;
      
      final formData = FormData.fromMap({
        'name': name,
        'gender': gender,
        'phone': phone,
        'email': email,
        'pincode': pincode,
        'location': location,
        'selfie': await MultipartFile.fromFile(
          selfiePath,
          filename: fileName,
        ),
      });

      final response = await _apiClient.post(
        'api/v1/user/register',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final token = data['token'] ?? data['accessToken'] ?? data['data']?['token'];
          final userDataMap = data['user'] ?? data['data']?['user'] ?? data;
          return UserModel.fromJson(userDataMap).copyWith(token: token);
        }
      }
      throw Exception('Registration failed: Invalid response from server');
    } catch (e) {
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return AuthRepository(apiClient, notificationService);
});
