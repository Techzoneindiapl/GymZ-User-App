import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/application/auth_provider.dart';
import '../data/repositories/profile_repository.dart';

class ProfileNotifier extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() async {
    final authState = ref.watch(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      return authState.user;
    }
    return null;
  }

  Future<void> fetchProfile() async {
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(profileRepositoryProvider);
      final user = await repo.getProfile();
      // Sync with authentication provider state and storage
      await ref.read(authProvider.notifier).updateUser(user);
      return user;
    });
  }

  Future<void> refreshProfile() async {
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) return;

    state = await AsyncValue.guard(() async {
      final repo = ref.read(profileRepositoryProvider);
      final user = await repo.getProfile();
      await ref.read(authProvider.notifier).updateUser(user);
      return user;
    });
  }

  Future<void> uploadProfileImage(String imagePath) async {
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(profileRepositoryProvider);
      final user = await repo.updateProfileImage(imagePath);
      // Sync with authentication provider state and storage
      await ref.read(authProvider.notifier).updateUser(user);
      return user;
    });
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserModel?>(ProfileNotifier.new);
