import 'package:dhukuti/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceView extends StatelessWidget {
  final TransactionModel transaction;
  final String userName;
  final String userPhone;

  const InvoiceView({
    super.key,
    required this.transaction,
    required this.userName,
    required this.userPhone,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isBuy = transaction.type == TransactionType.buy;
    final color = isBuy ? Colors.green : Colors.red;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🏆 Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DHUKUTI",
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Official Invoice",
                    style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.type.name.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 40),

          // 👤 User Details
          _buildRow("Customer", userName, screenWidth),
          _buildRow("Phone", userPhone, screenWidth),
          _buildRow("Date", DateFormat('MMM d, yyyy h:mm a').format(transaction.timestamp), screenWidth),
          _buildRow("Transaction ID", "#${transaction.id.toUpperCase().substring(0, 8)}", screenWidth),
          
          const Divider(height: 40),

          // 💎 Transaction Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${transaction.metalType.toUpperCase()} (${transaction.quantityTola.toStringAsFixed(2)} Tola)",
                style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600),
              ),
              Text(
                "Rs. ${transaction.ratePerTola.toStringAsFixed(2)} / Tola",
                style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (!isBuy) ...[
             _buildRow("Subtotal", "Rs. ${(transaction.quantityTola * transaction.ratePerTola).toStringAsFixed(2)}", screenWidth),
             _buildRow("Service Fee (1%)", "- Rs. ${(transaction.quantityTola * transaction.ratePerTola * 0.01).toStringAsFixed(2)}", screenWidth, valueColor: Colors.red),
             const SizedBox(height: 10),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NET TOTAL",
                style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
              ),
              Text(
                "Rs. ${transaction.totalAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
          Text(
            "Thank you for choosing Dhukuti!",
            style: TextStyle(fontSize: screenWidth * 0.03, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, double screenWidth, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }
}
