class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final String type; // 'credit' or 'debit'
  final DateTime? createdAt;
  final String? dateDisplay;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.createdAt,
    this.dateDisplay,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString());
    } else if (json['timestamp'] != null) {
      parsedDate = DateTime.tryParse(json['timestamp'].toString());
    } else if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString());
    }

    return WalletTransaction(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? json['description'] ?? 'Transaction',
      amount: (json['amount'] ?? 0.0) is int
          ? (json['amount'] ?? 0).toDouble()
          : (json['amount'] as num).toDouble(),
      type: json['type']?.toString().toLowerCase() ?? 'debit',
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
