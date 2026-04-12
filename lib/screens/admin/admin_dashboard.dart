import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/providers/market_provider.dart';
import 'package:dhukuti/screens/admin/admin_kyc_review_screen.dart';
import 'package:dhukuti/screens/admin/admin_transaction_approval_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Market Control", style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
          SizedBox(height: screenHeight * 0.012),
          _buildMarketControlCard(context),
          SizedBox(height: screenHeight * 0.025),

          Consumer<MarketProvider>(
            builder: (context, market, child) {
              final silverPrice = market.currentSilverPrice;
              final goldPrice = market.currentGoldPrice;
              final isLoading = market.isLoadingPrice;
              
              return Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                       _buildRateRow("Silver Rate", silverPrice, isLoading, screenWidth),
                       Divider(),
                       _buildRateRow("Gold Rate", goldPrice, isLoading, screenWidth),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: screenHeight * 0.025),
          Row(
            children: [
              _StatCard(
                title: "Total Users",
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (snapshot) => "${snapshot.docs.length}",
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              SizedBox(width: screenWidth * 0.025),
              _StatCard(
                title: "Total Txns",
                stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                builder: (snapshot) => "${snapshot.docs.length}",
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              SizedBox(width: screenWidth * 0.025),
              _PendingTxCard(screenWidth: screenWidth, screenHeight: screenHeight),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.03),
          Text("Pending KYC Verifications", style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
          SizedBox(height: screenHeight * 0.012),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users')
              .where('verificationStatus', isEqualTo: 'pending')
              .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              
              if (docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Center(
                      child: Text("No pending verifications", style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.035)),
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
                      leading: CircleAvatar(child: Icon(Icons.person, size: screenWidth * 0.06)),
                      title: Text(userData['name'] ?? "No Name", style: TextStyle(fontSize: screenWidth * 0.04)),
                      subtitle: Text(userData['phone'], style: TextStyle(fontSize: screenWidth * 0.03)),
                      trailing: Icon(Icons.chevron_right, size: screenWidth * 0.06),
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
          
          SizedBox(height: screenHeight * 0.025),
          Text("Recent Transactions", style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
          SizedBox(height: screenHeight * 0.012),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('transactions')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
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
                        size: screenWidth * 0.06,
                      ),
                      title: Text("$type - ${data['quantityTola']} Tola", style: TextStyle(fontSize: screenWidth * 0.035)),
                      subtitle: Text("ID: ${docs[index].id.substring(0, 8)}...", style: TextStyle(fontSize: screenWidth * 0.03)),
                      trailing: Text("Rs. ${data['totalAmount']}", style: TextStyle(fontSize: screenWidth * 0.035)),
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
        final screenHeight = MediaQuery.of(context).size.height;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(screenWidth * 0.03),
                    topRight: Radius.circular(screenWidth * 0.03),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOpen ? Icons.check_circle : Icons.cancel,
                      color: isOpen ? Colors.green : Colors.red,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.03),
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
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Row(
                  children: [
                    if (isOpen) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmAction(context, "Close Market Today?", () {
                            market.setMarketOverride(date: DateTime.now(), isClosed: true);
                          }),
                          icon: Icon(Icons.block, size: screenWidth * 0.045),
                          label: Text("Close Today", style: TextStyle(fontSize: screenWidth * 0.035)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
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
                            _confirmAction(context, "Close Market on ${DateFormat('MMM d').format(date)}?", () {
                              market.setMarketOverride(date: date, isClosed: true);
                            });
                          }
                        },
                        icon: Icon(Icons.calendar_today, size: screenWidth * 0.045),
                        label: Text("Schedule", style: TextStyle(fontSize: screenWidth * 0.035)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: screenWidth * 0.06),
                      onSelected: (value) {
                        if (value == 'reset') {
                           _confirmAction(context, "Clear all manual overrides?", () {
                            market.clearMarketOverride();
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'reset',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: screenWidth * 0.05),
                              SizedBox(width: screenWidth * 0.025),
                              Text("Reset Overrides", style: TextStyle(fontSize: screenWidth * 0.035)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(fontSize: screenWidth * 0.045)),
        content: Text("Are you sure you want to perform this action?", style: TextStyle(fontSize: screenWidth * 0.038)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(fontSize: screenWidth * 0.038))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              action();
            },
            child: Text("Confirm", style: TextStyle(fontSize: screenWidth * 0.038)),
          )
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, String? userId) {
    if (userId == null) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("User Details", style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
              SizedBox(height: screenHeight * 0.02),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text("Error loading user details", style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.038));
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Text("User not found", style: TextStyle(fontSize: screenWidth * 0.038));
                  }
                   
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        _DetailRow(icon: Icons.person, label: "Name", value: data['name'] ?? "N/A", screenWidth: screenWidth),
                        _DetailRow(icon: Icons.phone, label: "Phone", value: data['phone'] ?? "N/A", screenWidth: screenWidth),
                        _DetailRow(icon: Icons.location_on, label: "Address", value: data['address'] ?? "N/A", screenWidth: screenWidth),
                        _DetailRow(icon: Icons.email, label: "Email", value: data['email'] ?? "N/A", screenWidth: screenWidth),
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

  Widget _buildRateRow(String title, double? price, bool isLoading, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
        if (isLoading)
          SizedBox(width: screenWidth * 0.05, height: screenWidth * 0.05, child: CircularProgressIndicator(strokeWidth: 2))
        else if (price == null)
          Text("Error", style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.04))
        else
          Text("Rs. ${price.toStringAsFixed(2)}", style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.green)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double screenWidth;
  
  const _DetailRow({required this.icon, required this.label, required this.value, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        children: [
          Icon(icon, size: screenWidth * 0.05, color: Colors.grey),
          SizedBox(width: screenWidth * 0.025),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.038)),
          Expanded(child: Text(value, style: TextStyle(fontSize: screenWidth * 0.038))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> stream;
  final String Function(QuerySnapshot) builder;
  final double screenWidth;
  final double screenHeight;

  const _StatCard({required this.title, required this.stream, required this.builder, required this.screenWidth, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: screenWidth * 0.035)),
              SizedBox(height: screenHeight * 0.01),
              StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text("-", style: TextStyle(fontSize: screenWidth * 0.04));
                  return Text(
                    builder(snapshot.data!),
                    style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
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

class _PendingTxCard extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const _PendingTxCard({required this.screenWidth, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminTransactionApprovalScreen()),
          );
        },
        child: Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Pending", style: TextStyle(fontSize: screenWidth * 0.035)),
                    SizedBox(width: screenWidth * 0.01),
                    Icon(Icons.arrow_forward_ios, size: screenWidth * 0.03, color: Colors.orange[700]),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text(
                      "$count",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: count > 0 ? Colors.orange[700] : Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

