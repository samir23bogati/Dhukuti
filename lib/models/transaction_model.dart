enum TransactionType { buy, sell }

enum TransactionStatus { pending, approved, rejected, completed }

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final String metalType; // 'gold' or 'silver'
  final double quantityTola;
  final double ratePerTola;
  final double totalAmount;
  final DateTime timestamp;
  final TransactionStatus status;
  final String? rejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.metalType,
    required this.quantityTola,
    required this.ratePerTola,
    required this.totalAmount,
    required this.timestamp,
    this.status = TransactionStatus.pending,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${map['type']}',
        orElse: () => TransactionType.buy,
      ),
      metalType: map['metalType'] ?? 'silver',
      quantityTola: (map['quantityTola'] ?? 0).toDouble(),
      ratePerTola: (map['ratePerTola'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${map['status']}',
        orElse: () => TransactionStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['approvedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    String statusString;
    switch (status) {
      case TransactionStatus.pending:
        statusString = 'pending';
        break;
      case TransactionStatus.approved:
        statusString = 'approved';
        break;
      case TransactionStatus.rejected:
        statusString = 'rejected';
        break;
      case TransactionStatus.completed:
        statusString = 'completed';
        break;
    }
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'metalType': metalType,
      'quantityTola': quantityTola,
      'ratePerTola': ratePerTola,
      'totalAmount': totalAmount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': statusString,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (approvedAt != null) 'approvedAt': approvedAt!.millisecondsSinceEpoch,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    String? metalType,
    double? quantityTola,
    double? ratePerTola,
    double? totalAmount,
    DateTime? timestamp,
    TransactionStatus? status,
    String? rejectionReason,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      metalType: metalType ?? this.metalType,
      quantityTola: quantityTola ?? this.quantityTola,
      ratePerTola: ratePerTola ?? this.ratePerTola,
      totalAmount: totalAmount ?? this.totalAmount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
