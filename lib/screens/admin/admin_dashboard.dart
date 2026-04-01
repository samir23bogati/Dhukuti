import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/providers/market_provider.dart';
import 'package:dhukuti/screens/admin/admin_kyc_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Market Control", style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildMarketControlCard(context),
          const SizedBox(height: 20),

          Consumer<MarketProvider>(
            builder: (context, market, child) {
              final silverPrice = market.currentSilverPrice;
              final goldPrice = market.currentGoldPrice;
              final isLoading = market.isLoadingPrice;
              
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                       _buildRateRow("Silver Rate", silverPrice, isLoading),
                       const Divider(),
                       _buildRateRow("Gold Rate", goldPrice, isLoading),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatCard(
                title: "Total Users",
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (snapshot) => "${snapshot.docs.length}",
              ),
              const SizedBox(width: 10),
              _StatCard(
                title: "Total Transactions",
                stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                builder: (snapshot) => "${snapshot.docs.length}",
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          const Text("Pending KYC Verifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users')
              .where('verificationStatus', isEqualTo: 'pending')
              .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              
              if (docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text("No pending verifications", style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final userData = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(userData['name'] ?? "No Name"),
                      subtitle: Text(userData['phone']),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminKYCReviewScreen(
                              uid: docs[index].id,
                              userData: userData,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 20),
          const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('transactions')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final type = data['type']?.toString().toUpperCase() ?? "UNKNOWN";
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        type.contains('BUY') ? Icons.arrow_downward : Icons.arrow_upward,
                        color: type.contains('BUY') ? Colors.green : Colors.red,
                      ),
                      title: Text("$type - ${data['quantityTola']} Tola"),
                      subtitle: Text("ID: ${docs[index].id.substring(0, 8)}..."),
                      trailing: Text("Rs. ${data['totalAmount']}"),
                      onTap: () => _showUserDetails(context, data['userId']),
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildMarketControlCard(BuildContext context) {
    return Consumer<MarketProvider>(
      builder: (context, market, _) {
        final isMsg = market.marketStatusMessage;
        final isOpen = market.isMarketOpen;
        final screenWidth = MediaQuery.of(context).size.width;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOpen ? Icons.check_circle : Icons.cancel,
                      color: isOpen ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isMsg,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (isOpen) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmAction(context, "Close Market Today?", () {
                            market.setMarketOverride(date: DateTime.now(), isClosed: true);
                          }),
                          icon: const Icon(Icons.block, size: 18),
                          label: const Text("Close Today"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            // ignore: use_build_context_synchronously
                            _confirmAction(context, "Close Market on ${DateFormat('MMM d').format(date)}?", () {
                              market.setMarketOverride(date: date, isClosed: true);
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text("Schedule"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'reset') {
                           _confirmAction(context, "Clear all manual overrides?", () {
                            market.clearMarketOverride();
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'reset',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 20),
                              SizedBox(width: 10),
                              Text("Reset Overrides"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmAction(BuildContext context, String title, Function action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text("Are you sure you want to perform this action?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              action();
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, String? userId) {
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("User Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Text("Error loading user details", style: TextStyle(color: Colors.red));
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("User not found");
                  }
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        _DetailRow(icon: Icons.person, label: "Name", value: data['name'] ?? "N/A"),
                        _DetailRow(icon: Icons.phone, label: "Phone", value: data['phone'] ?? "N/A"),
                        _DetailRow(icon: Icons.location_on, label: "Address", value: data['address'] ?? "N/A"),
                        _DetailRow(icon: Icons.email, label: "Email", value: data['email'] ?? "N/A"),
                     ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRateRow(String title, double? price, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (isLoading)
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        else if (price == null)
          const Text("Error", style: TextStyle(color: Colors.red))
        else
          Text("Rs. ${price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> stream;
  final String Function(QuerySnapshot) builder;

  const _StatCard({required this.title, required this.stream, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text("-");
                  return Text(
                    builder(snapshot.data!),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

