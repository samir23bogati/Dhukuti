import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:suvha_investment/models/transaction_model.dart';
import 'package:suvha_investment/services/npi_service.dart';
import 'package:suvha_investment/services/payment_status_service.dart';

enum PaymentFlowPhase {
  idle,
  submitting,
  awaitingPayment,
  succeeded,
  failed,
  cancelled,
}

/// Drives the BUY payment flow. Talks to our own payment backend (never NCHL
/// directly) and mirrors the outcome in real time from Firestore via
/// [PaymentStatusService]. When the backend isn't configured the app falls back
/// to the legacy manual flow, so this is safe to leave active.
class PaymentProvider extends ChangeNotifier {
  final NpiService _npiService;
  final PaymentStatusService _statusService;

  PaymentFlowPhase _phase = PaymentFlowPhase.idle;
  PaymentFlowPhase get phase => _phase;

  String? _transactionId;
  String? get transactionId => _transactionId;

  String? _paymentId;
  String? get paymentId => _paymentId;

  String? _redirectUrl;
  String? get redirectUrl => _redirectUrl;

  String? _qrContent;
  String? get qrContent => _qrContent;

  double? _amount;
  double? get amount => _amount;

  String? _error;
  String? get error => _error;

  StreamSubscription<NpiPaymentStatus>? _subscription;

  PaymentProvider({NpiService? npiService, PaymentStatusService? statusService})
      : _npiService = npiService ?? NpiService(),
        _statusService = statusService ?? PaymentStatusService();

  bool get isConfigured => _npiService.isConfigured;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _phase = PaymentFlowPhase.idle;
    _transactionId = null;
    _paymentId = null;
    _redirectUrl = null;
    _qrContent = null;
    _amount = null;
    _error = null;
    notifyListeners();
  }

  /// Starts a ConnectIPS payment for a BUY transaction and subscribes to its
  /// Firestore-backed status stream.
  Future<void> startBuyPayment(TransactionModel transaction) async {
    _subscription?.cancel();
    _transactionId = transaction.id;
    _paymentId = null;
    _redirectUrl = null;
    _qrContent = null;
    _amount = transaction.totalAmount;
    _error = null;
    _phase = PaymentFlowPhase.submitting;
    notifyListeners();

    try {
      final result = await _npiService.createPayment(
        transactionId: transaction.id,
        amount: transaction.totalAmount,
        currency: 'NPR',
        payerAccountNumber: transaction.userId,
      );

      _paymentId = result['paymentId'] as String?;
      _redirectUrl = result['redirectUrl'] as String?;
      _qrContent = result['qrContent'] as String?;

      _subscription = _statusService
          .listenToPaymentStatus(transaction.id)
          .listen(_onRemoteStatus, onError: (Object e, StackTrace s) {
        debugPrint('PaymentProvider: status stream error: $e');
      });

      _phase = PaymentFlowPhase.awaitingPayment;
      notifyListeners();
    } catch (e) {
      _phase = PaymentFlowPhase.idle;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _onRemoteStatus(NpiPaymentStatus status) {
    switch (status) {
      case NpiPaymentStatus.succeeded:
        _phase = PaymentFlowPhase.succeeded;
        _subscription?.cancel();
        notifyListeners();
      case NpiPaymentStatus.failed:
        _phase = PaymentFlowPhase.failed;
        _subscription?.cancel();
        notifyListeners();
      case NpiPaymentStatus.cancelled:
      case NpiPaymentStatus.expired:
        _phase = PaymentFlowPhase.cancelled;
        _subscription?.cancel();
        notifyListeners();
      case NpiPaymentStatus.none:
      case NpiPaymentStatus.pending:
      case NpiPaymentStatus.qrGenerated:
      case NpiPaymentStatus.initiated:
      case NpiPaymentStatus.processing:
        if (_phase != PaymentFlowPhase.awaitingPayment) {
          _phase = PaymentFlowPhase.awaitingPayment;
          notifyListeners();
        }
    }
  }

  /// One-shot re-check (button / resume), useful if the stream missed an event.
  Future<void> refresh() async {
    if (_paymentId == null) return;
    _statusService.getPaymentStatus(_paymentId!).then((status) {
      _onRemoteStatus(status);
    }).catchError((Object e) {
      debugPrint('PaymentProvider: refresh error: $e');
    });
  }
}