import { Router } from 'express';
import { loadConfig } from '../config';
import { loadPrivateKey } from '../signing';
import { ConnectIPSTxnDetailsClient, isCreditSuccess } from '../connectips';
import { getTransactionData, updatePaymentStatus } from '../firestore';

export const webhooksRouter = Router();

/**
 * Reconciles a payment by calling ConnectIPS validatetxn with the stored
 * amount (so the signed token matches) and advancing Firestore so the app's
 * PaymentStatusService stream flips to succeeded / failed.
 */
async function settle(referenceId: string): Promise<string> {
  const tx = await getTransactionData(referenceId);
  const amountPaisa = tx?.amountPaisa;
  if (!tx || !amountPaisa) {
    throw new Error(`Cannot settle unknown payment ${referenceId}`);
  }

  const config = loadConfig();
  const client = new ConnectIPSTxnDetailsClient(
    config,
    loadPrivateKey(config.creditorKey),
  );
  const v = await client.validateTxn(referenceId, String(amountPaisa));

  if (isCreditSuccess(v.creditStatus)) {
    await updatePaymentStatus(referenceId, 'succeeded', {
      connectipsTxnId: v.txnId ? String(v.txnId) : null,
    });
    return 'succeeded';
  }
  await updatePaymentStatus(referenceId, 'failed', {
    creditStatus: String(v.creditStatus ?? v.status ?? ''),
    statusDesc: String(v.statusDesc ?? ''),
  });
  return 'failed';
}

/**
 * Browser redirect the user lands on after payment. ConnectIPS appends only
 * TXNID to the URL, exactly as the spec states.
 */
webhooksRouter.get('/redirect', async (req, res) => {
  const txnId = String(req.query.TXNID ?? req.query.txnId ?? '');
  const config = loadConfig();
  let target = config.failureUrl || '/';
  if (txnId) {
    try {
      target = (await settle(txnId)) === 'succeeded'
        ? config.successUrl || '/'
        : config.failureUrl || '/';
    } catch (e) {
      console.error(`settle failed for ${txnId}:`, e);
    }
  }
  res.redirect(302, target);
});

/**
 * Server-to-server notification (NPI push / QR gateway callback).
 * Body: { referenceId }  — kicks off the same settlement path.
 */
webhooksRouter.post('/settle', async (_req, res) => {
  const referenceId = String(_req.body?.referenceId ?? '');
  if (!referenceId) return res.status(400).json({ message: 'referenceId required' });
  try {
    await settle(referenceId);
    res.json({ ok: true, referenceId });
  } catch (e) {
    res.status(502).json({ ok: false, message: e instanceof Error ? e.message : String(e) });
  }
});