export enum NpiEnvironment {
  Sandbox = 'sandbox',
  Production = 'production',
}

/**
 * All NCHL/NPI credentials come from process env (functions/.env in the
 * emulator; Firebase secret manager in production). The app never sees these.
 */
function env(name: string): string {
  return process.env[name] ?? '';
}

export interface NpiConfig {
  /** 'test' simulates ConnectIPS locally; 'live' calls the real NCHL endpoints. */
  mode: 'test' | 'live';
  environment: NpiEnvironment;
  connectipsBaseUrl: string;
  /** Base URL of this backend as seen from the DEVICE (used for test-mode
   * redirects). Set to http://10.0.2.2:PORT for the Android emulator or a LAN
   * URL for a physical phone. */
  testBaseUrl: string;
  merchantId: string;
  appId: string;
  appName: string;
  appPassword: string;
  successUrl: string;
  failureUrl: string;
  creditorKey: {
    pemBase64: string;
    pemPath: string;
    pfxBase64: string;
    pfxPath: string;
    password: string;
  };
  qr: {
    username: string;
    apiKey: string;
    publicKey: string;
    wsUrl: string;
    key: {
      pemBase64: string;
      pemPath: string;
      pfxBase64: string;
      pfxPath: string;
      password: string;
    };
  };
}

function keySource(prefix: string): NpiConfig['creditorKey'] {
  return {
    pemBase64: env(`${prefix}_PEM_BASE64`),
    pemPath: env(`${prefix}_PEM_PATH`),
    pfxBase64: env(`${prefix}_PFX_BASE64`),
    pfxPath: env(`${prefix}_PFX_PATH`),
    password: env(`${prefix}_PFX_PASSWORD`) || '123',
  };
}

export function loadConfig(): NpiConfig {
  return {
    mode: env('NPI_MODE').toLowerCase() === 'live' ? 'live' : 'test',
    environment:
      env('NPI_ENV').toLowerCase() === 'production'
        ? NpiEnvironment.Production
        : NpiEnvironment.Sandbox,
    connectipsBaseUrl: env('CONNECTIPS_BASE_URL') || 'https://connectips.nchl.com',
    testBaseUrl: env('NPI_TEST_BASE_URL') || 'http://127.0.0.1:5001',
    merchantId: env('NPI_MERCHANT_ID'),
    appId: env('NPI_APP_ID'),
    appName: env('NPI_APP_NAME') || 'Suvha Investment',
    appPassword: env('NPI_APP_PASSWORD'),
    successUrl: env('NPI_SUCCESS_URL'),
    failureUrl: env('NPI_FAILURE_URL'),
    creditorKey: keySource('NPI_CREDITOR'),
    qr: {
      username: env('NPI_QR_USERNAME'),
      apiKey: env('NPI_QR_API_KEY'),
      publicKey: env('NPI_QR_PUBLIC_KEY'),
      wsUrl: env('NPI_QR_WS_URL'),
      key: keySource('NPI_QR'),
    },
  };
}