import { NpiConfig } from './config';
import { signSha256RsaBase64 } from './signing';
import type { KeyObject } from 'node:crypto';

type PrivateKey = KeyObject;

export interface QrStatusEvent {
  txnId: string;
  status: 'pending' | 'initiated' | 'processing' | 'success' | 'failed' | 'cancelled' | 'expired';
  creditStatus?: string;
  message?: string;
}

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
export class QrGatewayClient {
  private ws: WebSocket | null = null;
  private readonly state: { ready: Promise<void>; open: (() => void) | null } = {
    ready: Promise.resolve(),
    open: null,
  };

  constructor(
    private readonly config: NpiConfig,
    private readonly privateKey: PrivateKey,
  ) {}

  connect(): Promise<void> {
    this.state.ready = new Promise<void>((resolve) => {
      this.state.open = resolve;
    });
    this.ws = new WebSocket(this.config.qr.wsUrl);
    this.ws.onopen = () => this.state.open?.();
    return this.state.ready;
  }

  onStatus(handler: (event: QrStatusEvent) => void): void {
    if (!this.ws) throw new Error('QR gateway not connected');
    this.ws.onmessage = (raw) => {
      const data = JSON.parse(String((raw as MessageEvent).data)) as Record<string, unknown>;
      handler(mapToStatusEvent(data));
    };
  }

  /** Requests a QR for a transaction and returns whether it was accepted. */
  requestQr(payload: QrGatewayPayload): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      throw new Error('QR gateway not connected');
    }
    this.ws.send(JSON.stringify(buildQrRequest(this.config, this.privateKey, payload)));
  }

  close(): void {
    this.ws?.close();
    this.ws = null;
  }
}

/** Payload for a Gateway QR request — confirm exact keys with the NCHL spec. */
export interface QrGatewayPayload {
  userId: string; // e.g. shuvainvestgwqr
  txnId: string;
  txnDate: string; // DD-MM-YYYY
  amountPaisa: string;
  referenceId: string;
}

/** Sign the request with NPI.pfx so the QR server can verify the merchant. */
export function buildQrRequest(
  config: NpiConfig,
  privateKey: PrivateKey,
  p: QrGatewayPayload,
): Record<string, string> {
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
    token: signSha256RsaBase64(privateKey, tokenText),
  };
}

function mapToStatusEvent(data: Record<string, unknown>): QrStatusEvent {
  const raw = String(data['status'] ?? data['creditStatus'] ?? 'pending');
  const normalized = raw.includes('SUCCESS') || ['000', '999', 'DEFER'].includes(raw)
    ? 'success'
    : raw.toLowerCase();
  const status = (['pending', 'initiated', 'processing', 'success', 'failed', 'cancelled', 'expired'] as const)
    .find((s) => normalized.startsWith(s)) ?? 'pending';
  return {
    txnId: String(data['txnId'] ?? data['referenceId'] ?? ''),
    status,
    creditStatus: data['creditStatus'] !== undefined ? String(data['creditStatus']) : undefined,
    message: data['message'] !== undefined ? String(data['message']) : undefined,
  };
}