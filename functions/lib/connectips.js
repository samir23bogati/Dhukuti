"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConnectIPSTxnDetailsClient = void 0;
exports.buildInitiationToken = buildInitiationToken;
exports.buildInitiationFields = buildInitiationFields;
exports.buildValidationToken = buildValidationToken;
exports.isCreditSuccess = isCreditSuccess;
const signing_1 = require("./signing");
/**
 * Builds the token signing string for the merchant-interface form POST, exactly
 * per the ConnectIPS spec:
 *   MERCHANTID=..,APPID=..,APPNAME=..,TXNID=..,TXNDATE=..,TXNCRNCY=..,
 *   TXNAMT=..,REFERENCEID=..,REMARKS=..,PARTICULARS=..,TOKEN=TOKEN
 */
function buildInitiationToken(config, p) {
    return [
        `MERCHANTID=${config.merchantId}`,
        `APPID=${config.appId}`,
        `APPNAME=${config.appName}`,
        `TXNID=${p.txnId}`,
        `TXNDATE=${p.txnDate}`,
        `TXNCRNCY=${p.currency}`,
        `TXNAMT=${p.amountPaisa}`,
        `REFERENCEID=${p.referenceId}`,
        `REMARKS=${p.remarks}`,
        `PARTICULARS=${p.particulars}`,
        'TOKEN=TOKEN',
    ].join(',');
}
/** Hidden form fields to POST to ConnectIPS to open the payment page. */
function buildInitiationFields(config, p, privateKey) {
    const token = (0, signing_1.signSha256RsaBase64)(privateKey, buildInitiationToken(config, p));
    return {
        MERCHANTID: config.merchantId,
        APPID: config.appId,
        APPNAME: config.appName,
        TXNID: p.txnId,
        TXNDATE: p.txnDate,
        TXNCRNCY: p.currency,
        TXNAMT: p.amountPaisa,
        REFERENCEID: p.referenceId,
        REMARKS: p.remarks,
        PARTICULARS: p.particulars,
        TOKEN: token,
    };
}
/**
 * Token string for the REST status endpoints (validatetxn / gettxndetail):
 *   MERCHANTID=..,APPID=..,REFERENCEID=..,TXNAMT=..  (amount in paisa)
 */
function buildValidationToken(config, referenceId, amountPaisa) {
    return [
        `MERCHANTID=${config.merchantId}`,
        `APPID=${config.appId}`,
        `REFERENCEID=${referenceId}`,
        `TXNAMT=${amountPaisa}`,
    ].join(',');
}
class ConnectIPSTxnDetailsClient {
    config;
    privateKey;
    constructor(config, privateKey) {
        this.config = config;
        this.privateKey = privateKey;
    }
    get baseUrl() {
        return `${this.config.connectipsBaseUrl}/connectipswebws/api/creditor`;
    }
    authHeader() {
        const basic = Buffer.from(`${this.config.appId}:${this.config.appPassword}`).toString('base64');
        return { Authorization: `Basic ${basic}`, 'Content-Type': 'application/json' };
    }
    /**
     * Checks the current status of a payment. referenceId is the TXNID we sent
     * at initiation, amountPaisa the original amount so the token matches.
     */
    async validateTxn(referenceId, amountPaisa) {
        const token = (0, signing_1.signSha256RsaBase64)(this.privateKey, buildValidationToken(this.config, referenceId, amountPaisa));
        const body = {
            merchantId: this.config.merchantId,
            appId: this.config.appId,
            referenceId,
            txnAmt: amountPaisa,
            token,
        };
        const res = await fetch(`${this.baseUrl}/validatetxn`, {
            method: 'POST',
            headers: this.authHeader(),
            body: JSON.stringify(body),
        });
        if (!res.ok) {
            throw new Error(`validatetxn HTTP ${res.status}: ${await res.text()}`);
        }
        return (await res.json());
    }
    /** Full transaction details (debit bank, batch, charge, etc.). */
    async getTxnDetail(referenceId, amountPaisa) {
        const token = (0, signing_1.signSha256RsaBase64)(this.privateKey, buildValidationToken(this.config, referenceId, amountPaisa));
        const body = {
            merchantId: this.config.merchantId,
            appId: this.config.appId,
            referenceId,
            txnAmt: amountPaisa,
            token,
        };
        const res = await fetch(`${this.baseUrl}/gettxndetail`, {
            method: 'POST',
            headers: this.authHeader(),
            body: JSON.stringify(body),
        });
        if (!res.ok) {
            throw new Error(`gettxndetail HTTP ${res.status}: ${await res.text()}`);
        }
        return (await res.json());
    }
}
exports.ConnectIPSTxnDetailsClient = ConnectIPSTxnDetailsClient;
/** ConnectIPS creditStatus: 000 / 999 / DEFER all mean success. */
function isCreditSuccess(creditStatus) {
    return ['000', '999', 'DEFER'].includes(creditStatus ?? '');
}
//# sourceMappingURL=connectips.js.map