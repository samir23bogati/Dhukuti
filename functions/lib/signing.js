"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadPrivateKey = loadPrivateKey;
exports.signSha256RsaBase64 = signSha256RsaBase64;
exports.verifySha256RsaBase64 = verifySha256RsaBase64;
const node_crypto_1 = require("node:crypto");
const node_fs_1 = require("node:fs");
/**
 * Unified private-key loader. Order: PEM base64 → PEM path → (PFX unsupported,
 * error with conversion hint). The key is only ever used in-memory here — never
 * logged and never shipped to the mobile app.
 */
function loadPrivateKey(src) {
    if (src.pemBase64 && src.pemBase64.length > 0) {
        return (0, node_crypto_1.createPrivateKey)(Buffer.from(src.pemBase64, 'base64'));
    }
    if (src.pemPath && src.pemPath.length > 0) {
        return (0, node_crypto_1.createPrivateKey)((0, node_fs_1.readFileSync)(src.pemPath));
    }
    if (src.pfxBase64 || src.pfxPath) {
        throw new Error('PFX/legacy certificate unsupported in-process. Convert to PEM once with: ' +
            'openssl pkcs12 -legacy -in <file>.pfx -out <file>.pem -nodes -passin pass:<password>');
    }
    throw new Error('No private key configured for signing');
}
/**
 * SHA256withRSA signature over `message`, base64-encoded — exactly the
 * ConnectIPS "token" the NCHL endpoints verify (both direct) and the format our
 * callers (connectips.ts / qr.ts) send to NCHL.
 */
function signSha256RsaBase64(privateKey, message) {
    return (0, node_crypto_1.sign)('sha256', Buffer.from(message, 'utf8'), privateKey).toString('base64');
}
/**
 * Verifies a base64 SHA256withRSA signature using a peer's public key.
 * `publicKey` may be a PEM/SPKI string, its base64 SPKI form (as issued in the
 * Gateway QR doc, e.g. NPI_QR_PUBLIC_KEY), or an already-parsed KeyObject.
 */
function verifySha256RsaBase64(publicKey, message, signatureBase64) {
    const key = typeof publicKey === 'string'
        ? publicKey.trim().startsWith('-----BEGIN')
            ? (0, node_crypto_1.createPublicKey)(publicKey)
            : (0, node_crypto_1.createPublicKey)({
                key: Buffer.from(publicKey, 'base64'),
                format: 'der',
                type: 'spki',
            })
        : publicKey;
    return (0, node_crypto_1.verify)('sha256', Buffer.from(message, 'utf8'), key, Buffer.from(signatureBase64, 'base64'));
}
//# sourceMappingURL=signing.js.map