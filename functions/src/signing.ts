import {
  createPrivateKey,
  createPublicKey,
  sign,
  verify,
  type KeyObject,
} from 'node:crypto';
import { readFileSync } from 'node:fs';

/**
 * Any way the runtime can be given a private key. PEM is the supported format;
 * legacy NCHL PFX files (RC2-40-CBC) cannot be read in-process, so convert once
 * with:
 *   openssl pkcs12 -legacy -in X.pfx -out X.pem -nodes -passin pass:<pw>
 */
export interface KeySource {
  pemBase64?: string;
  pemPath?: string;
  pfxBase64?: string;
  pfxPath?: string;
  password?: string;
}

/**
 * Unified private-key loader. Order: PEM base64 → PEM path → (PFX unsupported,
 * error with conversion hint). The key is only ever used in-memory here — never
 * logged and never shipped to the mobile app.
 */
export function loadPrivateKey(src: KeySource): KeyObject {
  if (src.pemBase64 && src.pemBase64.length > 0) {
    return createPrivateKey(Buffer.from(src.pemBase64, 'base64'));
  }
  if (src.pemPath && src.pemPath.length > 0) {
    return createPrivateKey(readFileSync(src.pemPath));
  }
  if (src.pfxBase64 || src.pfxPath) {
    throw new Error(
      'PFX/legacy certificate unsupported in-process. Convert to PEM once with: ' +
        'openssl pkcs12 -legacy -in <file>.pfx -out <file>.pem -nodes -passin pass:<password>',
    );
  }
  throw new Error('No private key configured for signing');
}

/**
 * SHA256withRSA signature over `message`, base64-encoded — exactly the
 * ConnectIPS "token" the NCHL endpoints verify (both direct) and the format our
 * callers (connectips.ts / qr.ts) send to NCHL.
 */
export function signSha256RsaBase64(privateKey: KeyObject, message: string): string {
  return sign('sha256', Buffer.from(message, 'utf8'), privateKey).toString('base64');
}

/**
 * Verifies a base64 SHA256withRSA signature using a peer's public key.
 * `publicKey` may be a PEM/SPKI string, its base64 SPKI form (as issued in the
 * Gateway QR doc, e.g. NPI_QR_PUBLIC_KEY), or an already-parsed KeyObject.
 */
export function verifySha256RsaBase64(
  publicKey: string | KeyObject,
  message: string,
  signatureBase64: string,
): boolean {
  const key: KeyObject =
    typeof publicKey === 'string'
      ? publicKey.trim().startsWith('-----BEGIN')
        ? createPublicKey(publicKey)
        : createPublicKey({
            key: Buffer.from(publicKey, 'base64'),
            format: 'der',
            type: 'spki',
          })
      : publicKey;
  return verify('sha256', Buffer.from(message, 'utf8'), key, Buffer.from(signatureBase64, 'base64'));
}