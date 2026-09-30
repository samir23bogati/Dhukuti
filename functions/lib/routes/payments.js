"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentsRouter = void 0;
const express_1 = require("express");
const config_1 = require("../config");
const signing_1 = require("../signing");
const connectips_1 = require("../connectips");
const firestore_1 = require("../firestore");
exports.paymentsRouter = (0, express_1.Router)();
function fmtTxnDate(d) {
    const dd = String(d.getDate()).padStart(2, '0');
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    return `${dd}-${mm}-${d.getFullYear()}`;
}
/**
 * POST /v1/payments
 * Body: { transactionId, amount, currency?, payerAccountNumber? }
 * Replies with { paymentId, status, initiationFields, redirectUrl, qrUrl },
 * the exact contract lib/services/npi_service.dart consumes.
 */
exports.paymentsRouter.post('/', async (req, res) => {
    const { transactionId, amount, currency, payerAccountNumber } = req.body ?? {};
    if (!transactionId || typeof amount !== 'number' || amount <= 0) {
        return res.status(400).json({ message: 'transactionId and amount are required' });
    }
    const tx = await (0, firestore_1.getTransactionData)(transactionId);
    if (!tx)
        return res.status(404).json({ message: 'transaction not found' });
    const config = (0, config_1.loadConfig)();
    const key = (0, signing_1.loadPrivateKey)(config.creditorKey);
    // ConnectIPS amounts are integer paisa. TXNID = our Firestore txn id, which
    // is what NCHL echoes back to redirect/webhook URLs for reconciliation.
    const paisa = String(Math.round(amount * 100));
    const paymentId = transactionId;
    const initiationFields = (0, connectips_1.buildInitiationFields)(config, {
        txnId: paymentId,
        amountPaisa: paisa,
        currency: currency ?? 'NPR',
        referenceId: paymentId,
        remarks: payerAccountNumber ?? '',
        particulars: 'Suvha Investment trade',
        txnDate: fmtTxnDate(new Date()),
    }, key);
    const pendingMeta = {
        paymentStatus: 'pending',
        connectipsReferenceId: paymentId,
        amountPaisa: paisa,
        currency: currency ?? 'NPR',
        initiatedAt: Date.now(),
    };
    if (config.mode === 'test') {
        pendingMeta.qrContent = 'TEST-QR:' + paymentId;
    }
    await (0, firestore_1.setPaymentPending)(paymentId, pendingMeta);
    // In test mode we point the app at our simulator page (which bounces back via
    // the suvhaval deep link) instead of the real ConnectIPS loginpage. The URL
    // must be reachable from the device itself.
    const testModeUrl = `${config.testBaseUrl}/v1/test/pay/${paymentId}`;
    res.json({
        paymentId,
        status: 'pending',
        initiationFields,
        redirectUrl: config.mode === 'test' ? testModeUrl : config.connectipsBaseUrl,
        qrUrl: `/v1/payments/${paymentId}/qr`,
    });
});
/**
 * GET /v1/payments/:paymentId
 * Returns last known status; refreshes from ConnectIPS unless already terminal.
 */
exports.paymentsRouter.get('/:paymentId', async (req, res) => {
    const { paymentId } = req.params;
    const tx = await (0, firestore_1.getTransactionData)(paymentId);
    if (!tx || !tx.paymentStatus) {
        return res.status(404).json({ message: 'payment not found' });
    }
    let status = String(tx.paymentStatus);
    const amountPaisa = String(tx.amountPaisa ?? '');
    const terminal = ['succeeded', 'failed', 'cancelled', 'expired'].includes(status);
    const config = (0, config_1.loadConfig)();
    // Only poke the real NCHL validatetxn API in live mode; in test mode the
    // simulator already wrote the terminal paymentStatus to Firestore.
    if (!terminal && amountPaisa && config.mode === 'live') {
        try {
            const client = new connectips_1.ConnectIPSTxnDetailsClient(config, (0, signing_1.loadPrivateKey)(config.creditorKey));
            const v = await client.validateTxn(paymentId, amountPaisa);
            if ((0, connectips_1.isCreditSuccess)(v.creditStatus)) {
                status = 'succeeded';
            }
            else if (v.creditStatus) {
                status = 'failed';
            }
            if (status !== tx.paymentStatus) {
                await (0, firestore_1.updatePaymentStatus)(paymentId, status, { creditStatus: v.creditStatus ?? null });
            }
        }
        catch (e) {
            console.error(`validatetxn failed for ${paymentId}:`, e);
        }
    }
    res.json({
        paymentId,
        status,
        connectipsReferenceId: tx.connectipsReferenceId ?? null,
        connectipsTxnId: tx.connectipsTxnId ?? null,
        amountPaisa: tx.amountPaisa ?? null,
        currency: tx.currency ?? 'NPR',
    });
});
/**
 * GET /v1/payments/:paymentId/qr
 * Returns { qrContent } — the values the app renders on the landing page.
 * Content is populated asynchronously by the QR WebSocket handler after the
 * request is sent; returns 409 until it lands.
 */
exports.paymentsRouter.get('/:paymentId/qr', async (req, res) => {
    const { paymentId } = req.params;
    const tx = await (0, firestore_1.getTransactionData)(paymentId);
    if (!tx || !tx.paymentStatus) {
        return res.status(404).json({ message: 'payment not found' });
    }
    if (typeof tx.qrContent === 'string' && tx.qrContent.length > 0) {
        return res.json({ qrContent: tx.qrContent });
    }
    res.status(409).json({ message: 'QR not generated yet' });
});
/** DELETE /v1/payments/:paymentId — local cancel (no ConnectIPS cancel). */
exports.paymentsRouter.delete('/:paymentId', async (req, res) => {
    const { paymentId } = req.params;
    await (0, firestore_1.markCancelled)(paymentId);
    res.json({ paymentId, status: 'cancelled' });
});
//# sourceMappingURL=payments.js.map