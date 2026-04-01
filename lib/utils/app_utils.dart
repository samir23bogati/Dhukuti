class AppUtils {
  static double calculateTotalWithFee(double amount) {
    return amount + (amount * 0.01);
  }

  static double calculateFeeOnly(double amount) {
    return amount * 0.01;
  }
}
