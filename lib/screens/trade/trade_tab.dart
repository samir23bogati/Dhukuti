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
        _showPendingSuccessDialog(type);
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

  void _showPendingSuccessDialog(TransactionType type) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.hourglass_top, color: Colors.orange, size: screenWidth * 0.06),
            SizedBox(width: screenWidth * 0.02),
            Text("Request Submitted", style: TextStyle(fontSize: screenWidth * 0.045)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your ${_metalType.toUpperCase()} ${type == TransactionType.buy ? 'Purchase' : 'Sale'} request has been submitted for admin approval.",
              style: TextStyle(fontSize: screenWidth * 0.038),
            ),
            SizedBox(height: screenWidth * 0.03),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      "You will be notified once approved. Check your transaction history for status updates.",
                      style: TextStyle(fontSize: screenWidth * 0.03),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(fontSize: screenWidth * 0.038)),
          ),
        ],
      ),
    );
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
        child: Icon(Icons.chat, color: Colors.white, size: screenWidth * 0.07),
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
                    SizedBox(height: screenHeight * 0.005),
                    Text(formattedTime, style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold)),
                    SizedBox(height: screenHeight * 0.015),
                    Divider(),
                    SizedBox(height: screenHeight * 0.015),
                    Text("Trading Hours: 11:00 AM - 5:00 PM", style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.03)),
                    SizedBox(height: screenHeight * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: screenWidth * 0.04,
                          height: screenWidth * 0.04,
                          decoration: BoxDecoration(
                            color: isMarketOpen ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
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
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    labelText: "Quantity (${_metalType.toUpperCase()} Tola)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                    prefixIcon: Icon(Icons.shopping_basket_outlined, size: screenWidth * 0.06),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                if (_isLoading)
                  Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, 
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          ),
                          onPressed: () => _handleTrade(TransactionType.buy),
                          child: Text("BUY NOW", style: TextStyle(fontSize: screenWidth * 0.04)),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.05),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, 
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          ),
                          onPressed: () => _handleTrade(TransactionType.sell),
                          child: Text("SELL NOW", style: TextStyle(fontSize: screenWidth * 0.04)),
                        ),
                      ),
                    ],
                  ),
              ] else ...[
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.shield_outlined, size: screenWidth * 0.12, color: Colors.blue),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Verification Required",
                        style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: screenHeight * 0.012),
                      Text(
                        "You must complete your KYC verification to start trading Gold and Silver.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const KYCScreen()),
                          );
                        },
                        child: Text("Verify Now", style: TextStyle(fontSize: screenWidth * 0.038)),
                      ),
                    ],
                  ),
                ),
              ]
            ] else ...[
               Container(
                 padding: EdgeInsets.all(screenWidth * 0.04),
                 decoration: BoxDecoration(
                   color: Colors.red.shade50,
                   borderRadius: BorderRadius.circular(screenWidth * 0.02),
                   border: Border.all(color: Colors.red.shade200),
                 ),
                 child: Column(
                   children: [
                     Icon(Icons.lock_clock, size: screenWidth * 0.12, color: Colors.red),
                     SizedBox(height: screenHeight * 0.012),
                     Text(
                       "Trading is currently paused.",
                       textAlign: TextAlign.center,
                       style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.red),
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
