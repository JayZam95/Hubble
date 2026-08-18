const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ region: "europe-west1" });

exports.onNewMessage = onDocumentCreated('conversations/{roomId}/messages/{messageId}', async (event) => {
  const messageData = event.data.data();
  const roomId = event.params.roomId;
  
  if (!messageData) return null;

  try {
    const roomRef = admin.firestore().collection('conversations').doc(roomId);
    const roomSnap = await roomRef.get();
    if (!roomSnap.exists) {
      console.log(`Room ${roomId} does not exist.`);
      return null;
    }
    
    const roomData = roomSnap.data();
    const participants = roomData.participants || [];
    const senderId = messageData.senderId;

    const recipientId = participants.find(uid => uid !== senderId);
    if (!recipientId) return null;

    const recipientRef = admin.firestore().collection('users').doc(recipientId);
    const recipientSnap = await recipientRef.get();
    if (!recipientSnap.exists) return null;

    const recipientData = recipientSnap.data();
    const fcmToken = recipientData.fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: messageData.senderName || 'New Message',
        body: messageData.type === 'IMAGE' ? '📷 Sent an image' : messageData.text || '',
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type: 'CHAT',
        roomId: roomId,
        senderId: senderId,
      },
      token: fcmToken
    };

    const response = await admin.messaging().send(payload);
    console.log('Successfully sent chat notification:', response);
    return response;

  } catch (error) {
    console.error('Error sending chat push notification:', error);
    return null;
  }
});

exports.onBookingChange = onDocumentWritten('bookings/{bookingId}', async (event) => {
  const bookingId = event.params.bookingId;
  const beforeData = event.data.before.exists ? event.data.before.data() : null;
  const afterData = event.data.after.exists ? event.data.after.data() : null;

  if (!afterData) return null;

  try {
    const oldStatus = beforeData ? beforeData.status : 'NONE';
    const newStatus = afterData.status;

    if (oldStatus === newStatus) return null;

    // Track trending categories based on requested (PENDING) and done (COMPLETED) jobs
    if (newStatus === 'PENDING' || newStatus === 'COMPLETED') {
      const category = afterData.serviceCategory || afterData.category;
      if (category) {
        try {
          const trendingRef = admin.firestore().collection('metadata').doc('trending_categories');
          await trendingRef.set({
            [category]: admin.firestore.FieldValue.increment(1)
          }, { merge: true });
        } catch (e) {
          console.error('Error updating trending categories:', e);
        }
      }
    }

    let recipientId;
    let notificationTitle = 'Booking Update';
    let notificationBody = `Your booking status has changed to ${newStatus.toLowerCase()}.`;

    if (newStatus === 'PENDING') {
      recipientId = afterData.providerId;
      notificationTitle = 'New Booking Request!';
      const price = afterData.financials ? afterData.financials.agreedPrice : 0;
      notificationBody = `You have a new booking request for ${price}.`;
    } else if (newStatus === 'ACCEPTED') {
      recipientId = afterData.clientId;
      notificationTitle = 'Booking Accepted!';
      notificationBody = 'Your booking request has been accepted by the provider.';
    } else if (newStatus === 'IN_PROGRESS') {
      recipientId = afterData.clientId;
      notificationTitle = 'Delivery/Job In Progress';
      notificationBody = 'The provider has started working on your job/delivery.';
    } else if (newStatus === 'COMPLETED') {
      recipientId = afterData.clientId;
      notificationTitle = 'Booking Completed!';
      notificationBody = 'The provider has marked your booking as completed.';
    } else if (newStatus === 'DISPUTED') {
      recipientId = afterData.providerId;
      notificationTitle = 'Booking Disputed';
      notificationBody = 'The client has disputed this booking. Escrow is paused.';
    } else if (newStatus === 'CANCELLED') {
      recipientId = (beforeData && beforeData.cancelledBy === afterData.clientId) 
        ? afterData.providerId 
        : afterData.clientId;
      notificationTitle = 'Booking Cancelled';
      notificationBody = 'The booking has been cancelled.';
    }

    if (!recipientId) return null;

    const recipientRef = admin.firestore().collection('users').doc(recipientId);
    const recipientSnap = await recipientRef.get();
    if (!recipientSnap.exists) return null;

    const recipientData = recipientSnap.data();
    const fcmToken = recipientData.fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type: 'BOOKING',
        bookingId: bookingId,
        status: newStatus,
      },
      token: fcmToken
    };

    const response = await admin.messaging().send(payload);
    console.log('Successfully sent booking notification:', response);
    return response;

  } catch (error) {
    console.error('Error sending booking push notification:', error);
    return null;
  }
});

exports.onNewReview = onDocumentCreated('reviews/{reviewId}', async (event) => {
  const reviewData = event.data ? event.data.data() : null;
  if (!reviewData) return null;

  try {
    const providerId = reviewData.providerId || reviewData.revieweeId;
    if (!providerId) return null;

    // Recalculate provider average rating and review count on users collection
    const reviewsSnap = await admin.firestore().collection('reviews')
      .where('revieweeId', '==', providerId)
      .get();
    
    let docs = reviewsSnap.docs;
    if (docs.length === 0) {
      const pSnap = await admin.firestore().collection('reviews')
        .where('providerId', '==', providerId)
        .get();
      docs = pSnap.docs;
    }

    if (docs.length > 0) {
      const totalRating = docs.reduce((sum, doc) => sum + (doc.data().rating || 0), 0);
      const reviewCount = docs.length;
      const averageRating = Math.round((totalRating / reviewCount) * 100) / 100;

      const providerRef = admin.firestore().collection('users').doc(providerId);
      await providerRef.update({
        'providerProfile.ratingAsProvider': averageRating,
        'providerProfile.reviewCount': reviewCount
      });
    }

    // Send FCM push notification to provider
    const providerRef = admin.firestore().collection('users').doc(providerId);
    const providerSnap = await providerRef.get();
    if (!providerSnap.exists) return null;

    const providerUser = providerSnap.data();
    const fcmToken = providerUser.fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: 'New Review Received!',
        body: `You received a new ${reviewData.rating}-star review.`,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type: 'REVIEW',
        reviewId: event.params.reviewId,
      },
      token: fcmToken
    };

    const response = await admin.messaging().send(payload);
    console.log('Successfully sent review notification:', response);
    return response;

  } catch (error) {
    console.error('Error in onReviewAdded:', error);
    return null;
  }
});

exports.onReviewAdded = exports.onNewReview;

exports.onDisputeCreated = onDocumentCreated('disputes/{disputeId}', async (event) => {
  const disputeData = event.data ? event.data.data() : null;
  if (!disputeData) return null;

  try {
    const { bookingId, clientId, providerId, reason, raisedBy } = disputeData;

    // 1. Notify admins via notifications collection
    const adminNotifRef = admin.firestore().collection('notifications').doc();
    await adminNotifRef.set({
      type: 'DISPUTE_RAISED',
      disputeId: event.params.disputeId,
      bookingId: bookingId || '',
      raisedBy: raisedBy || clientId || '',
      reason: reason || 'Dispute opened',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      target: 'ADMIN'
    });

    // 2. Send push notifications to provider and client
    const targetUids = [clientId, providerId].filter(Boolean);
    const notifications = targetUids.map(async (uid) => {
      const userSnap = await admin.firestore().collection('users').doc(uid).get();
      if (!userSnap.exists) return;
      const fcmToken = userSnap.data()?.fcmToken;
      if (!fcmToken) return;

      const isRaiser = uid === raisedBy;
      const title = isRaiser ? 'Dispute Submitted' : 'Dispute Opened on Booking';
      const body = isRaiser
        ? 'Your dispute has been logged and is under admin review.'
        : `A dispute was opened for booking #${bookingId ? bookingId.substring(0, 8) : ''}. Escrow is paused.`;

      const payload = {
        notification: { title, body },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          type: 'DISPUTE',
          disputeId: event.params.disputeId,
          bookingId: bookingId || '',
        },
        token: fcmToken
      };

      return admin.messaging().send(payload);
    });

    await Promise.all(notifications);
    console.log(`Successfully handled onDisputeCreated for ${event.params.disputeId}`);
    return true;
  } catch (error) {
    console.error('Error in onDisputeCreated:', error);
    return null;
  }
});

const { onRequest } = require('firebase-functions/v2/https');
exports.fixCors = onRequest(async (req, res) => { try { await admin.storage().bucket().setCorsConfiguration([{ origin: ['*'], method: ['GET'], maxAgeSeconds: 3600 }]); res.send('CORS set successfully!'); } catch (err) { res.status(500).send(err.message); } });

const wallet = require('./wallet');
exports.requestDeposit = wallet.requestDeposit;
exports.flutterwaveWebhook = wallet.flutterwaveWebhook;
exports.holdInEscrow = wallet.holdInEscrow;
exports.releaseEscrow = wallet.releaseEscrow;
exports.refundEscrow = wallet.refundEscrow;
exports.requestWithdrawal = wallet.requestWithdrawal;
