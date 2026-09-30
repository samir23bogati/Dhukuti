import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:suvha_investment/models/transaction_model.dart';
import 'package:suvha_investment/providers/payment_provider.dart';

/// BUY payment landing screen. Shows the payable total, two-step progress and
/// a primary PAY NOW action. The result (success / failed / cancelled) renders
/// here automatically from the Firestore stream — no separate web page needed.
/// Responsive: content is capped at a readable width and sizes scale with the
/// screen via [MediaQuery].
class PaymentScreen extends StatefulWidget {
  final TransactionModel transaction;

  const PaymentScreen({super.key, required this.transaction});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _launching = false;
  bool _refreshing = false;
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
      onResume: () {
        final provider = context.read<PaymentProvider>();
        if (provider.phase == PaymentFlowPhase.awaitingPayment) {
          provider.refresh();
        }
      },
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
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the payment page')),
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _refreshing = true);
    await context.read<PaymentProvider>().refresh();
    if (mounted) setState(() => _refreshing = false);
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
        appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildPhase(context, provider, amount),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(
      BuildContext context, PaymentProvider provider, double amount) {
    final sw = MediaQuery.of(context).size.width;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    switch (provider.phase) {
      case PaymentFlowPhase.idle:
      case PaymentFlowPhase.submitting:
        return _Preparing(sw: sw, scheme: scheme, text: text);
      case PaymentFlowPhase.awaitingPayment:
        return _Awaiting(
          sw: sw,
          scheme: scheme,
          text: text,
          amount: amount,
          metal: widget.transaction.metalType,
          qty: widget.transaction.quantityTola,
          qrHint: provider.qrContent,
          launching: _launching,
          refreshing: _refreshing,
          onPayNow: _payNow,
          onCheck: _checkStatus,
        );
      case PaymentFlowPhase.succeeded:
        return _Result(
          sw: sw,
          scheme: scheme,
          text: text,
          amount: amount,
          metal: widget.transaction.metalType,
          qty: widget.transaction.quantityTola,
          success: true,
          cancelled: false,
          txnRef: provider.paymentId,
          onDone: () => Navigator.pop(context),
        );
      case PaymentFlowPhase.failed:
        return _Result(
          sw: sw,
          scheme: scheme,
          text: text,
          amount: amount,
          metal: widget.transaction.metalType,
          qty: widget.transaction.quantityTola,
          success: false,
          cancelled: false,
          txnRef: provider.paymentId,
          onDone: () => Navigator.pop(context),
          onRetry: provider.phase == PaymentFlowPhase.failed ? _start : null,
        );
      case PaymentFlowPhase.cancelled:
        return _Result(
          sw: sw,
          scheme: scheme,
          text: text,
          amount: amount,
          metal: widget.transaction.metalType,
          qty: widget.transaction.quantityTola,
          success: false,
          cancelled: true,
          txnRef: provider.paymentId,
          onDone: () => Navigator.pop(context),
        );
    }
  }
}

class _PayHeader extends StatelessWidget {
  final double sw;
  final ColorScheme scheme;
  final TextTheme text;
  final IconData icon;
  final String title;
  final String subtitle;

  const _PayHeader({
    required this.sw,
    required this.scheme,
    required this.text,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: scheme.primary),
        ),
        SizedBox(height: sw * 0.025),
        Text(title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  final double sw;
  final ColorScheme scheme;
  final TextTheme text;
  final double amount;
  final String metal;
  final double qty;

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
    final formatted = NumberFormat('#,##0.00').format(amount);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sw * 0.05),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text('Amount Payable',
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
          SizedBox(height: 6),
          Text(
            'Rs $formatted',
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '${metal.toUpperCase()} · ${NumberFormat('#,##0.00').format(qty)} tola',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme text;
  final int current;

  const _Steps({
    required this.scheme,
    required this.text,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Order', 'Payment', 'Done'];
    final completed = current;
    return Column(
      children: [
        Row(
          children: List.generate(labels.length, (i) {
            final state = i < completed
                ? _StepState.done
                : i == completed
                    ? _StepState.active
                    : _StepState.todo;
            return Expanded(child: _StepDot(state: state, scheme: scheme));
            // Splitting spaces between dots handled below.
          }),
        ),
        SizedBox(height: 10),
        Row(
          children: List.generate(labels.length, (i) {
            final state = i < completed
                ? _StepState.done
                : i == completed
                    ? _StepState.active
                    : _StepState.todo;
            return Expanded(
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                  color: state == _StepState.todo
                      ? scheme.outline
                      : scheme.primary,
                  fontWeight: state == _StepState.active
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

enum _StepState { todo, active, done }

class _StepDot extends StatelessWidget {
  final _StepState state;
  final ColorScheme scheme;

  const _StepDot({required this.state, required this.scheme});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _StepState.done:
        return Icon(Icons.check_circle, size: 26, color: scheme.primary);
      case _StepState.active:
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.more_horiz, size: 22, color: scheme.onPrimary),
        );
      case _StepState.todo:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant, width: 2),
          ),
        );
    }
  }
}

class _Preparing extends StatelessWidget {
  final double sw;
  final ColorScheme scheme;
  final TextTheme text;
  const _Preparing({required this.sw, required this.scheme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: sw * 0.06),
        SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(
              strokeWidth: 5, color: scheme.primary),
        ),
        SizedBox(height: sw * 0.05),
        Text('Securing payment…', style: text.titleMedium),
      ],
    );
  }
}

class _Awaiting extends StatelessWidget {
  final double sw;
  final ColorScheme scheme;
  final TextTheme text;
  final double amount;
  final String metal;
  final double qty;
  final String? qrHint;
  final bool launching;
  final bool refreshing;
  final VoidCallback onPayNow;
  final VoidCallback onCheck;

  const _Awaiting({
    required this.sw,
    required this.scheme,
    required this.text,
    required this.amount,
    required this.metal,
    required this.qty,
    required this.qrHint,
    required this.launching,
    required this.refreshing,
    required this.onPayNow,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PayHeader(
          sw: sw,
          scheme: scheme,
          text: text,
          icon: Icons.account_balance_wallet_rounded,
          title: 'Pay with ConnectIPS',
          subtitle:
              'You will be redirected to the secure ConnectIPS portal to authorize the payment.',
        ),
        SizedBox(height: sw * 0.06),
        _AmountCard(
            sw: sw, scheme: scheme, text: text, amount: amount, metal: metal, qty: qty),
        SizedBox(height: sw * 0.055),
        _Steps(scheme: scheme, text: text, current: 1),
        SizedBox(height: sw * 0.06),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: launching ? null : onPayNow,
            icon: launching
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: scheme.onPrimary))
                : const Icon(Icons.lock_rounded),
            label: Text(
              launching ? 'Opening secure portal…' : 'PAY NOW',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: refreshing ? null : onCheck,
            icon: refreshing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.refresh_rounded),
            label: const Text('I’ve already paid — check status'),
          ),
        ),
        SizedBox(height: sw * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_rounded, size: 15, color: scheme.outline),
            SizedBox(width: 6),
            Text(
              'Secured by ConnectIPS (NCHL)',
              style: text.bodySmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  final double sw;
  final ColorScheme scheme;
  final TextTheme text;
  final double amount;
  final String metal;
  final double qty;
  final bool success;
  final bool cancelled;
  final String? txnRef;
  final VoidCallback onDone;
  final VoidCallback? onRetry;

  const _Result({
    required this.sw,
    required this.scheme,
    required this.text,
    required this.amount,
    required this.metal,
    required this.qty,
    required this.success,
    required this.cancelled,
    required this.txnRef,
    required this.onDone,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final color = success
        ? const Color(0xFF22A06B)
        : cancelled
            ? const Color(0xFFF5A623)
            : const Color(0xFFE5484D);
    final title = success
        ? 'Payment Successful'
        : cancelled
            ? 'Payment Cancelled'
            : 'Payment Failed';
    final subtitle = success
        ? 'Your payment was received. Your order is now with the admin for final approval.'
        : cancelled
            ? 'The payment was cancelled. No amount was charged.'
            : 'The payment could not be completed. No amount was charged.';

    final ref = txnRef?.isNotEmpty == true ? txnRef! : null;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 96,
          height: 96,
          margin: EdgeInsets.only(top: sw * 0.02),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            success
                ? Icons.check_rounded
                : cancelled
                    ? Icons.info_rounded
                    : Icons.close_rounded,
            size: 52,
            color: color,
          ),
        ),
        SizedBox(height: sw * 0.04),
        Text(title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
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
        _AmountCard(
            sw: sw, scheme: scheme, text: text, amount: amount, metal: metal, qty: qty),
        if (ref != null) ...[
          SizedBox(height: 12),
          Text(
            'Ref: $ref',
            style: text.bodySmall?.copyWith(color: scheme.outline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: sw * 0.045),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onDone,
            icon: const Icon(Icons.done_rounded),
            label: const Text('Done'),
          ),
        ),
        if (onRetry != null) ...[
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Try Again'),
            ),
          ),
        ],
      ],
    );
  }
}