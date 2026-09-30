import { NpiConfig } from './config';
import { signSha256RsaBase64 } from './signing';
import type { KeyObject } from 'node:crypto';

type PrivateKey = KeyObject;

export interface InitiationParams {
  txnId: string;
  amountPaisa: string;
  currency: string;
  referenceId: string;
  remarks: string;
  particulars: string;
  txnDate: string; // DD-MM-YYYY
}

/**
 * Builds the token signing string for the merchant-interface form POST, exactly
 * per the ConnectIPS spec:
 *   MERCHANTID=..,APPID=..,APPNAME=..,TXNID=..,TXNDATE=..,TXNCRNCY=..,
 *   TXNAMT=..,REFERENCEID=..,REMARKS=..,PARTICULARS=..,TOKEN=TOKEN
 */
export function buildInitiationToken(
  config: NpiConfig,
  p: InitiationParams,
): string {
  return [
    `MERCHANTID=${config.merchantId}`,
    `APPID=${config.appId}`,
    `APPNAME=${config.appName}`,
    `TXNID=${p.txnId}`,
    `TXNDATE=${p.txnDate}`,
    `TXNCRNCY=${p.currency}`,
    `TXNAMT=${p.amountPaisa}`,
    `REFERENCEID=${p.referenceId}`,
    `REMARKS=${p.remarks}`,
    `PARTICULARS=${p.particulars}`,
    'TOKEN=TOKEN',
  ].join(',');
}

/** Hidden form fields to POST to ConnectIPS to open the payment page. */
export function buildInitiationFields(
  config: NpiConfig,
  p: InitiationParams,
  privateKey: PrivateKey,
): Record<string, string> {
  const token = signSha256RsaBase64(
    privateKey,
    buildInitiationToken(config, p),
  );
  return {
    MERCHANTID: config.merchantId,
    APPID: config.appId,
    APPNAME: config.appName,
    TXNID: p.txnId,
    TXNDATE: p.txnDate,
    TXNCRNCY: p.currency,
    TXNAMT: p.amountPaisa,
    REFERENCEID: p.referenceId,
    REMARKS: p.remarks,
    PARTICULARS: p.particulars,
    TOKEN: token,
  };
}

/**
 * Token string for the REST status endpoints (validatetxn / gettxndetail):
 *   MERCHANTID=..,APPID=..,REFERENCEID=..,TXNAMT=..  (amount in paisa)
 */
export function buildValidationToken(
  config: NpiConfig,
  referenceId: string,
  amountPaisa: string,
): string {
  return [
    `MERCHANTID=${config.merchantId}`,
    `APPID=${config.appId}`,
    `REFERENCEID=${referenceId}`,
    `TXNAMT=${amountPaisa}`,
  ].join(',');
}

export interface ValidationResult {
  status: string;
  statusDesc: string;
  creditStatus?: string;
  txnAmt?: number;
  refId?: string;
  [key: string]: unknown;
}

export class ConnectIPSTxnDetailsClient {
  constructor(
    private readonly config: NpiConfig,
    private readonly privateKey: PrivateKey,
  ) {}

  private get baseUrl(): string {
    return `${this.config.connectipsBaseUrl}/connectipswebws/api/creditor`;
  }

  private authHeader(): Record<string, string> {
    const basic = Buffer.from(`${this.config.appId}:${this.config.appPassword}`).toString('base64');
    return { Authorization: `Basic ${basic}`, 'Content-Type': 'application/json' };
  }

  /**
   * Checks the current status of a payment. referenceId is the TXNID we sent
   * at initiation, amountPaisa the original amount so the token matches.
   */
  async validateTxn(referenceId: string, amountPaisa: string): Promise<ValidationResult> {
    const token = signSha256RsaBase64(
      this.privateKey,
      buildValidationToken(this.config, referenceId, amountPaisa),
    );
    const body = {
      merchantId: this.config.merchantId,
      appId: this.config.appId,
      referenceId,
      txnAmt: amountPaisa,
      token,
    };
    const res = await fetch(`${this.baseUrl}/validatetxn`, {
      method: 'POST',
      headers: this.authHeader(),
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      throw new Error(`validatetxn HTTP ${res.status}: ${await res.text()}`);
    }
    return (await res.json()) as ValidationResult;
  }

  /** Full transaction details (debit bank, batch, charge, etc.). */
  async getTxnDetail(referenceId: string, amountPaisa: string): Promise<ValidationResult> {
    const token = signSha256RsaBase64(
      this.privateKey,
      buildValidationToken(this.config, referenceId, amountPaisa),
    );
    const body = {
      merchantId: this.config.merchantId,
      appId: this.config.appId,
      referenceId,
      txnAmt: amountPaisa,
      token,
    };
    const res = await fetch(`${this.baseUrl}/gettxndetail`, {
      method: 'POST',
      headers: this.authHeader(),
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      throw new Error(`gettxndetail HTTP ${res.status}: ${await res.text()}`);
    }
    return (await res.json()) as ValidationResult;
  }
}

/** ConnectIPS creditStatus: 000 / 999 / DEFER all mean success. */
export function isCreditSuccess(creditStatus?: string): boolean {
  return ['000', '999', 'DEFER'].includes(creditStatus ?? '');
}