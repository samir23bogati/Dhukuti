class PortfolioModel {
  final String userId;
  final double totalSilverTola;
  final double totalSilverInvestedAmount;
  final double totalGoldTola;
  final double totalGoldInvestedAmount;

  PortfolioModel({
    required this.userId,
    required this.totalSilverTola,
    required this.totalSilverInvestedAmount,
    required this.totalGoldTola,
    required this.totalGoldInvestedAmount,
  });

  factory PortfolioModel.fromMap(Map<String, dynamic> map, String userId) {
    return PortfolioModel(
      userId: userId,
      totalSilverTola: (map['totalSilverTola'] ?? 0).toDouble(),
      totalSilverInvestedAmount: (map['totalInvestedAmount'] ?? map['totalSilverInvestedAmount'] ?? 0).toDouble(),
      totalGoldTola: (map['totalGoldTola'] ?? 0).toDouble(),
      totalGoldInvestedAmount: (map['totalGoldInvestedAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSilverTola': totalSilverTola,
      'totalSilverInvestedAmount': totalSilverInvestedAmount,
      'totalGoldTola': totalGoldTola,
      'totalGoldInvestedAmount': totalGoldInvestedAmount,
    };
  }
  
  // Helper to calculate P/L
  double calculateProfitLoss(double currentPricePerTola) {
    final currentValue = totalSilverTola * currentPricePerTola;
    return currentValue - totalSilverInvestedAmount;
  }
}
