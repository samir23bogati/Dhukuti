enum TransactionType { buy, sell }

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final String metalType; // 'gold' or 'silver'
  final double quantityTola;
  final double ratePerTola;
  final double totalAmount;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.metalType,
    required this.quantityTola,
    required this.ratePerTola,
    required this.totalAmount,
    required this.timestamp,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: TransactionType.values.firstWhere(
          (e) => e.toString() == 'TransactionType.${map['type']}',
          orElse: () => TransactionType.buy),
      metalType: map['metalType'] ?? 'silver',
      quantityTola: (map['quantityTola'] ?? 0).toDouble(),
      ratePerTola: (map['ratePerTola'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last, // 'buy' or 'sell'
      'metalType': metalType,
      'quantityTola': quantityTola,
      'ratePerTola': ratePerTola,
      'totalAmount': totalAmount,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
