enum NpiEnvironment { sandbox, production }

class NpiConfig {
  final NpiEnvironment environment;
  final String baseUrl;

  /// Optional app-level key issued by our own backend (not the NCHL API key).
  final String? appApiKey;

  const NpiConfig({
    required this.environment,
    required this.baseUrl,
    this.appApiKey,
  });

  // Compile-time overrides. Provide at build time, e.g.:
  //   flutter build apk --dart-define=NPI_ENV=sandbox \
  //     --dart-define=NPI_BASE_URL=https://pay.suvhainvestment.test \
  //     --dart-define=NPI_APP_API_KEY=...
  // Secrets for the NCHL/NPI gateway (NPI.pfx, CREDITOR.pfx, API keys) are
  // NEVER shipped with the app. They live on the payment backend only.
  static const String _envDefaultUrl = String.fromEnvironment('NPI_BASE_URL');
  static const String _envApiKey = String.fromEnvironment('NPI_APP_API_KEY');
  static const String _envType = String.fromEnvironment('NPI_ENV');

  factory NpiConfig.fromEnvironment() {
    final environment = _envType == 'production'
        ? NpiEnvironment.production
        : NpiEnvironment.sandbox;
    return NpiConfig(
      environment: environment,
      baseUrl: _envDefaultUrl,
      appApiKey: _envApiKey.isEmpty ? null : _envApiKey,
    );
  }

  bool get isSandbox => environment == NpiEnvironment.sandbox;

  /// Payment is only reachable when a backend URL is compiled in via
  /// --dart-define=NPI_BASE_URL=... ; otherwise the old manual flow stays.
  bool get isConfigured => baseUrl.isNotEmpty;
}