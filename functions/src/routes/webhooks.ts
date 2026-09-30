import { Router } from 'express';
import { loadConfig } from '../config';
import { loadPrivateKey } from '../signing';
import { ConnectIPSTxnDetailsClient, isCreditSuccess } from '../connectips';
import { getTransactionData, updatePaymentStatus } from '../firestore';
import { deepLink } from './test';

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

  // Bare GET (no TXNID) — what NCHL/reC see when they open the URL to check
  // it's reachable. Render an informational page instead of bouncing to a 404.
  if (!txnId) {
    const proto = req.headers['x-forwarded-proto'] || 'https';
    const host = req.get('host') || 'localhost';
    const project = process.env.GCLOUD_PROJECT || 'dhukuti-1e030';
    const canonical = `${proto}://${host}/${project}/asia-south1/npi/webhooks/redirect`;
    res.set('Content-Type', 'text/html; charset=utf-8').send(`<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>ConnectIPS Redirect Endpoint</title>
<style>body{font-family:system-ui,sans-serif;background:#0B5F4B;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
.card{background:#fff;border-radius:16px;padding:28px 32px;max-width:520px;box-shadow:0 12px 30px rgba(0,0,0,.25)}
h1{margin:0 0 6px;color:#0B5F4B;font-size:20px} p{color:#444;margin:6px 0}
code{background:#eef4f1;border-radius:6px;padding:2px 6px;font-size:13px;word-break:break-all}</style>
</head><body><div class="card">
<h1>ConnectIPS redirect endpoint is live.</h1>
<p>This URL is registered with NCHL as the success/failure redirect for <b>Suvha Investment</b>.</p>
<p>ConnectIPS appends <code>?TXNID=&lt;transaction-id&gt;</code> and bounces the payer's
browser here; we then validate the payment and return the app to its payment status screen.</p>
<p><b>Reachable via:</b> <code>${canonical}</code></p>
</div></body></html>`);
    return;
  }

  try {
    const result = (await settle(txnId)) === 'succeeded' ? 'success' : 'failure';
    res.redirect(302, deepLink(txnId, result));
  } catch (e) {
    console.error(`settle failed for ${txnId}:`, e);
    res.redirect(302, deepLink(txnId, 'failure'));
  }
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