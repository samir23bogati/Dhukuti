"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.transactions = void 0;
exports.ensureFirebase = ensureFirebase;
exports.admin = admin;
exports.firebaseAuth = firebaseAuth;
exports.setPaymentPending = setPaymentPending;
exports.updatePaymentStatus = updatePaymentStatus;
exports.getTransactionData = getTransactionData;
exports.markCancelled = markCancelled;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const transactions = () => (0, firestore_1.getFirestore)().collection('transactions');
exports.transactions = transactions;
/** Prepares the default Firebase app once (idempotent across cold starts). */
function ensureFirebase() {
    if ((0, app_1.getApps)().length === 0) {
        try {
            (0, app_1.initializeApp)();
        }
        catch {
            // USE_EMULATOR / missing service account etc. — let individual calls fail
            // with clear errors rather than crashing on init.
        }
    }
}
function admin() {
    ensureFirebase();
    return (0, firestore_1.getFirestore)();
}
function firebaseAuth() {
    ensureFirebase();
    return (0, auth_1.getAuth)();
}
/** Records that a payment was initiated against a trade transaction. */
async function setPaymentPending(transactionId, meta) {
    await admin().collection('transactions').doc(transactionId).set({ ...meta, updatedAt: Date.now() }, { merge: true });
}
/** Advance the payment lifecycle (drives the app's status stream). */
async function updatePaymentStatus(transactionId, paymentStatus, extra = {}) {
    await admin().collection('transactions').doc(transactionId).update({
        paymentStatus,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        ...extra,
    });
}
async function getTransactionData(transactionId) {
    const doc = await admin().collection('transactions').doc(transactionId).get();
    return doc.exists ? doc.data() : undefined;
}
async function markCancelled(transactionId) {
    await updatePaymentStatus(transactionId, 'cancelled');
}
//# sourceMappingURL=firestore.js.map