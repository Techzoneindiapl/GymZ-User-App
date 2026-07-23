import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_shell_screen.dart';
import '../../application/wallet_provider.dart';
import '../../domain/wallet_model.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/language_provider.dart';


class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  double _selectedRechargeAmount = 1000;
  String _selectedPaymentMethod = 'UPI';
  String _selectedTxFilter = 'All';

  final List<double> _quickRecharges = [100, 500, 1000, 2000];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'UPI', 'label': 'UPI', 'icon': Icons.phone_android},
    {'id': 'NetBanking', 'label': 'Net Banking', 'icon': Icons.account_balance},
    {'id': 'DebitCard', 'label': 'Debit Card', 'icon': Icons.credit_card},
    {'id': 'CreditCard', 'label': 'Credit Card', 'icon': Icons.credit_card_outlined},
  ];

  String _formatTxDate(DateTime? date) {
    if (date == null) return 'Recent';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (txDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }

  void _handleTopUp() async {
    final success = await ref.read(walletProvider.notifier).addMoney(
          _selectedRechargeAmount,
          _selectedPaymentMethod,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Successfully added ₹${_selectedRechargeAmount.toInt()} to wallet!',
              style: TextStyle(color: AppColors.textOnAccent, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else {
        final error = ref.read(walletProvider).error;
        final errorMsg = error?.toString().replaceAll('Exception: ', '') ?? 'Failed to add money. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              errorMsg,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final tr = ref.watch(translationProvider);

    return GradientScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(walletProvider.notifier).refreshWallet(),
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppBar Row
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final canPop = Navigator.of(context).canPop();
                      if (canPop) {
                        Navigator.of(context).pop();
                      } else {
                        ref.read(shellTabIndexProvider.notifier).state = 0;
                      }
                    },
                    icon: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
                    style: IconButton.styleFrom(backgroundColor: AppColors.surfaceCard),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(tr['wallet'] ?? 'Wallet', style: AppTextStyles.displayMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Wallet Balance Card
              walletState.when(
                data: (walletData) => _buildBalanceCard(walletData.walletBalance),
                loading: () => _buildBalanceCardPlaceholder(isLoading: true),
                error: (error, _) => _buildBalanceCardPlaceholder(hasError: true),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Quick Recharge
              Text(tr['quick_recharge'] ?? 'Quick Recharge', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _quickRecharges.map((amount) {
                  final isSelected = _selectedRechargeAmount == amount;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedRechargeAmount = amount;
                          });
                        },
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.surfaceCardBorder,
                            ),
                          ),
                          child: Text(
                            '₹${amount.toInt()}',
                            style: AppTextStyles.label.copyWith(
                              color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Payment Methods
              Text(tr['payment_methods'] ?? 'Payment Methods', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.8,
                ),
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  final isSelected = _selectedPaymentMethod == method['id'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = method['id'];
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.surfaceCardBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            method['icon'] as IconData,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              method['label'] as String,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Transaction History
              Text(tr['transaction_history'] ?? 'Transaction History', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Credits', 'Debits'].map((filter) {
                    final isSelected = _selectedTxFilter == filter;
                    final String translatedFilter;
                    switch (filter) {
                      case 'All':
                        translatedFilter = tr['all'] ?? 'All';
                        break;
                      case 'Credits':
                        translatedFilter = tr['credits'] ?? 'Credits';
                        break;
                      case 'Debits':
                        translatedFilter = tr['debits'] ?? 'Debits';
                        break;
                      default:
                        translatedFilter = filter;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(translatedFilter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTxFilter = filter;
                            });
                          }
                        },
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        labelStyle: AppTextStyles.bodySmall.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: AppColors.surfaceCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.surfaceCardBorder,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              walletState.when(
                data: (walletData) {
                  final filteredTxs = walletData.transactions.where((tx) {
                    final isCredit = tx.type == 'credit';
                    if (_selectedTxFilter == 'Credits') {
                      return isCredit;
                    } else if (_selectedTxFilter == 'Debits') {
                      return !isCredit;
                    }
                    return true;
                  }).toList();
                  return _buildTransactionList(filteredTxs);
                },
                loading: () => const ShimmerLoading(
                  child: Column(
                    children: [
                      _TransactionItemSkeleton(),
                      _TransactionItemSkeleton(),
                      _TransactionItemSkeleton(),
                      _TransactionItemSkeleton(),
                    ],
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      tr['failed_load_txs'] ?? 'Failed to load transactions. Pull to refresh.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    final tr = ref.watch(translationProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final balanceText = currencyFormatter.format(balance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr['wallet_balance']?.toUpperCase() ?? 'WALLET BALANCE',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    balanceText,
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Material(
            color: const Color(0xFFFF6D00), // Vibrant orange matching the design
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: _handleTopUp,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.textOnPrimary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      tr['add_money'] ?? 'Add Money',
                      style: AppTextStyles.buttonLabel.copyWith(color: AppColors.textOnPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCardPlaceholder({bool isLoading = false, bool hasError = false}) {
    final tr = ref.watch(translationProvider);
    if (isLoading) {
      return ShimmerLoading(
        child: Container(
          width: double.infinity,
          height: 172,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBlock(width: 100, height: 12),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBlock(width: 120, height: 28),
                    ],
                  ),
                  const ShimmerBlock(width: 48, height: 48, borderRadius: 24),
                ],
              ),
              const Spacer(),
              const ShimmerBlock(width: double.infinity, height: 52, borderRadius: AppRadius.pill),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 172,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tr['failed_load_balance'] ?? 'Failed to load balance',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<WalletTransaction> transactions) {
    final tr = ref.watch(translationProvider);
    if (transactions.isEmpty) {
      final noTxMsg = _selectedTxFilter == 'All'
          ? (tr['no_txs_yet'] ?? 'No transactions yet.')
          : 'No ${_selectedTxFilter.toLowerCase()} transactions found.';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              noTxMsg,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isCredit = tx.type == 'credit';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceCardBorder),
            ),
            child: Row(
              children: [
                // Direction icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCredit
                        ? AppColors.success.withOpacity(0.15)
                        : const Color(0xFFFF6D00).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCredit ? Icons.south_west : Icons.north_east,
                    color: isCredit ? AppColors.success : const Color(0xFFFF6D00),
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.dateDisplay ?? _formatTxDate(tx.createdAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Amount
                Text(
                  isCredit ? '+₹${tx.amount.toInt()}' : '₹${tx.amount.toInt()}',
                  style: AppTextStyles.price.copyWith(
                    color: isCredit ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionItemSkeleton extends StatelessWidget {
  const _TransactionItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceCardBorder),
        ),
        child: Row(
          children: [
            const ShimmerBlock(width: 44, height: 44, borderRadius: 22),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBlock(width: 140, height: 14),
                  SizedBox(height: 6),
                  ShimmerBlock(width: 80, height: 10),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const ShimmerBlock(width: 50, height: 16),
          ],
        ),
      ),
    );
  }
}

