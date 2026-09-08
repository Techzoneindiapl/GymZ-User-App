import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  double _selectedRechargeAmount = 1000;
  String _selectedTxFilter = 'All';
  bool _isProcessingPayment = false;
  late final TextEditingController _customAmountController;
  String? _amountError;

  bool get _isValidAmount =>
      _amountError == null &&
      _selectedRechargeAmount >= 1 &&
      _selectedRechargeAmount <= 5000;

  final List<double> _quickRecharges = [100, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _customAmountController = TextEditingController(
      text: _selectedRechargeAmount.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _onCustomAmountChanged(String val) {
    final text = val.trim();
    if (text.isEmpty) {
      setState(() {
        _selectedRechargeAmount = 0;
        _amountError = 'Please enter an amount';
      });
      return;
    }

    final parsed = double.tryParse(text);
    if (parsed == null) {
      setState(() {
        _selectedRechargeAmount = 0;
        _amountError = 'Please enter a valid number';
      });
      return;
    }

    if (parsed < 1) {
      setState(() {
        _selectedRechargeAmount = parsed;
        _amountError = 'Minimum recharge is ₹1';
      });
    } else if (parsed > 5000) {
      setState(() {
        _selectedRechargeAmount = parsed;
        _amountError = 'Maximum recharge is ₹5,000';
      });
    } else {
      setState(() {
        _selectedRechargeAmount = parsed;
        _amountError = null;
      });
    }
  }

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
    if (_isProcessingPayment) return;

    if (_selectedRechargeAmount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: const Text('Minimum recharge amount is ₹1.'),
        ),
      );
      return;
    }
    if (_selectedRechargeAmount > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: const Text('Maximum recharge amount is ₹5,000.'),
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final result = await ref.read(walletProvider.notifier).rechargeWithRazorpay(
            amount: _selectedRechargeAmount,
          );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                'Successfully added ₹${_selectedRechargeAmount.toInt()} to wallet!',
                style: TextStyle(color: AppColors.textOnAccent, fontWeight: FontWeight.bold),
              ),
            ),
          );
        } else if (result.isCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceCard,
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.message ?? 'Payment was cancelled.',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.message ?? 'Payment failed. Please try again.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
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
                  final isSelected = _selectedRechargeAmount == amount && _amountError == null;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedRechargeAmount = amount;
                            _customAmountController.text = amount.toInt().toString();
                            _amountError = null;
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
              const SizedBox(height: AppSpacing.lg),

              // Custom Amount Input
              Text(
                'Custom Amount',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _amountError != null
                        ? AppColors.danger
                        : AppColors.surfaceCardBorder,
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '₹',
                      style: AppTextStyles.displayMedium.copyWith(
                        fontSize: 22,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _customAmountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        onChanged: _onCustomAmountChanged,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter amount (₹1 – ₹5,000)',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    if (_customAmountController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _customAmountController.clear();
                          _onCustomAmountChanged('');
                        },
                        child: Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              if (_amountError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 14, color: AppColors.danger),
                      const SizedBox(width: 4),
                      Text(
                        _amountError!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Min: ₹1 • Max: ₹5,000',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),

              // Transaction History Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr['transaction_history'] ?? 'Transaction History',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                  ),
                  walletState.maybeWhen(
                    data: (walletData) => walletData.transactions.isNotEmpty
                        ? InkWell(
                            onTap: () => _openAllTransactionsModal(
                              context,
                              walletData.transactions,
                              initialFilter: _selectedTxFilter,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tr['view_all'] ?? 'View All',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Credits', 'Debits', 'Failed'].map((filter) {
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
                      case 'Failed':
                        translatedFilter = 'Failed';
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
                        selectedColor: filter == 'Failed'
                            ? AppColors.danger.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? (filter == 'Failed' ? AppColors.danger : AppColors.primary)
                              : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: AppColors.surfaceCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          side: BorderSide(
                            color: isSelected
                                ? (filter == 'Failed' ? AppColors.danger : AppColors.primary)
                                : AppColors.surfaceCardBorder,
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
                    final isFailed = tx.isFailedOrCancelled;
                    final isCredit = !isFailed && tx.type == 'credit';
                    if (_selectedTxFilter == 'Credits') {
                      return isCredit;
                    } else if (_selectedTxFilter == 'Debits') {
                      return !isCredit && !isFailed;
                    } else if (_selectedTxFilter == 'Failed') {
                      return isFailed;
                    }
                    return true;
                  }).toList();

                  // Limit to latest 5 transactions on the wallet screen
                  final latest5Txs = filteredTxs.take(5).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTransactionList(latest5Txs),
                      if (filteredTxs.length > 5) ...[
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _openAllTransactionsModal(
                              context,
                              walletData.transactions,
                              initialFilter: _selectedTxFilter,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.surfaceCardBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${tr['view_all'] ?? 'View All'} (${filteredTxs.length})',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
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
            color: _isValidAmount
                ? const Color(0xFFFF6D00)
                : AppColors.surfaceCardBorder,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: (_isProcessingPayment || !_isValidAmount) ? null : _handleTopUp,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                child: _isProcessingPayment
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payment_rounded,
                            color: _isValidAmount ? AppColors.textOnPrimary : AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _isValidAmount
                                ? '${tr['add_money'] ?? 'Add Money'} • ₹${_selectedRechargeAmount.toInt()}'
                                : 'Enter valid amount (₹1 – ₹5,000)',
                            style: AppTextStyles.buttonLabel.copyWith(
                              color: _isValidAmount ? AppColors.textOnPrimary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Secured by Razorpay (UPI, Cards, NetBanking)',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
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

  void _openAllTransactionsModal(
    BuildContext context,
    List<WalletTransaction> allTransactions, {
    String initialFilter = 'All',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllTransactionsModal(
        transactions: allTransactions,
        initialFilter: initialFilter,
        formatTxDate: _formatTxDate,
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
        return _TransactionCard(
          tx: transactions[index],
          formatDate: _formatTxDate,
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final WalletTransaction tx;
  final String Function(DateTime?) formatDate;

  const _TransactionCard({
    required this.tx,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == 'credit';
    final isFailed = tx.isFailedOrCancelled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFailed ? AppColors.danger.withValues(alpha: 0.35) : AppColors.surfaceCardBorder,
          ),
        ),
        child: Row(
          children: [
            // Direction icon / status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isFailed
                    ? AppColors.danger.withValues(alpha: 0.15)
                    : isCredit
                        ? AppColors.success.withValues(alpha: 0.15)
                        : const Color(0xFFFF6D00).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFailed
                    ? Icons.close_rounded
                    : isCredit
                        ? Icons.south_west
                        : Icons.north_east,
                color: isFailed
                    ? AppColors.danger
                    : isCredit
                        ? AppColors.success
                        : const Color(0xFFFF6D00),
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tx.title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFailed) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (tx.status == 'cancelled' ? AppColors.warning : AppColors.danger).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.status.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: tx.status == 'cancelled' ? AppColors.warning : AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.dateDisplay ?? formatDate(tx.createdAt),
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
              isFailed
                  ? '₹${tx.amount.toInt()}'
                  : isCredit
                      ? '+₹${tx.amount.toInt()}'
                      : '₹${tx.amount.toInt()}',
              style: AppTextStyles.price.copyWith(
                color: isFailed
                    ? AppColors.textMuted
                    : isCredit
                        ? AppColors.success
                        : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                decoration: isFailed ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllTransactionsModal extends ConsumerStatefulWidget {
  final List<WalletTransaction> transactions;
  final String initialFilter;
  final String Function(DateTime?) formatTxDate;

  const _AllTransactionsModal({
    required this.transactions,
    required this.initialFilter,
    required this.formatTxDate,
  });

  @override
  ConsumerState<_AllTransactionsModal> createState() => _AllTransactionsModalState();
}

class _AllTransactionsModalState extends ConsumerState<_AllTransactionsModal> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalCredits = widget.transactions.where((t) => !t.isFailedOrCancelled && t.type == 'credit').length;
    final totalDebits = widget.transactions.where((t) => !t.isFailedOrCancelled && t.type != 'credit').length;
    final totalFailed = widget.transactions.where((t) => t.isFailedOrCancelled).length;

    final filtered = widget.transactions.where((tx) {
      final isFailed = tx.isFailedOrCancelled;
      final isCredit = !isFailed && tx.type == 'credit';
      if (_selectedFilter == 'Credits') return isCredit;
      if (_selectedFilter == 'Debits') return !isCredit && !isFailed;
      if (_selectedFilter == 'Failed') return isFailed;
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.isDark ? AppColors.surfaceCardSolid : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr['transaction_history'] ?? 'Transaction History',
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.transactions.length} total transactions',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceCardBorder),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Filter chips with counts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ('All', tr['all'] ?? 'All', widget.transactions.length),
                ('Credits', tr['credits'] ?? 'Credits', totalCredits),
                ('Debits', tr['debits'] ?? 'Debits', totalDebits),
                ('Failed', 'Failed', totalFailed),
              ].map((item) {
                final filterKey = item.$1;
                final label = item.$2;
                final count = item.$3;
                final isSelected = _selectedFilter == filterKey;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$label ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filterKey;
                        });
                      }
                    },
                    selectedColor: filterKey == 'Failed'
                        ? AppColors.danger.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? (filterKey == 'Failed' ? AppColors.danger : AppColors.primary)
                          : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.surfaceCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide(
                        color: isSelected
                            ? (filterKey == 'Failed' ? AppColors.danger : AppColors.primary)
                            : AppColors.surfaceCardBorder,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Scrollable List of All Transactions
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 54, color: AppColors.textMuted),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No ${_selectedFilter.toLowerCase()} transactions found',
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _TransactionCard(
                        tx: filtered[index],
                        formatDate: widget.formatTxDate,
                      );
                    },
                  ),
          ),
        ],
      ),
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

