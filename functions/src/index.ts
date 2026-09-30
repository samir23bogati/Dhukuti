import * as functions from 'firebase-functions';
import cors from 'cors';
import express from 'express';
import { paymentsRouter } from './routes/payments';
import { webhooksRouter } from './routes/webhooks';
import { testRouter } from './routes/test';

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Base paths the mobile app's NpiService calls (see lib/services/npi_service.dart).
app.use('/v1/payments', paymentsRouter);
// Callbacks from ConnectIPS / NPI / QR gateway (live mode).
app.use('/webhooks', webhooksRouter);
// Test-mode simulator (only active while NPI_MODE=test).
app.use('/v1/test', testRouter);

// Single HTTP endpoint hosting the whole API; region closest to Nepal users.
export const npi = functions.https.onRequest(
  { region: 'asia-south1', timeoutSeconds: 60 },
  app,
);