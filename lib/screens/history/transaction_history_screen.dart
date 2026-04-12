import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/models/transaction_model.dart';
import 'package:dhukuti/providers/user_provider.dart';
import 'package:dhukuti/widgets/invoice_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.userModel;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (user == null) {
      return Scaffold(body: Center(child: Text("Please log in to view history", style: TextStyle(fontSize: screenWidth * 0.04))));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(fontSize: screenWidth * 0.04)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text("No transactions yet.", style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey)));
          }

          return ListView.builder(
            padding: EdgeInsets.all(screenWidth * 0.04),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final tx = TransactionModel.fromMap(
                docs[index].data() as Map<String, dynamic>,
                docs[index].id,
              );
              final isBuy = tx.type == TransactionType.buy;

              return Card(
                margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
                  leading: CircleAvatar(
                    backgroundColor: isBuy ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isBuy ? Colors.green : Colors.red,
                      size: screenWidth * 0.05,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${tx.type.name.toUpperCase()} ${tx.metalType.toUpperCase()}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.038),
                        ),
                      ),
                      _buildStatusBadge(tx.status, screenWidth),
                    ],
                  ),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(tx.timestamp), style: TextStyle(fontSize: screenWidth * 0.03)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Rs. ${tx.totalAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isBuy ? Colors.green : Colors.red,
                          fontSize: screenWidth * 0.038,
                        ),
                      ),
                      Text("${tx.quantityTola} Tola", style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey)),
                    ],
                  ),
                  onTap: () {
                    _showInvoice(context, tx, user.name ?? "Customer", user.phone ?? "N/A");
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showInvoice(BuildContext context, TransactionModel tx, String name, String phone) {
    final screenWidth = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: screenWidth * 0.25,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
          ),
          child: SingleChildScrollView(
            child: InvoiceView(
              transaction: tx,
              userName: name,
              userPhone: phone,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status, double screenWidth) {
    Color color;
    String text;
    switch (status) {
      case TransactionStatus.pending:
        color = Colors.orange;
        text = "PENDING";
        break;
      case TransactionStatus.approved:
        color = Colors.green;
        text = "APPROVED";
        break;
      case TransactionStatus.rejected:
        color = Colors.red;
        text = "REJECTED";
        break;
      case TransactionStatus.completed:
        color = Colors.blue;
        text = "COMPLETED";
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.005),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: screenWidth * 0.025,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
