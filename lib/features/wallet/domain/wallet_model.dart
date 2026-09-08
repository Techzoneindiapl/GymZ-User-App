class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final String type; // 'credit', 'debit', 'failed'
  final String status; // 'success', 'failed', 'cancelled'
  final DateTime? createdAt;
  final String? dateDisplay;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.status = 'success',
    this.createdAt,
    this.dateDisplay,
  });

  bool get isFailedOrCancelled =>
      status == 'failed' || status == 'cancelled' || type == 'failed';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString());
    } else if (json['timestamp'] != null) {
      parsedDate = DateTime.tryParse(json['timestamp'].toString());
    } else if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString());
    }

    final rawType = json['type']?.toString().toLowerCase() ?? 'debit';
    final rawStatus = json['status']?.toString().toLowerCase() ??
        (rawType == 'failed' || rawType == 'cancelled' ? rawType : 'success');

    return WalletTransaction(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? json['description'] ?? 'Transaction',
      amount: (json['amount'] ?? 0.0) is int
          ? (json['amount'] ?? 0).toDouble()
          : (json['amount'] as num).toDouble(),
      type: rawType,
      status: rawStatus,
      createdAt: parsedDate,
      dateDisplay: json['dateDisplay'] ?? json['formattedDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (dateDisplay != null) 'dateDisplay': dateDisplay,
    };
  }
}

class WalletData {
  final double walletBalance;
  final List<WalletTransaction> transactions;

  const WalletData({
    required this.walletBalance,
    required this.transactions,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final balanceVal = json['walletBalance'] ?? json['balance'] ?? 0.0;
    final balance = balanceVal is int ? balanceVal.toDouble() : (balanceVal as num).toDouble();
    
    final txList = json['transactions'] as List? ?? [];
    return WalletData(
      walletBalance: balance,
      transactions: txList
          .map((item) => WalletTransaction.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletBalance': walletBalance,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }
}

class RazorpayOrder {
  final String orderId;
  final int amount; // in paise
  final String currency;
  final String? razorpayKeyId;

  const RazorpayOrder({
    required this.orderId,
    required this.amount,
    this.currency = 'INR',
    this.razorpayKeyId,
  });

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) {
    return RazorpayOrder(
      orderId: json['orderId'] ?? json['id'] ?? json['order_id'] ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] ?? 'INR',
      razorpayKeyId: json['razorpayKeyId'] ?? json['key_id'] ?? json['keyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      if (razorpayKeyId != null) 'razorpayKeyId': razorpayKeyId,
    };
  }
}

class PaymentVerificationPayload {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const PaymentVerificationPayload({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    };
  }
}
