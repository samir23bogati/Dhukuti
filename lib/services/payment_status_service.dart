import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment lifecycle written to `transactions/{id}.paymentStatus` by the
/// payment backend (from NCHL webhooks / QR WebSocket events).
enum NpiPaymentStatus {
  none,
  pending,
  qrGenerated,
  initiated,
  processing,
  succeeded,
  failed,
  cancelled,
  expired;

  static NpiPaymentStatus fromString(String? raw) {
    if (raw == null || raw.isEmpty) return NpiPaymentStatus.none;
    return NpiPaymentStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => NpiPaymentStatus.none,
    );
  }

  bool get isTerminal =>
      this == succeeded || this == failed || this == cancelled || this == expired;

  bool get isFinalSuccess => this == succeeded;
}

class PaymentStatusService {
  final FirebaseFirestore _db;

  PaymentStatusService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Listens to the payment status of a trade transaction. The status is
  /// kept in sync server-side, so the app does not poll NCHL directly.
  Stream<NpiPaymentStatus> listenToPaymentStatus(String transactionId) {
    return _db
        .collection('transactions')
        .doc(transactionId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return NpiPaymentStatus.fromString(data?['paymentStatus']?.toString());
    })
        .distinct();
  }

  /// One-shot read, useful on cold start before subscribing.
  Future<NpiPaymentStatus> getPaymentStatus(String transactionId) async {
    final snapshot =
        await _db.collection('transactions').doc(transactionId).get();
    return NpiPaymentStatus.fromString(
      snapshot.data()?['paymentStatus']?.toString(),
    );
  }
}