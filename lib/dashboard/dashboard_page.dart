import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../services/price_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _priceService = PriceService();
  late Future<double> _priceFuture;

  @override
  void initState() {
    super.initState();
    _priceFuture = _priceService.getSilverPrice();
  }

  void _refreshPrice() {
    setState(() {
      _priceFuture = _priceService.getSilverPrice();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPrice,
            tooltip: 'Refresh Price',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Silver Price",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("NPR / Tola", style: TextStyle(fontSize: 16)),
                    FutureBuilder<double>(
                      future: _priceFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        } else if (snapshot.hasError) {
                          return const Text(
                            "Error",
                            style: TextStyle(color: Colors.red),
                          );
                        } else if (snapshot.hasData) {
                          return Text(
                            "Rs. ${snapshot.data}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          );
                        }
                        return const Text("---");
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text("Buy Silver"),
                    onPressed: () {
                      // TODO: Buy logic
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sell),
                    label: const Text("Sell Silver"),
                    onPressed: () {
                      // TODO: Sell logic
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
