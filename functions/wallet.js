const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require('firebase-admin');

// IMPORTANT: In production, store FLW_SECRET_KEY and FLW_SECRET_HASH in Google Cloud Secret Manager
const FLW_SECRET_KEY = process.env.FLW_SECRET_KEY || "FLWSECK_TEST-sandbox-key";
const FLW_SECRET_HASH = process.env.FLW_SECRET_HASH || "hubble_secret_hash";

// Helper to interact with Flutterwave API
async function flwRequest(endpoint, method, payload) {
    const response = await fetch(`https://api.flutterwave.com/v3/${endpoint}`, {
        method: method,
        headers: {
            'Authorization': `Bearer ${FLW_SECRET_KEY}`,
            'Content-Type': 'application/json'
        },
        body: payload ? JSON.stringify(payload) : undefined
    });
    
    const data = await response.json();
    if (!response.ok) {
        throw new Error(data.message || 'Flutterwave API error');
    }
    return data;
}

/**
 * requestDeposit - Callable Function
 * Called by the app to initiate a Mobile Money STK Push.
 */
exports.requestDeposit = onCall(async (request) => {
    const { amount, phoneNumber, network } = request.data;
    const uid = request.auth?.uid;

    if (!uid) throw new HttpsError('unauthenticated', 'User must be logged in.');
    if (!amount || amount <= 0) throw new HttpsError('invalid-argument', 'Amount must be greater than 0.');
    if (!phoneNumber || !network) throw new HttpsError('invalid-argument', 'Phone number and network are required.');

    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    if (!userDoc.exists) throw new HttpsError('not-found', 'User not found.');
    const userData = userDoc.data();

    const txRef = `deposit-${uid}-${Date.now()}`;

    // Record the pending transaction in Firestore BEFORE hitting Flutterwave
    await admin.firestore().collection('users').doc(uid).collection('transactions').doc(txRef).set({
        txRef,
        type: 'DEPOSIT',
        amount: amount,
        currency: 'ZMW',
        status: 'PENDING',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        provider: 'FLUTTERWAVE',
        network: network,
        phoneNumber: phoneNumber
    });

    try {
        // Initiate the STK Push via Flutterwave API
        const payload = {
            tx_ref: txRef,
            amount: amount,
            currency: 'ZMW',
            network: network, // e.g., 'MTN', 'AIRTEL', 'ZAMTEL'
            email: userData.personalInfo?.email || 'user@hubble.com',
            phone_number: phoneNumber,
            meta: {
                userId: uid
            }
        };

        const response = await flwRequest('charges?type=mobile_money_zambia', 'POST', payload);
        
        return {
            status: 'success',
            message: 'Prompt sent to your phone. Please enter your PIN to authorize.',
            data: response.data
        };
    } catch (error) {
        // Update transaction to failed
        await admin.firestore().collection('users').doc(uid).collection('transactions').doc(txRef).update({
            status: 'FAILED',
            error: error.message
        });
        throw new HttpsError('internal', `Payment initiation failed: ${error.message}`);
    }
});

/**
 * flutterwaveWebhook - HTTP Function
 * Called by Flutterwave when a payment succeeds or fails.
 */
exports.flutterwaveWebhook = onRequest(async (req, res) => {
    // Verify Webhook Signature
    const signature = req.headers['verif-hash'];
    if (signature !== FLW_SECRET_HASH) {
        res.status(401).send('Unauthorized');
        return;
    }

    const payload = req.body;
    if (payload.event !== 'charge.completed') {
        res.status(200).send('Ignored');
        return;
    }

    const { tx_ref, amount, status, currency } = payload.data;
    
    // Extract UID from tx_ref (e.g., deposit-uid-timestamp)
    const txParts = tx_ref.split('-');
    if (txParts.length < 3 || txParts[0] !== 'deposit') {
        res.status(200).send('Ignored non-deposit transaction');
        return;
    }
    const uid = txParts[1];

    try {
        await admin.firestore().runTransaction(async (t) => {
            const userRef = admin.firestore().collection('users').doc(uid);
            const txRefDoc = userRef.collection('transactions').doc(tx_ref);

            const txSnap = await t.get(txRefDoc);
            if (!txSnap.exists) throw new Error('Transaction not found');
            
            const txData = txSnap.data();
            if (txData.status !== 'PENDING') {
                return; // Already processed
            }

            if (status === 'successful') {
                // Update Balance
                const userSnap = await t.get(userRef);
                const ledger = userSnap.data().financialLedger || {};
                const currentBalance = ledger.availableBalance || 0.0;

                t.update(userRef, {
                    'financialLedger.availableBalance': currentBalance + amount
                });

                // Update Transaction
                t.update(txRefDoc, {
                    status: 'SUCCESSFUL',
                    completedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                t.update(txRefDoc, {
                    status: 'FAILED',
                    completedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
        });

        res.status(200).send('Processed');
    } catch (error) {
        console.error('Webhook processing error:', error);
        res.status(500).send('Internal Server Error');
    }
});

/**
 * holdInEscrow - Callable Function
 */
exports.holdInEscrow = onCall(async (request) => {
    const { amount, bookingId } = request.data;
    const uid = request.auth?.uid;

    if (!uid) throw new HttpsError('unauthenticated', 'User must be logged in.');
    if (!amount || amount <= 0) throw new HttpsError('invalid-argument', 'Amount must be greater than 0.');
    if (!bookingId) throw new HttpsError('invalid-argument', 'Booking ID is required.');

    const userRef = admin.firestore().collection('users').doc(uid);

    try {
        await admin.firestore().runTransaction(async (t) => {
            const userSnap = await t.get(userRef);
            if (!userSnap.exists) throw new HttpsError('not-found', 'User not found.');
            
            const ledger = userSnap.data().financialLedger || {};
            const currentBalance = ledger.availableBalance || 0.0;
            const vaultBalance = ledger.vaultSettings?.vaultBalance || 0.0;

            if (currentBalance < amount) {
                throw new HttpsError('failed-precondition', 'Insufficient funds in wallet.');
            }

            // Deduct from available, add to vault
            t.update(userRef, {
                'financialLedger.availableBalance': currentBalance - amount,
                'financialLedger.vaultSettings.vaultBalance': vaultBalance + amount
            });

            const txRef = `escrow-hold-${bookingId}-${Date.now()}`;
            t.set(userRef.collection('transactions').doc(txRef), {
                txRef,
                type: 'ESCROW_HOLD',
                amount: amount,
                bookingId: bookingId,
                status: 'SUCCESSFUL',
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        return { success: true };
    } catch (error) {
        throw new HttpsError('internal', error.message);
    }
});

/**
 * releaseEscrow - Callable Function
 * Calculates 10% platform fee and credits 90% net payout to provider.
 */
exports.releaseEscrow = onCall(async (request) => {
    const { amount, bookingId, providerId, clientId } = request.data;
    const uid = request.auth?.uid;

    if (!uid) throw new HttpsError('unauthenticated', 'User must be logged in.');
    if (!bookingId || !providerId || !clientId) throw new HttpsError('invalid-argument', 'Missing booking identifiers.');

    const clientRef = admin.firestore().collection('users').doc(clientId);
    const providerRef = admin.firestore().collection('users').doc(providerId);
    const bookingRef = admin.firestore().collection('bookings').doc(bookingId);

    try {
        await admin.firestore().runTransaction(async (t) => {
            const bookingSnap = await t.get(bookingRef);
            if (!bookingSnap.exists) throw new HttpsError('not-found', 'Booking not found');
            if (bookingSnap.data().status === 'DISPUTED') {
                throw new HttpsError('failed-precondition', 'Funds are locked due to dispute.');
            }

            const clientSnap = await t.get(clientRef);
            const providerSnap = await t.get(providerRef);

            const clientLedger = clientSnap.data()?.financialLedger || {};
            const clientVault = clientLedger.vaultSettings?.vaultBalance || 0.0;
            
            const providerLedger = providerSnap.data()?.financialLedger || {};
            const providerAvailable = providerLedger.availableBalance || 0.0;

            // Financial split: 10% platform fee, 90% provider payout
            const platformFee = Math.round((amount * 0.10) * 100) / 100;
            const providerPayout = Math.round((amount - platformFee) * 100) / 100;

            // Remove from Client's Vault
            t.update(clientRef, {
                'financialLedger.vaultSettings.vaultBalance': Math.max(0, clientVault - amount)
            });

            // Add to Provider's Available Balance (net of platform fee)
            t.update(providerRef, {
                'financialLedger.availableBalance': providerAvailable + providerPayout
            });

            // Record Provider Payout Transaction
            const txRefRelease = `escrow-release-${bookingId}-${Date.now()}`;
            t.set(providerRef.collection('transactions').doc(txRefRelease), {
                txRef: txRefRelease,
                type: 'ESCROW_RELEASE',
                grossAmount: amount,
                platformFee: platformFee,
                amount: providerPayout,
                bookingId: bookingId,
                status: 'SUCCESSFUL',
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });

            // Record System Revenue Ledger
            const systemRevenueRef = admin.firestore().collection('metadata').doc('revenue_ledger');
            t.set(systemRevenueRef, {
                totalFeesCollected: admin.firestore.FieldValue.increment(platformFee),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            t.update(bookingRef, {
                status: 'COMPLETED',
                'financials.isEscrowPaidOut': true,
                'financials.platformFee': platformFee,
                'financials.providerPayout': providerPayout,
                completedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        return { success: true };
    } catch (error) {
        throw new HttpsError('internal', error.message);
    }
});

/**
 * refundEscrow - Callable Function
 * Refunds escrowed funds from client's vault back to client's available balance.
 */
exports.refundEscrow = onCall(async (request) => {
    const { amount, bookingId, clientId, disputeId, reason } = request.data;
    const uid = request.auth?.uid;

    if (!uid) throw new HttpsError('unauthenticated', 'User must be logged in.');
    if (!bookingId || !clientId) throw new HttpsError('invalid-argument', 'Missing booking identifiers.');

    const clientRef = admin.firestore().collection('users').doc(clientId);
    const bookingRef = admin.firestore().collection('bookings').doc(bookingId);

    try {
        await admin.firestore().runTransaction(async (t) => {
            const bookingSnap = await t.get(bookingRef);
            if (!bookingSnap.exists) throw new HttpsError('not-found', 'Booking not found');

            const clientSnap = await t.get(clientRef);
            if (!clientSnap.exists) throw new HttpsError('not-found', 'Client not found');

            const clientLedger = clientSnap.data()?.financialLedger || {};
            const clientAvailable = clientLedger.availableBalance || 0.0;
            const clientVault = clientLedger.vaultSettings?.vaultBalance || 0.0;

            const refundAmount = amount || bookingSnap.data().financials?.agreedPrice || 0;
            if (refundAmount <= 0) {
                throw new HttpsError('invalid-argument', 'Invalid refund amount.');
            }

            // Transfer from Vault back to Available Balance
            t.update(clientRef, {
                'financialLedger.vaultSettings.vaultBalance': Math.max(0, clientVault - refundAmount),
                'financialLedger.availableBalance': clientAvailable + refundAmount
            });

            // Log Refund Transaction
            const txRefRefund = `escrow-refund-${bookingId}-${Date.now()}`;
            t.set(clientRef.collection('transactions').doc(txRefRefund), {
                txRef: txRefRefund,
                type: 'ESCROW_REFUND',
                amount: refundAmount,
                bookingId: bookingId,
                reason: reason || 'Dispute resolution or cancellation',
                status: 'SUCCESSFUL',
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });

            // Update Booking Status
            t.update(bookingRef, {
                status: 'CANCELLED',
                'financials.isEscrowPaidOut': false,
                'financials.isRefunded': true,
                cancelledAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Resolve Dispute if disputeId provided
            if (disputeId) {
                const disputeRef = admin.firestore().collection('disputes').doc(disputeId);
                t.update(disputeRef, {
                    status: 'RESOLVED',
                    resolution: 'REFUNDED_TO_CLIENT',
                    resolvedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
        });

        return { success: true, message: 'Escrow refunded successfully to client wallet.' };
    } catch (error) {
        throw new HttpsError('internal', error.message);
    }
});

/**
 * requestWithdrawal - Callable Function
 */
exports.requestWithdrawal = onCall(async (request) => {
    const { amount, phoneNumber, network } = request.data;
    const uid = request.auth?.uid;

    if (!uid) throw new HttpsError('unauthenticated', 'User must be logged in.');
    if (!amount || amount <= 0) throw new HttpsError('invalid-argument', 'Amount must be greater than 0.');

    const userRef = admin.firestore().collection('users').doc(uid);

    try {
        await admin.firestore().runTransaction(async (t) => {
            const userSnap = await t.get(userRef);
            const ledger = userSnap.data()?.financialLedger || {};
            const currentBalance = ledger.availableBalance || 0.0;

            if (currentBalance < amount) {
                throw new HttpsError('failed-precondition', 'Insufficient funds.');
            }

            // Deduct from Available
            t.update(userRef, {
                'financialLedger.availableBalance': currentBalance - amount
            });

            const txRef = `withdrawal-${uid}-${Date.now()}`;
            t.set(userRef.collection('transactions').doc(txRef), {
                txRef,
                type: 'WITHDRAWAL',
                amount: amount,
                status: 'PENDING_TRANSFER', // Wait for async transfer
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                phoneNumber,
                network
            });
        });
        
        return { success: true, message: 'Withdrawal initiated successfully.' };
    } catch (error) {
        throw new HttpsError('internal', error.message);
    }
});
