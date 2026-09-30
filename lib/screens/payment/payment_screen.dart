import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:suvha_investment/models/transaction_model.dart';
import 'package:suvha_investment/providers/payment_provider.dart';

/// BUY payment landing screen. Shows the payable total, opens the payment page
/// (test simulator or real ConnectIPS), and follows the transaction's
/// paymentStatus stream until it becomes terminal. No separate web page is
/// needed — the app renders the result here.
class PaymentScreen extends StatefulWidget {
  final TransactionModel transaction;

  const PaymentScreen({super.key, required this.transaction});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _launching = false;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      if (provider.phase == PaymentFlowPhase.idle &&
          provider.transactionId != widget.transaction.id) {
        _start();
      }
    });

    // The ConnectIPS page redirects back to `suvhaval://payment/<txnId>`; when
    // the browser hands back to the app, re-check status in case the Firestore
    // stream missed the update while backgrounded.
    _lifecycleListener = AppLifecycleListener(
      onResume: () => context.read<PaymentProvider>().refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await context.read<PaymentProvider>().startBuyPayment(widget.transaction);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e')),
        );
      }
    }
  }

  Future<void> _payNow() async {
    final provider = context.read<PaymentProvider>();
    final url = provider.redirectUrl;
    if (url == null || url.isEmpty) return;

    setState(() => _launching = true);
    try {
      final uri = Uri.parse(url);
      final ok = await canLaunchUrl(uri);
      if (ok) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open payment page')),
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final amount = provider.amount ?? widget.transaction.totalAmount;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<PaymentProvider>().reset();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Amount Payable',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        'Rs ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.transaction.metalType.toUpperCase()} · '
                        '${widget.transaction.quantityTola.toStringAsFixed(2)} tola',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildPhase(provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(PaymentProvider provider) {
    switch (provider.phase) {
      case PaymentFlowPhase.idle:
        return const Center(child: Text('Preparing payment…'));
      case PaymentFlowPhase.submitting:
        return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Creating payment…'),
        ]));
      case PaymentFlowPhase.awaitingPayment:
        return _awaiting(provider);
      case PaymentFlowPhase.succeeded:
        return _result(Icons.check_circle, 'Payment Successful',
            'Your order is now with the admin for final approval.',
            Colors.green);
      case PaymentFlowPhase.failed:
        return _result(Icons.cancel, 'Payment Failed',
            'The payment was not completed. You can retry.', Colors.red);
      case PaymentFlowPhase.cancelled:
        return _result(Icons.info, 'Payment Cancelled',
            'No charge was made.', Colors.orange);
    }
  }

  Widget _awaiting(PaymentProvider provider) {
    final qr = provider.qrContent;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_wallet, size: 72, color: Colors.green.shade600),
        const SizedBox(height: 12),
        const Text('Pay with ConnectIPS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (qr != null && qr.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Scan & pay via Gateway QR (test)'),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _launching ? null : _payNow,
          icon: const Icon(Icons.open_in_new),
          label: Text(_launching ? 'Opening…' : 'PAY NOW'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => provider.refresh(),
          child: const Text('I have paid — check status'),
        ),
        if (provider.error != null) ...[
          const SizedBox(height: 16),
          Text(provider.error!,
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _result(IconData icon, String title, String subtitle, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72, color: color),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}