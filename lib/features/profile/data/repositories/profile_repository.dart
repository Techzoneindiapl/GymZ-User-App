import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/user_model.dart';

class ProfileRepository {
  const ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetch user profile details.
  /// GET api/v1/user/profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.get('api/v1/user/profile');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final profileData = data['data'];
          if (profileData is Map<String, dynamic>) {
            return UserModel.fromJson(profileData);
          }
        }
      }
      throw Exception('Failed to load user profile: Invalid response');
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile image.
  /// PUT api/v1/user/profile
  Future<UserModel> updateProfileImage(String imagePath) async {
    try {
      final fileName = imagePath.split(Platform.pathSeparator).last;
      
      final formData = FormData.fromMap({
        'selfie': await MultipartFile.fromFile(
          imagePath,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.put(
        'api/v1/user/profile',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final profileData = data['data'];
          if (profileData is Map<String, dynamic>) {
            return UserModel.fromJson(profileData);
          }
        }
      }
      throw Exception('Failed to update profile image: Invalid response');
    } catch (e) {
      rethrow;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});
