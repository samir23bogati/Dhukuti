"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.QrGatewayClient = void 0;
exports.buildQrRequest = buildQrRequest;
const signing_1 = require("./signing");
/**
 * Minimal WebSocket client for the NPI Gateway QR channel the user opens on the
 * payment landing page (username from NCHL, e.g. shuvainvestgwqr).
 *
 * NOTE: the exact wire message schema for the Gateway QR WebSocket lives in the
 * NCHL "Gateway QR" spec (docs_npiqrgt). This client implements the mechanics
 * (connect, send a request, emit status events) and maps NCHL statuses onto the
 * Firestore payment lifecycle, but the request payload field names must be
 * confirmed against the spec before going live. Update QrGatewayPayload below.
 */
class QrGatewayClient {
    config;
    privateKey;
    ws = null;
    state = {
        ready: Promise.resolve(),
        open: null,
    };
    constructor(config, privateKey) {
        this.config = config;
        this.privateKey = privateKey;
    }
    connect() {
        this.state.ready = new Promise((resolve) => {
            this.state.open = resolve;
        });
        this.ws = new WebSocket(this.config.qr.wsUrl);
        this.ws.onopen = () => this.state.open?.();
        return this.state.ready;
    }
    onStatus(handler) {
        if (!this.ws)
            throw new Error('QR gateway not connected');
        this.ws.onmessage = (raw) => {
            const data = JSON.parse(String(raw.data));
            handler(mapToStatusEvent(data));
        };
    }
    /** Requests a QR for a transaction and returns whether it was accepted. */
    requestQr(payload) {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            throw new Error('QR gateway not connected');
        }
        this.ws.send(JSON.stringify(buildQrRequest(this.config, this.privateKey, payload)));
    }
    close() {
        this.ws?.close();
        this.ws = null;
    }
}
exports.QrGatewayClient = QrGatewayClient;
/** Sign the request with NPI.pfx so the QR server can verify the merchant. */
function buildQrRequest(config, privateKey, p) {
    const tokenText = [
        `USERID=${p.userId}`,
        `TXNID=${p.txnId}`,
        `TXNDATE=${p.txnDate}`,
        `TXNAMT=${p.amountPaisa}`,
        `REFERENCEID=${p.referenceId}`,
        'TOKEN=TOKEN',
    ].join(',');
    return {
        username: config.qr.username,
        apiKey: config.qr.apiKey,
        txnId: p.txnId,
        txnDate: p.txnDate,
        txnAmt: p.amountPaisa,
        referenceId: p.referenceId,
        token: (0, signing_1.signSha256RsaBase64)(privateKey, tokenText),
    };
}
function mapToStatusEvent(data) {
    const raw = String(data['status'] ?? data['creditStatus'] ?? 'pending');
    const normalized = raw.includes('SUCCESS') || ['000', '999', 'DEFER'].includes(raw)
        ? 'success'
        : raw.toLowerCase();
    const status = ['pending', 'initiated', 'processing', 'success', 'failed', 'cancelled', 'expired']
        .find((s) => normalized.startsWith(s)) ?? 'pending';
    return {
        txnId: String(data['txnId'] ?? data['referenceId'] ?? ''),
        status,
        creditStatus: data['creditStatus'] !== undefined ? String(data['creditStatus']) : undefined,
        message: data['message'] !== undefined ? String(data['message']) : undefined,
    };
}
//# sourceMappingURL=qr.js.map