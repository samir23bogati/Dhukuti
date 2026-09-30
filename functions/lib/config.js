"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NpiEnvironment = void 0;
exports.loadConfig = loadConfig;
var NpiEnvironment;
(function (NpiEnvironment) {
    NpiEnvironment["Sandbox"] = "sandbox";
    NpiEnvironment["Production"] = "production";
})(NpiEnvironment || (exports.NpiEnvironment = NpiEnvironment = {}));
/**
 * All NCHL/NPI credentials come from process env (functions/.env in the
 * emulator; Firebase secret manager in production). The app never sees these.
 */
function env(name) {
    return process.env[name] ?? '';
}
function keySource(prefix) {
    return {
        pemBase64: env(`${prefix}_PEM_BASE64`),
        pemPath: env(`${prefix}_PEM_PATH`),
        pfxBase64: env(`${prefix}_PFX_BASE64`),
        pfxPath: env(`${prefix}_PFX_PATH`),
        password: env(`${prefix}_PFX_PASSWORD`) || '123',
    };
}
function loadConfig() {
    return {
        mode: env('NPI_MODE').toLowerCase() === 'live' ? 'live' : 'test',
        environment: env('NPI_ENV').toLowerCase() === 'production'
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
//# sourceMappingURL=config.js.map