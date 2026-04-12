import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/models/transaction_model.dart';
import 'package:dhukuti/providers/market_provider.dart';
import 'package:dhukuti/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminTransactionApprovalScreen extends StatelessWidget {
  const AdminTransactionApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Transactions"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: screenWidth * 0.16, color: Colors.green[300]),
                  SizedBox(height: screenWidth * 0.04),
                  Text(
                    "No pending transactions",
                    style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    "All transactions have been reviewed",
                    style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.035),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(screenWidth * 0.04),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final transaction = TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              return _TransactionCard(transaction: transaction);
            },
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _isProcessing = false;
  final _reasonController = TextEditingController();

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    try {
      final userProvider = context.read<UserProvider>();
      final adminId = userProvider.userModel?.uid ?? 'admin';
      await context.read<MarketProvider>().approveTransaction(widget.transaction.id, adminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction approved successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reject Transaction", style: TextStyle(fontSize: screenWidth * 0.045)),
        content: TextField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: "Reason for rejection",
            hintText: "e.g., Insufficient funds",
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(fontSize: screenWidth * 0.035))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (_reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please provide a rejection reason")),
                );
                return;
              }
              Navigator.pop(context);
              await _reject();
            },
            child: Text("Reject", style: TextStyle(fontSize: screenWidth * 0.035)),
          ),
        ],
      ),
    );
  }

  Future<void> _reject() async {
    setState(() => _isProcessing = true);
    try {
      final userProvider = context.read<UserProvider>();
      final adminId = userProvider.userModel?.uid ?? 'admin';
      await context.read<MarketProvider>().rejectTransaction(
        widget.transaction.id,
        adminId,
        _reasonController.text,
      );
      _reasonController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction rejected")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isBuy = widget.transaction.type == TransactionType.buy;
    final color = isBuy ? Colors.green : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: screenWidth * 0.07,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${isBuy ? 'BUY' : 'SELL'} - ${widget.transaction.metalType.toUpperCase()}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04,
                            color: color,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, y h:mm a').format(widget.transaction.timestamp),
                          style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.03),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  ),
                  child: Text(
                    "PENDING",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: screenHeight * 0.03),
            _buildDetailRow("Transaction ID", "#${widget.transaction.id.toUpperCase().substring(0, 8)}", screenWidth),
            _buildDetailRow("User ID", widget.transaction.userId, screenWidth),
            _buildDetailRow("Quantity", "${widget.transaction.quantityTola.toStringAsFixed(2)} Tola", screenWidth),
            _buildDetailRow("Rate/Tola", "Rs. ${widget.transaction.ratePerTola.toStringAsFixed(2)}", screenWidth),
            SizedBox(height: screenHeight * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.035)),
                Text(
                  "Rs. ${widget.transaction.totalAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            if (_isProcessing)
              Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      ),
                      onPressed: _showRejectDialog,
                      child: Text("REJECT", style: TextStyle(fontSize: screenWidth * 0.035)),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      ),
                      onPressed: _approve,
                      child: Text("APPROVE", style: TextStyle(fontSize: screenWidth * 0.035)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: screenWidth * 0.035)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: screenWidth * 0.035)),
        ],
      ),
    );
  }
}
