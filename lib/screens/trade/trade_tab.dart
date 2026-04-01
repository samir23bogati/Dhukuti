import 'dart:async';
import 'package:dhukuti/models/transaction_model.dart';
import 'package:dhukuti/models/user_model.dart';
import 'package:dhukuti/providers/market_provider.dart';
import 'package:dhukuti/providers/user_provider.dart';
import 'package:dhukuti/screens/kyc/kyc_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TradeTab extends StatefulWidget {
  const TradeTab({super.key});

  @override
  State<TradeTab> createState() => _TradeTabState();
}

class _TradeTabState extends State<TradeTab> {
  final _quantityController = TextEditingController();
  bool _isLoading = false;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  String _metalType = 'silver'; // 'gold' or 'silver'

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _handleTrade(TransactionType type) async {
    final qtyText = _quantityController.text;
    final qty = double.tryParse(qtyText);

    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid quantity")));
      return;
    }

    final user = context.read<UserProvider>().userModel;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    try {
      await context.read<MarketProvider>().executeTrade(
        user: user,
        type: type,
        metalType: _metalType,
        quantityTola: qty,
      );
      if (mounted) {
        String msg = "${_metalType.toUpperCase()} ${type.name.toUpperCase()} Success!";
        if (type == TransactionType.sell) {
          msg += " (1% fee deducted)";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        _quantityController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '+9779851239186';
    final message = 'Hello Admin I want to Buy/Sell ${_metalType.toUpperCase()}, I am here to Inquiry about my Buy/Sell Payments.';
    final url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch WhatsApp")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = context.watch<MarketProvider>();
    final silverPrice = marketProvider.currentSilverPrice;
    final goldPrice = marketProvider.currentGoldPrice;
    final isMarketOpen = marketProvider.isMarketOpen;
    final marketStatusMsg = marketProvider.marketStatusMessage;

    final currentPrice = _metalType == 'gold' ? goldPrice : silverPrice;

    final user = context.watch<UserProvider>().userModel;
    final isVerified = true; // Temporarily bypassed for testing (no Storage)

    if (currentPrice == null) {
      return const Center(child: Text("Price currently unavailable"));
    }

    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(_currentTime);
    final formattedTime = DateFormat('h:mm:ss a').format(_currentTime);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _launchWhatsApp,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  children: [
                    Text(formattedDate, style: TextStyle(fontSize: screenWidth * 0.04)),
                    const SizedBox(height: 4),
                    Text(formattedTime, style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text("Trading Hours: 11:00 AM - 5:00 PM", style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.03)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isMarketOpen ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          marketStatusMsg,
                          style: TextStyle(
                            color: isMarketOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            
            SizedBox(height: screenHeight * 0.02),

            // 🔄 Metal Selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'silver', label: Text("Silver"), icon: Icon(Icons.diamond)),
                ButtonSegment(value: 'gold', label: Text("Gold"), icon: Icon(Icons.workspace_premium)),
              ],
              selected: {_metalType},
              onSelectionChanged: (val) => setState(() => _metalType = val.first),
            ),

            SizedBox(height: screenHeight * 0.03),

            Center(
              child: Text(
                "Today's Rate: Rs. ${currentPrice.toStringAsFixed(2)} / Tola",
                style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            
            if (isMarketOpen) ...[
              if (isVerified) ...[
                TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Quantity (${_metalType.toUpperCase()} Tola)",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.shopping_basket_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () => _handleTrade(TransactionType.buy),
                          child: const Text("BUY NOW"),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () => _handleTrade(TransactionType.sell),
                          child: const Text("SELL NOW"),
                        ),
                      ),
                    ],
                  ),
              ] else ...[
                // 🛡️ KYC Required Prompt
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shield_outlined, size: 50, color: Colors.blue),
                      const SizedBox(height: 15),
                      const Text(
                        "Verification Required",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "You must complete your KYC verification to start trading Gold and Silver.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Logic to switch to Profile Tab or open KYC Screen
                          // For simplicity, let's open KYC Screen directly
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const KYCScreen()),
                          );
                        },
                        child: const Text("Verify Now"),
                      ),
                    ],
                  ),
                ),
              ]
            ] else ...[
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.red.shade50,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.red.shade200),
                 ),
                 child: const Column(
                   children: [
                     Icon(Icons.lock_clock, size: 48, color: Colors.red),
                     SizedBox(height: 10),
                     Text(
                       "Trading is currently paused.",
                       textAlign: TextAlign.center,
                       style: TextStyle(fontSize: 16, color: Colors.red),
                     ),
                   ],
                 ),
               )
            ]
          ],
        ),
      ),
    );
  }
}
