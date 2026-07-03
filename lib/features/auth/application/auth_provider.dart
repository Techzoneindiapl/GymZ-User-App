import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/user_model.dart';
import '../../../../core/storage/storage_service.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  verificationPending,
  needsRegistration,
  authenticated
}

class AuthState {
  const AuthState({
    required this.status,
    this.phone,
    this.token,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? phone;
  final String? token;
  final UserModel? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    String? token,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkSession();
    return const AuthState(status: AuthStatus.authenticating);
  }

  Future<void> _checkSession() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final token = await storage.getToken();
      final userMap = await storage.getUser();
      if (token != null && userMap != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          token: token,
          user: UserModel.fromJson(userMap),
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final success = await repo.sendOtp(phone);
      if (success) {
        state = state.copyWith(
          status: AuthStatus.verificationPending,
          phone: phone,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Failed to send OTP. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<VerifyOtpResponse?> verifyOtp(String otp) async {
    final phone = state.phone;
    if (phone == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session timeout. Please request OTP again.',
      );
      return null;
    }

    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.verifyOtp(phone, otp);

      if (response.isRegistered && response.token != null && response.user != null) {
        final storage = ref.read(storageServiceProvider);
        await storage.saveToken(response.token!);
        await storage.saveUser(response.user!.toJson());
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: response.token,
          user: response.user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.needsRegistration,
        );
      }
      return response;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<UserModel?> register({
    required String name,
    required String gender,
    required String email,
    required String pincode,
    required String selfiePath,
    required String location,
  }) async {
    final phone = state.phone;
    if (phone == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Registration session expired. Please verify OTP again.',
      );
      return null;
    }

    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(
        name: name,
        gender: gender,
        phone: phone,
        email: email,
        pincode: pincode,
        selfiePath: selfiePath,
        location: location,
      );

      if (user.token != null) {
        final storage = ref.read(storageServiceProvider);
        await storage.saveToken(user.token!);
        await storage.saveUser(user.toJson());

        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: user.token,
          user: user,
        );
        return user;
      }
      throw Exception('Failed to retrieve authentication token after registration');
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.needsRegistration,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
