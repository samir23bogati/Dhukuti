import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:suvha_investment/config/npi_config.dart';

class NpiApiException implements Exception {
  final int statusCode;
  final String message;

  const NpiApiException(this.statusCode, this.message);

  @override
  String toString() => 'NpiApiException($statusCode): $message';
}

/// App-facing client for Suvha's own payment backend.
///
/// The backend holds the NPI.pfx / CREDITOR.pfx signing certs, signs
/// requests to NCHL, manages the Gateway QR WebSocket and webhooks, and
/// persists the outcome in Firestore. The app NEVER talks to NCHL directly;
/// it only calls these authenticated endpoints.
class NpiService {
  final NpiConfig _config;
  final http.Client _client;

  NpiService({NpiConfig? config, http.Client? client})
      : _config = config ?? NpiConfig.fromEnvironment(),
        _client = client ?? http.Client();

  bool get isConfigured => _config.baseUrl.isNotEmpty;

  Uri _uri(String path) => Uri.parse('${_config.baseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_config.appApiKey != null) 'X-Api-Key': _config.appApiKey!,
      };

  /// Start a ConnectIPS payment against an existing trade transaction.
  /// Returns a payment id (ConnectIPS transaction id) to poll/listen on.
  Future<Map<String, dynamic>> createPayment({
    required String transactionId,
    required double amount,
    required String currency,
    required String payerAccountNumber,
  }) async {
    _ensureConfigured();
    final response = await _client.post(
      _uri('/v1/payments'),
      headers: _headers,
      body: jsonEncode({
        'transactionId': transactionId,
        'amount': amount,
        'currency': currency,
        'payerAccountNumber': payerAccountNumber,
      }),
    );
    return _decode(response);
  }

  /// Explicit status lookup from the backend (ConnectIPS status inquiry).
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    _ensureConfigured();
    final response = await _client.get(
      _uri('/v1/payments/$paymentId'),
      headers: _headers,
    );
    return _decode(response);
  }

  /// Fetch the Gateway QR payload (image data / content) to render on the
  /// trade landing page. Prefer only URL content; image bytes stay server-side.
  Future<String> getGatewayQrContent(String paymentId) async {
    _ensureConfigured();
    final response = await _client.get(
      _uri('/v1/payments/$paymentId/qr'),
      headers: _headers,
    );
    final data = _decode(response);
    return data['qrContent'] as String;
  }

  /// Cancel an in-flight payment (expiry / user back-out). Read-only for now.
  Future<void> cancelPayment(String paymentId) async {
    _ensureConfigured();
    final response = await _client.delete(
      _uri('/v1/payments/$paymentId'),
      headers: _headers,
    );
    _decode(response);
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const NpiApiException(
        0,
        'NPI backend not configured. Pass NPI_BASE_URL via --dart-define.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body;
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw NpiApiException(response.statusCode, 'Invalid response body');
    }
    if (response.statusCode >= 400) {
      throw NpiApiException(
        response.statusCode,
        decoded['message']?.toString() ?? decoded['error']?.toString() ??
            'Payment backend error',
      );
    }
    return decoded;
  }
}