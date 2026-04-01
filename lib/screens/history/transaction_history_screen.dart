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

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in to view history")));
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No transactions yet."));
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
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isBuy ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isBuy ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    "${tx.type.name.toUpperCase()} ${tx.metalType.toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(tx.timestamp)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Rs. ${tx.totalAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isBuy ? Colors.green : Colors.red,
                        ),
                      ),
                      Text("${tx.quantityTola} Tola", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 100,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
}
