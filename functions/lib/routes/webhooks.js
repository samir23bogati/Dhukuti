"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.webhooksRouter = void 0;
const express_1 = require("express");
const config_1 = require("../config");
const signing_1 = require("../signing");
const connectips_1 = require("../connectips");
const firestore_1 = require("../firestore");
exports.webhooksRouter = (0, express_1.Router)();
/**
 * Reconciles a payment by calling ConnectIPS validatetxn with the stored
 * amount (so the signed token matches) and advancing Firestore so the app's
 * PaymentStatusService stream flips to succeeded / failed.
 */
async function settle(referenceId) {
    const tx = await (0, firestore_1.getTransactionData)(referenceId);
    const amountPaisa = tx?.amountPaisa;
    if (!tx || !amountPaisa) {
        throw new Error(`Cannot settle unknown payment ${referenceId}`);
    }
    const config = (0, config_1.loadConfig)();
    const client = new connectips_1.ConnectIPSTxnDetailsClient(config, (0, signing_1.loadPrivateKey)(config.creditorKey));
    const v = await client.validateTxn(referenceId, String(amountPaisa));
    if ((0, connectips_1.isCreditSuccess)(v.creditStatus)) {
        await (0, firestore_1.updatePaymentStatus)(referenceId, 'succeeded', {
            connectipsTxnId: v.txnId ? String(v.txnId) : null,
        });
        return 'succeeded';
    }
    await (0, firestore_1.updatePaymentStatus)(referenceId, 'failed', {
        creditStatus: String(v.creditStatus ?? v.status ?? ''),
        statusDesc: String(v.statusDesc ?? ''),
    });
    return 'failed';
}
/**
 * Browser redirect the user lands on after payment. ConnectIPS appends only
 * TXNID to the URL, exactly as the spec states.
 */
exports.webhooksRouter.get('/redirect', async (req, res) => {
    const txnId = String(req.query.TXNID ?? req.query.txnId ?? '');
    const config = (0, config_1.loadConfig)();
    let target = config.failureUrl || '/';
    if (txnId) {
        try {
            target = (await settle(txnId)) === 'succeeded'
                ? config.successUrl || '/'
                : config.failureUrl || '/';
        }
        catch (e) {
            console.error(`settle failed for ${txnId}:`, e);
        }
    }
    res.redirect(302, target);
});
/**
 * Server-to-server notification (NPI push / QR gateway callback).
 * Body: { referenceId }  — kicks off the same settlement path.
 */
exports.webhooksRouter.post('/settle', async (_req, res) => {
    const referenceId = String(_req.body?.referenceId ?? '');
    if (!referenceId)
        return res.status(400).json({ message: 'referenceId required' });
    try {
        await settle(referenceId);
        res.json({ ok: true, referenceId });
    }
    catch (e) {
        res.status(502).json({ ok: false, message: e instanceof Error ? e.message : String(e) });
    }
});
//# sourceMappingURL=webhooks.js.map