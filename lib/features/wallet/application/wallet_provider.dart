import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/wallet_repository.dart';
import '../domain/wallet_model.dart';

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
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletData>(WalletNotifier.new);
