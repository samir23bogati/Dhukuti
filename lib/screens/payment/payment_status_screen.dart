import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:suvha_investment/services/payment_status_service.dart';

/// Landing page for the connectips return (`suvhaval://payment/<txnId>`).
/// Paints an instant result from the deep-link [statusFromLink] and then
/// keeps the live Firestore status in sync until terminal. Pure result page —
/// amount/metal come from the transaction doc; no payment initiation here.
class PaymentStatusScreen extends StatefulWidget {
  final String txnId;

  /// 'success' | 'failure' from the deep link; used only for instant paint.
  final String? statusFromLink;

  const PaymentStatusScreen({
    super.key,
    required this.txnId,
    this.statusFromLink,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  late final StreamSubscription<DocumentSnapshot> _sub;
  Map<String, dynamic>? _txData;
  NpiPaymentStatus _status = NpiPaymentStatus.pending;

  @override
  void initState() {
    super.initState();
    switch (widget.statusFromLink) {
      case 'success':
        _status = NpiPaymentStatus.succeeded;
      case 'failure':
        _status = NpiPaymentStatus.failed;
      case 'cancelled':
        _status = NpiPaymentStatus.cancelled;
      default:
        _status = NpiPaymentStatus.pending;
    }
    _sub = FirebaseFirestore.instance
        .collection('transactions')
        .doc(widget.txnId)
        .snapshots()
        .listen((snap) {
      _txData = snap.data();
      final st = NpiPaymentStatus.fromString(
          _txData?['paymentStatus']?.toString());
      if (mounted) setState(() => _status = st);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final data = _txData;
    final amount = (data?['totalAmount'] as num?)?.toDouble();
    final metal = data?['metalType']?.toString().toUpperCase();
    final qty = (data?['quantityTola'] as num?)?.toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Status'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: sw * 0.04,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _status.isTerminal
                  ? _Result(
                      sw: sw,
                      scheme: scheme,
                      text: text,
                      status: _status,
                      amount: amount,
                      metal: metal,
                      qty: qty,
                      txnId: widget.txnId,
                    )
                  : _Checking(sw: sw, scheme: scheme, text: text),
            ),
          ),
        ),
      ),
    );
  }
}

class _Checking extends StatelessWidget {
  final double sw;
  final ColorScheme scheme;
  final TextTheme text;
  const _Checking(
      {required this.sw, required this.scheme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 48),
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: sw * 0.05),
        Text('Checking payment…', style: text.titleMedium),
        SizedBox(height: 8),
        Text(
          'Sit tight, we are confirming your payment with the bank.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  final double sw;
  final ColorScheme scheme;
  final TextTheme text;
  final NpiPaymentStatus status;
  final double? amount;
  final String? metal;
  final double? qty;
  final String txnId;

  const _Result({
    required this.sw,
    required this.scheme,
    required this.text,
    required this.status,
    required this.amount,
    required this.metal,
    required this.qty,
    required this.txnId,
  });

  @override
  Widget build(BuildContext context) {
    final success = status == NpiPaymentStatus.succeeded;
    final color =
        success ? const Color(0xFF22A06B) : (status == NpiPaymentStatus.failed ? const Color(0xFFE5484D) : const Color(0xFFF5A623));
    final title = success
        ? 'Payment Successful'
        : status == NpiPaymentStatus.failed
            ? 'Payment Failed'
            : 'Payment Cancelled';
    final subtitle = success
        ? 'Your payment was received. Your order is now with the admin for final approval.'
        : status == NpiPaymentStatus.failed
            ? 'The payment could not be completed. No amount was charged — you can try again.'
            : 'The payment was cancelled. No amount was charged.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 96,
          height: 96,
          margin: EdgeInsets.only(top: sw * 0.03),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            success ? Icons.check_rounded : (status == NpiPaymentStatus.failed ? Icons.close_rounded : Icons.info_rounded),
            size: 52,
            color: color,
          ),
        ),
        SizedBox(height: sw * 0.045),
        Text(title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        SizedBox(height: sw * 0.05),
        _AmountCard(sw: sw, scheme: scheme, text: text, amount: amount, metal: metal, qty: qty),
        SizedBox(height: 14),
        Text(
          'Ref: $txnId',
          style: text.bodySmall?.copyWith(color: scheme.outline),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: sw * 0.04),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Back to Home'),
          ),
        ),
        if (!success)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Try Again'),
            ),
          ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  final double sw;
  final ColorScheme scheme;
  final TextTheme text;
  final double? amount;
  final String? metal;
  final double? qty;

  const _AmountCard({
    required this.sw,
    required this.scheme,
    required this.text,
    required this.amount,
    required this.metal,
    required this.qty,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,##0.00').format(amount ?? 0);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sw * 0.045),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            'Amount',
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 6),
          Text(
            'Rs $formatted',
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          if (metal != null) ...[
            SizedBox(height: 6),
            Text(
              '$metal · ${NumberFormat('#,##0.00').format(qty ?? 0)} tola',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}