import { Router } from 'express';
import { loadConfig } from '../config';
import { getTransactionData, updatePaymentStatus } from '../firestore';

export const testRouter = Router();

/** Static deep link the app registers (see AndroidManifest intent-filter). */
export const DEEP_LINK_SCHEME = 'suvhaval';

export function deepLink(paymentId: string, status: 'success' | 'failure'): string {
  return `${DEEP_LINK_SCHEME}://payment/${paymentId}?status=${status}`;
}

/**
 * TEST ONLY — simulated ConnectIPS login page. In live mode the real redirect
 * is the NCHL loginpage; this lets us run the whole BUY flow end-to-end with
 * no NCHL access. Live code in routes/webhooks.ts is untouched.
 */
testRouter.get('/pay/:paymentId', async (req, res) => {
  const config = loadConfig();
  if (config.mode !== 'test') {
    return res.status(404).json({ message: 'Test endpoints only available in test mode' });
  }
  const { paymentId } = req.params;
  const tx = await getTransactionData(paymentId);
  if (!tx || !tx.paymentStatus) {
    return res.status(404).json({ message: 'payment not found' });
  }
  const amount = (Number(tx.amountPaisa ?? 0) / 100).toLocaleString('en-US', {
    minimumFractionDigits: 2,
  });
  const base = loadConfig().testBaseUrl;
  res.set('Content-Type', 'text/html; charset=utf-8').send(`<!doctype html>
<html lang="en">
<head><meta name="viewport" content="width=device-width, initial-scale=1">
<title>ConnectIPS (TEST)</title>
<style>
  body{font-family:system-ui,-apple-system,sans-serif;background:#f4f5f7;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
  .card{background:#fff;border-radius:16px;box-shadow:0 10px 30px rgba(0,0,0,.12);padding:32px;max-width:380px;width:100%;text-align:center}
  h2{color:#0B5F4B;margin-top:0} .amt{font-size:26px;font-weight:700;color:#111}
  .gp{font-size:12px;color:#888;margin:6px 0 22px}
  .row{display:flex;gap:12px;margin-top:8px}
  button{flex:1;border:0;border-radius:10px;padding:14px;font-size:15px;font-weight:600;cursor:pointer;color:#fff}
  .ok{background:#22a06b} .no{background:#e5484d}
  .note{margin-top:18px;font-size:11px;color:#999}
</style></head>
<body>
  <div class="card">
    <h2>ConnectIPS &middot; SIMULATION</h2>
    <div class="amt">NPR ${amount}</div>
    <div class="gp">TXNID: ${paymentId}</div>
    <form method="POST" action="${base}/v1/test/complete/${paymentId}" class="row">
      <button type="submit" name="result" value="success" class="ok">Simulate Success</button>
      <button type="submit" name="result" value="failure" class="no">Simulate Failure</button>
    </form>
    <div class="note">Test page only — replaces the real ConnectIPS login while NPI_MODE=test.</div>
  </div>
</body></html>`);
});

/**
 * TEST ONLY — completes a simulated payment, advances Firestore exactly like
 * the live webhook would, then bounces the user back into the Flutter app via
 * the deep link.
 */
testRouter.post('/complete/:paymentId', async (req, res) => {
  const config = loadConfig();
  if (config.mode !== 'test') {
    return res.status(404).json({ message: 'Test endpoints only available in test mode' });
  }
  const { paymentId } = req.params;
  const result = String(req.body?.result ?? 'success');

  const tx = await getTransactionData(paymentId);
  if (!tx || !tx.paymentStatus) {
    return res.status(404).json({ message: 'payment not found' });
  }

  if (result === 'success') {
    await updatePaymentStatus(paymentId, 'succeeded', {
      connectipsReferenceId: paymentId,
      creditStatus: '000',
      testMode: true,
    });
  } else {
    await updatePaymentStatus(paymentId, 'failed', {
      creditStatus: '999',
      testMode: true,
    });
  }

  res.redirect(302, deepLink(paymentId, result === 'success' ? 'success' : 'failure'));
});