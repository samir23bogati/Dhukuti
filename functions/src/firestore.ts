import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

export const transactions = () => getFirestore().collection('transactions');

/** Prepares the default Firebase app once (idempotent across cold starts). */
export function ensureFirebase(): void {
  if (getApps().length === 0) {
    try {
      initializeApp();
    } catch {
      // USE_EMULATOR / missing service account etc. — let individual calls fail
      // with clear errors rather than crashing on init.
    }
  }
}

export function admin(): FirebaseFirestore.Firestore {
  ensureFirebase();
  return getFirestore();
}

export function firebaseAuth() {
  ensureFirebase();
  return getAuth();
}

export interface PaymentMeta {
  paymentStatus: string;
  connectipsReferenceId?: string;
  connectipsTxnId?: string;
  amountPaisa?: string;
  currency?: string;
  qrContent?: string;
  initiatedAt?: number;
  updatedAt: number;
}

/** Records that a payment was initiated against a trade transaction. */
export async function setPaymentPending(
  transactionId: string,
  meta: Omit<PaymentMeta, 'updatedAt'>,
): Promise<void> {
  await admin().collection('transactions').doc(transactionId).set(
    { ...meta, updatedAt: Date.now() },
    { merge: true },
  );
}

/** Advance the payment lifecycle (drives the app's status stream). */
export async function updatePaymentStatus(
  transactionId: string,
  paymentStatus: string,
  extra: Record<string, unknown> = {},
): Promise<void> {
  await admin().collection('transactions').doc(transactionId).update({
    paymentStatus,
    updatedAt: FieldValue.serverTimestamp(),
    ...extra,
  });
}

export async function getTransactionData(
  transactionId: string,
): Promise<FirebaseFirestore.DocumentData | undefined> {
  const doc = await admin().collection('transactions').doc(transactionId).get();
  return doc.exists ? doc.data() : undefined;
}

export async function markCancelled(transactionId: string): Promise<void> {
  await updatePaymentStatus(transactionId, 'cancelled');
}