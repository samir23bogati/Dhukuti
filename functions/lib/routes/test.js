"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEEP_LINK_SCHEME = exports.testRouter = void 0;
exports.deepLink = deepLink;
const express_1 = require("express");
const config_1 = require("../config");
const firestore_1 = require("../firestore");
exports.testRouter = (0, express_1.Router)();
/** Static deep link the app registers (see AndroidManifest intent-filter). */
exports.DEEP_LINK_SCHEME = 'suvhaval';
function deepLink(paymentId, status) {
    return `${exports.DEEP_LINK_SCHEME}://payment/${paymentId}?status=${status}`;
}
/**
 * TEST ONLY — simulated ConnectIPS login page. In live mode the real redirect
 * is the NCHL loginpage; this lets us run the whole BUY flow end-to-end with
 * no NCHL access. Live code in routes/webhooks.ts is untouched.
 */
exports.testRouter.get('/pay/:paymentId', async (req, res) => {
    const config = (0, config_1.loadConfig)();
    if (config.mode !== 'test') {
        return res.status(404).json({ message: 'Test endpoints only available in test mode' });
    }
    const { paymentId } = req.params;
    const tx = await (0, firestore_1.getTransactionData)(paymentId);
    if (!tx || !tx.paymentStatus) {
        return res.status(404).json({ message: 'payment not found' });
    }
    const amount = (Number(tx.amountPaisa ?? 0) / 100).toLocaleString('en-US', {
        minimumFractionDigits: 2,
    });
    const base = (0, config_1.loadConfig)().testBaseUrl;
    const meta = `<meta name="viewport" content="width=device-width, initial-scale=1">`;
    res.set('Content-Type', 'text/html; charset=utf-8').send(`<!doctype html>
<html lang="en">
<head>${meta}
<title>ConnectIPS · Test</title>
<style>
  :root{--g:#0B5F4B;--g2:#15805f;--ink:#11231c;--mut:#717d78;--bg:#eceef0;--card:#ffffff;--err:#e5484d;--ok:#22a06b}
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:var(--bg);
       display:flex;align-items:center;justify-content:center;min-height:100vh;color:var(--ink)}
  .wrap{width:100%;max-width:400px;padding:16px}
  .bar{background:linear-gradient(135deg,var(--g),var(--g2));border-radius:18px 18px 0 0;padding:18px 22px;color:#fff;
       display:flex;align-items:center;gap:10px}
  .bar .dot{width:34px;height:34px;border-radius:50%;background:rgba(255,255,255,.18);display:flex;align-items:center;justify-content:center;font-weight:800}
  .bar h1{font-size:15px;font-weight:700;letter-spacing:.2px}
  .bar small{display:block;font-weight:400;opacity:.8;font-size:11px}
  .card{background:var(--card);border-radius:0 0 18px 18px;padding:24px 22px;box-shadow:0 12px 30px rgba(17,35,28,.10)}
  .amt{font-size:30px;font-weight:800;color:var(--g)}
  .lbl{font-size:11px;letter-spacing:.6px;text-transform:uppercase;color:var(--mut)}
  .row{display:flex;justify-content:space-between;align-items:baseline;border-bottom:1px solid #eef1ef;padding:10px 0}
  .row:last-of-type{border-bottom:0}
  .row .v{font-weight:600;color:var(--ink);text-align:right;word-break:break-all}
  .tag{display:inline-block;background:#eaf6f0;color:var(--g);font-size:11px;font-weight:700;
       border-radius:999px;padding:5px 10px;margin-bottom:14px}
  button{flex:1;border:0;border-radius:12px;padding:15px;font-size:15px;font-weight:700;cursor:pointer;color:#fff}
  .btns{display:flex;gap:12px;margin-top:18px}
  .ok{background:var(--ok)} .no{background:var(--err)}
  button:active{transform:scale(.98)}
  .note{margin-top:16px;text-align:center;font-size:11px;color:#9aa49f}
  @media (max-width:340px){.btns{flex-direction:column}.amt{font-size:24px}}
</style></head>
<body>
  <div class="wrap">
    <div class="bar">
      <span class="dot">C</span>
      <div><h1>ConnectIPS Simulator</h1><small>Test environment · Suvha Investment</small></div>
    </div>
    <div class="card">
      <span class="tag">TEST ONLY</span>
      <div class="lbl">Amount</div>
      <div class="amt">NPR ${amount}</div>
      <div style="margin-top:16px">
        <div class="row"><span class="lbl">TXN ID</span><span class="v">${paymentId}</span></div>
        <div class="row"><span class="lbl">Currency</span><span class="v">NPR</span></div>
      </div>
      <form method="POST" action="${base}/v1/test/complete/${paymentId}" class="btns">
        <button type="submit" name="result" value="success" class="ok">Simulate Success</button>
        <button type="submit" name="result" value="failure" class="no">Simulate Failure</button>
      </form>
      <div class="note">Simulated page — real ConnectIPS login appears when NPI_MODE=live</div>
    </div>
  </div>
</body></html>`);
});
/**
 * TEST ONLY — completes a simulated payment, advances Firestore exactly like
 * the live webhook would, then bounces the user back into the Flutter app via
 * the deep link.
 */
exports.testRouter.post('/complete/:paymentId', async (req, res) => {
    const config = (0, config_1.loadConfig)();
    if (config.mode !== 'test') {
        return res.status(404).json({ message: 'Test endpoints only available in test mode' });
    }
    const { paymentId } = req.params;
    const result = String(req.body?.result ?? 'success');
    const tx = await (0, firestore_1.getTransactionData)(paymentId);
    if (!tx || !tx.paymentStatus) {
        return res.status(404).json({ message: 'payment not found' });
    }
    if (result === 'success') {
        await (0, firestore_1.updatePaymentStatus)(paymentId, 'succeeded', {
            connectipsReferenceId: paymentId,
            creditStatus: '000',
            testMode: true,
        });
    }
    else {
        await (0, firestore_1.updatePaymentStatus)(paymentId, 'failed', {
            creditStatus: '999',
            testMode: true,
        });
    }
    res.redirect(302, deepLink(paymentId, result === 'success' ? 'success' : 'failure'));
});
//# sourceMappingURL=test.js.map